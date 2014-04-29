//
//  CWFirebaseCollection.m
//
//  Created by Clément Wehrung on 08/04/2014.
//  Copyright (c) 2014 Clément Wehrung. All rights reserved.
//

#import <objc/runtime.h>

#import "CWFirebaseCollection.h"

@interface CWFirebaseCollection()

@property (nonatomic, strong, readwrite) Firebase* reference;
@property (nonatomic, assign, readwrite) BOOL isLoading;

@property (nonatomic, strong) NSMutableDictionary *eventHandles;
@property (nonatomic, strong) NSMutableArray *currentBatchModels;
@property (nonatomic, strong) FDataSnapshot *lastDataSnapshot;

@end

@implementation CWFirebaseCollection

- (id)initWithReference:(Firebase *)reference dataSource:(id <CWCollectionDataSource>)dataSource
{
    if (self = [super init])
    {
        _reference = reference;
        _currentBatchModels = [NSMutableArray array];
        _isLoading = NO;
        _batchSize = 0;
        _autoStartListeners = YES;
        
        self.dataSource = dataSource;
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
    
    __weak CWFirebaseCollection *this = self;
    FirebaseHandle handle;
    handle = [query observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        [this.dataSource collection:this prepareModelWithData:snapshot completion:^(id <CWCollectionModelProtocol> model, FDataSnapshot *snapshot) {
            if (model) {
                [this addModel:model];
            }
        }];
    }];
    
    _eventHandles[@(FEventTypeChildAdded)] = @(handle);
}

- (void)setupListenerForEventType:(FEventType)eventType withSelector:(SEL)selector
{
    if (_eventHandles[@(eventType)]) return;

    __weak CWFirebaseCollection *this = self;
    FirebaseHandle handle;
    
    handle = [self.reference observeEventType:eventType withBlock:^(FDataSnapshot *snapshot) {
        if ([this respondsToSelector:selector]) {
            IMP imp = class_getMethodImplementation(this.class, selector);
            void (*func)(id, SEL, FDataSnapshot *) = (void *)imp;
            func(this, selector, snapshot);
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
    __weak CWFirebaseCollection *this = self;
    
    [self.dataSource collection:self prepareModelWithData:snapshot completion:^(id <CWCollectionModelProtocol> model, FDataSnapshot *snapshot) {
        if (model) {
            [this updateModel:model];
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
    if (self.isLoading) return completion(self, @[]);
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
    
    __weak CWFirebaseCollection *this = self;
    __block BOOL batchLoading = YES;
    
    [query observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        __block NSUInteger totalCount = snapshot.childrenCount - (this.lastDataSnapshot ? 1 : 0);
        __block NSMutableDictionary *preparedSnapshots = [NSMutableDictionary dictionary];
        
        void (^readyBlock)() = ^() {
            
            this.isLoading = batchLoading = NO;
            
            if (completion) {
                completion(this, this.currentBatchModels);
            }
            
            [this startListeners];
            
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
                // This is due to Firebase Offline cache which forces us to accept
                // multiple completion callbacks per location (1. cache, 2. remote value).
                // Yet, once we have received 1 callback per location, the query is
                // considered completed (otherwise, it may never complete: e.g. if one child
                // was indeed removed, it won't be called twice with NSNull)
                
                if (model && [this hasModel:model]) {
                    return [this updateModel:model silent:NO];
                }
            }
            
            if (model && ![this hasModel:model])
            {
                [this.currentBatchModels addObject:model];
                [this addModel:model];
            }
            else if (model) {
                [this updateModel:model silent:YES];
            }
            
            // If collection is empty, no snapshot
            if (snapshot) {
                if (preparedSnapshots[snapshot.name]) return;
                else [preparedSnapshots setObject:@(YES) forKey:snapshot.name];
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
        NSUInteger lastDataIndex = this.isAscending ? (snapshot.childrenCount - 1) : 0;
        
        // TODO: snapshot.children should be reversed if not ascending
        // But snapshot.children.allObjects.reverseEnumerator does not seem to work for now
        // Maybe Firebase SDK could offer snapshot.reverseChildren?
        
        for (FDataSnapshot *childSnapshot in snapshot.children) {
            
            if (startDataSnapshotName != childSnapshot.name)
            {
                if (enumIndex == lastDataIndex) {
                    this.lastDataSnapshot = childSnapshot;
                }
                
                if ([childSnapshot.value isKindOfClass:NSNull.class]) {
                    completionBlock(nil, snapshot);
                } else {
                    [this.dataSource collection:this prepareModelWithData:childSnapshot completion:completionBlock];
                }
            }
            
            enumIndex++;
        }        
    }];
}

- (void)modelAdded:(id <CWCollectionModelProtocol>)model atIndex:(NSUInteger)index
{
    [super modelAdded:model atIndex:index];
    
    BOOL inBatch = [self.currentBatchModels indexOfObject:model] != NSNotFound;
    
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

@end
