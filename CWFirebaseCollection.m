//
//  CWFirebaseCollection.m
//
//  Created by Clément Wehrung on 08/04/2014.
//  Copyright (c) 2014 Clément Wehrung. All rights reserved.
//

#import <objc/runtime.h>

#import "CWFirebaseCollection.h"
#import "CWModel.h"

@interface CWFirebaseCollection()

@property (nonatomic, strong, readwrite) Firebase* reference;
@property (nonatomic, assign, readwrite) BOOL isLoading;
@property (nonatomic, assign, readwrite) BOOL hasMore;

@property (nonatomic, strong) NSMutableDictionary *eventHandles;
@property (nonatomic, strong) NSMutableDictionary *currentBatchModels;
@property (nonatomic, strong, readwrite) FDataSnapshot *lastDataSnapshot;

@end

@implementation CWFirebaseCollection

- (id)initWithReference:(Firebase *)reference dataSource:(id <CWCollectionDataSource>)dataSource
{
    if (self = [super init])
    {
        _reference = reference;
        _currentBatchModels = [NSMutableDictionary dictionary];
        _isLoading = NO;
        _batchSize = 0;
        _autoStartListeners = YES;
        _hasMore = YES;
        
        self.dataSource = dataSource;
    }
    return self;
}

- (id)init
{
    if (self.reference && self.modelClass) {
        self = [self initWithReference:self.reference dataSource:self];
    } else {
        self = [super init];
    }
    return self;
}

- (NSString *)description
{
    return _reference.description;
}

- (void)startListeners
{
    [self startListeningForNew];
    [self setupListenerForEventType:FEventTypeChildChanged withSelector:@selector(remoteModelDidChangeWithSnapshot:)];
    [self setupListenerForEventType:FEventTypeChildMoved withSelector:@selector(remoteModelDidChangeWithSnapshot:)];
    [self setupListenerForEventType:FEventTypeChildRemoved withSelector:@selector(removeModelWithSnapshot:)];
}

- (void)startListeningForNew
{
    if (_eventHandles[@(FEventTypeChildAdded)]) return;
    
    FQuery *query = nil;
    
    if (!self.lastDataSnapshot) {
        query = self.reference;
    }
    else if (self.isAscending) {
        query = [self.reference queryEndingAtPriority:self.lastDataSnapshot.priority andChildName:self.lastDataSnapshot.name];
    }
    else {
        query = [self.reference queryStartingAtPriority:self.lastDataSnapshot.priority andChildName:self.lastDataSnapshot.name];
    }
    
    __weak CWFirebaseCollection *weakSelf = self;
    FirebaseHandle handle;
    
    handle = [query observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {

        __block BOOL processed = NO;

        [weakSelf.dataSource collection:weakSelf prepareModelWithData:snapshot completion:^(id <CWCollectionModelProtocol> model, FDataSnapshot *snapshot) {
            
            if (!model) { return; }
            
            assert([model conformsToProtocol:@protocol(CWCollectionModelProtocol)]);
            
            if ([weakSelf hasModel:model])
            {
                [weakSelf updateModel:model silent:NO];
            }
            else if (!processed)
            {
                // If a model has already been processed, it should never be added again
                // Otherwise, a model could have been removed in the meantime, but receive
                // echo from prepareModelWithData:completion: as it may be still listening to somethig else
                // TODO: it would be nice to receive a cancellable FOperation: we could cancel it from here
                [weakSelf addModel:model];
            }
            processed = YES;
        }];
    }];
    
    _eventHandles[@(FEventTypeChildAdded)] = @(handle);
}

- (void)setupListenerForEventType:(FEventType)eventType withSelector:(SEL)selector
{
    if (_eventHandles[@(eventType)]) return;

    __weak CWFirebaseCollection *weakSelf = self;
    FirebaseHandle handle;
    
    handle = [self.reference observeEventType:eventType withBlock:^(FDataSnapshot *snapshot) {
        if ([weakSelf respondsToSelector:selector]) {
            IMP imp = class_getMethodImplementation(weakSelf.class, selector);
            void (*func)(id, SEL, FDataSnapshot *) = (void *)imp;
            func(weakSelf, selector, snapshot);
        }
    }];
    
    _eventHandles[@(eventType)] = @(handle);
}

- (void)removeModelWithSnapshot:(FDataSnapshot *)snapshot
{
    [self removeModelWithIdentifier:snapshot.name];
}

- (void)remoteModelDidChangeWithSnapshot:(FDataSnapshot *)snapshot
{
    __weak CWFirebaseCollection *weakSelf = self;
    
    [self.dataSource collection:self prepareModelWithData:snapshot completion:^(id <CWCollectionModelProtocol> model, FDataSnapshot *snapshot) {
        if (model) {
            [weakSelf updateModel:model];
        }
    }];

}

- (void)loadAllWithCompletion:(void (^)(CWCollection *collection, NSArray *models))completion
{
    [self runQueryWithLimit:0 completion:completion];
}

- (void)loadMoreWithCompletion:(void (^)(CWCollection *collection, NSArray *models))completion
{
    [self runQueryWithLimit:self.batchSize completion:completion];
}

- (void)runQueryWithLimit:(NSUInteger)limit completion:(void (^)(CWCollection *collection, NSArray *models))completion
{
    NSAssert(completion, @"A completion block is required.");
    
    void(^errorBlock)() = ^() {
        completion(self, @[]);
    };
    
    if (self.isLoading || !self.hasMore) return errorBlock();
    else self.isLoading = YES;
    
    [self.currentBatchModels  removeAllObjects];
    
    FQuery *query = limit ? [self.reference queryLimitedToNumberOfChildren:limit] : self.reference;
    
    NSString *startDataSnapshotName = nil;
    
    if (self.lastDataSnapshot)
    {
        query = [query queryEndingAtPriority:self.lastDataSnapshot.priority
                                andChildName:self.lastDataSnapshot.name];
        
        startDataSnapshotName = self.lastDataSnapshot.name;
    }
    
    __weak CWFirebaseCollection *weakSelf = self;
    __block BOOL batchLoading = YES;
    
    [query observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        __block NSUInteger totalCount = snapshot.childrenCount - (weakSelf.lastDataSnapshot ? 1 : 0);
        __block NSMutableDictionary *preparedSnapshots = [NSMutableDictionary dictionary];
        
        void (^readyBlock)() = ^() {
            
            weakSelf.isLoading = batchLoading = NO;
            
            if (!limit || totalCount < limit - 1) {
                weakSelf.hasMore = NO;
            }
            
            for (id <CWCollectionModelProtocol> model in weakSelf.currentBatchModels.allValues)
            {
                if (![weakSelf hasModel:model]) {
                    [weakSelf addModel:model];
                } else {
                    [weakSelf updateModel:model silent:YES];
                }
            }
            
            if (completion) {
                completion(weakSelf, weakSelf.currentBatchModels.allValues);
            }
            
            [weakSelf startListeners];
            
            [weakSelf.currentBatchModels removeAllObjects];
            preparedSnapshots = nil;
        };
        
        if (!totalCount) {
            return readyBlock();
        }
        
        /**
         * completionBlock takes care of complex situations linked with offline cache, 
         * where the completionBlock may be called several times for the same snapshot.
         * If the model has already been created, it will update it silently.
         */
        
        void (^completionBlock)(id <CWCollectionModelProtocol>, FDataSnapshot *snapshot) = ^(id <CWCollectionModelProtocol> model, FDataSnapshot *snapshot)
        {
            if (!batchLoading) {
                
                // Query already completed, but receives new data updates.
                // weakSelf is due to Firebase Offline cache which forces us to accept
                // multiple completion callbacks per location (1. cache, 2. remote value).
                // Yet, once we have received 1 callback per location, the query is
                // considered completed (otherwise, it may never complete: e.g. if one child
                // was indeed removed, it won't be called twice with NSNull)
                
                return model ? [weakSelf updateModel:model silent:NO] : nil;
            }
            
            if (snapshot) {
                if (preparedSnapshots[snapshot.name]) return;
                else [preparedSnapshots setObject:@(YES) forKey:snapshot.name];
            }
            
            if (model) {
                [weakSelf.currentBatchModels setObject:model forKey:model.identifier];
            }
            
            if (preparedSnapshots.count == totalCount)
            {
                readyBlock();
            }
        };
        
        if (!snapshot.childrenCount) {
            return completionBlock(nil, nil);
        }

        NSUInteger enumIndex = 0;
        NSUInteger lastDataIndex = weakSelf.isAscending ? (snapshot.childrenCount - 1) : 0;
        
        // TODO: snapshot.children should be reversed if not ascending
        // But snapshot.children.allObjects.reverseEnumerator does not seem to work for now
        // Maybe Firebase SDK could offer snapshot.reverseChildren?
        
        for (FDataSnapshot *childSnapshot in snapshot.children) {
            
            if (startDataSnapshotName != childSnapshot.name)
            {
                if (enumIndex == lastDataIndex) {
                    weakSelf.lastDataSnapshot = childSnapshot;
                }
                
                if ([childSnapshot.value isKindOfClass:NSNull.class]) {
                    completionBlock(nil, snapshot);
                } else {
                    [weakSelf.dataSource collection:weakSelf prepareModelWithData:childSnapshot completion:completionBlock];
                }
            }
            
            enumIndex++;
        }        
    } withCancelBlock:^(NSError *error) {
        errorBlock();
    }];
}

- (void)modelAdded:(id <CWCollectionModelProtocol>)model atIndex:(NSUInteger)index
{
    [super modelAdded:model atIndex:index];
    
    BOOL inBatch = [self.currentBatchModels objectForKey:model.identifier] != nil;
    
    if ([self.delegate respondsToSelector:@selector(collection:modelAdded:atIndex:inBatch:)]) {
        [self.delegate collection:self modelAdded:model atIndex:index inBatch:inBatch];
    }
}

- (void)setIsLoading:(BOOL)isLoading
{
    _isLoading = isLoading;
    
	SEL selector = isLoading ? @selector(collectionDidStartLoad:) : @selector(collectionDidEndLoad:);

    if ([self.delegate respondsToSelector:selector]) {
        IMP imp = class_getMethodImplementation(self.delegate.class, selector);
        void (*func)(id, SEL, CWCollection *) = (void *)imp;
        func(self.delegate, selector, self);
    }
}

#pragma mark - Default Model Implementation

- (void)collection:(CWCollection *)collection prepareModelWithData:(FDataSnapshot *)snapshot completion:(CWCollectionPrepareResult)completionBlock
{
    assert(self.modelClass);
    
    id model = nil;
    
    if (snapshot && ![snapshot isKindOfClass:NSNull.class]) {

        Class class = self.modelClass;
        
        model = [[class alloc] initWithIdentifier:snapshot.name];
        [model updateWithDictionary:snapshot.valueInExportFormat];
        
    }

    completionBlock(model, snapshot);
}

#pragma mark - Model

- (void)addModel:(id <CWCollectionModelProtocol>)model
{
    if (!model.identifier) {
        Firebase *modelRef = [self.reference childByAutoId];
        model.identifier = modelRef.name;
        [modelRef setValue:model.dictionary];
    }
    
    return [super addModel:model silent:NO];
}

@end
