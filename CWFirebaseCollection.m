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

@property (nonatomic, assign) BOOL isListeningForNew;
@property (nonatomic, assign) BOOL isListeningForChange;
@property (nonatomic, assign) BOOL isListeningForMove;

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

- (void)startListeners
{
    [self startListeningForNew];
    [self startListeningForChange];
    [self startListeningForMove];
}

- (void)startListeningForNew
{
    if (self.isListeningForNew) return;
    else self.isListeningForNew = YES;
    
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
    
    __block CWFirebaseCollection *this = self;
   
    [query observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        [this.dataSource collection:this prepareModelWithData:snapshot completion:^(id <CWCollectionModelProtocol> model, FDataSnapshot *snapshot) {
            if (model) {
                [this addModel:model];
            }
        }];
    }];
}

- (void)startListeningForMove
{
    if (self.isListeningForMove) return;
    else self.isListeningForMove = YES;
    
    __block CWFirebaseCollection *this = self;
    
    [self.reference observeEventType:FEventTypeChildMoved withBlock:^(FDataSnapshot *snapshot) {
        [this remoteModelDidChangeWithSnapshot:snapshot];
    }];
}

- (void)startListeningForChange
{
    if (self.isListeningForChange) return;
    else self.isListeningForChange = YES;
    
    __block CWFirebaseCollection *this = self;
    
    [self.reference observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        [this remoteModelDidChangeWithSnapshot:snapshot];
    }];
}

- (void)remoteModelDidChangeWithSnapshot:(FDataSnapshot *)snapshot
{
    __block CWFirebaseCollection *this = self;
    
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
    if (self.isLoading) return;
    else self.isLoading = YES;
    
    [self.currentBatchModels  removeAllObjects];
    
    FQuery *query = limit ? [self.reference queryLimitedToNumberOfChildren:limit] : self.reference;
    
    if (self.lastDataSnapshot) {
        query = [query queryEndingAtPriority:self.lastDataSnapshot.priority
                                andChildName:self.lastDataSnapshot.name];
    }
    
    __block CWFirebaseCollection *this = self;
    
    [query observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        __block NSUInteger preparedCount = 0;
        __block NSUInteger totalCount = snapshot.childrenCount;
        
        void (^completionBlock)(id <CWCollectionModelProtocol>, FDataSnapshot *snapshot) = ^(id <CWCollectionModelProtocol> model, FDataSnapshot *snapshot)
        {
            if (model && ![self hasModel:model])
            {
                [this.currentBatchModels addObject:model];
                [this addModel:model];
            }
            
            preparedCount++;
            
            if (preparedCount >= totalCount)
            {
                this.isLoading = NO;
                
                if (completion) {
                    completion(this, this.currentBatchModels);
                }

                [this startListeners];
            }
        };
        
        NSUInteger enumIndex = 0;
        NSUInteger lastDataIndex = this.isAscending ? (snapshot.childrenCount - 1) : 0;
        
        // TODO: snapshot.children should be reversed if not ascending
        // But snapshot.children.allObjects.reverseEnumerator does not seem to work for now
        // Maybe Firebase SDK could offer snapshot.reverseChildren?
        
        for (FDataSnapshot *childSnapshot in snapshot.children) {
            
            if (enumIndex == lastDataIndex) {
                this.lastDataSnapshot = childSnapshot;
            }
            
            if ([childSnapshot.value isKindOfClass:NSNull.class]) {
                completionBlock(nil, snapshot);
            } else {
                [this.dataSource collection:this prepareModelWithData:childSnapshot completion:completionBlock];
            }
            
            enumIndex++;
        }
        
        if (!snapshot.childrenCount) {
            completionBlock(nil, snapshot);
        }
    }];
}

- (void)modelAdded:(id <CWCollectionModelProtocol>)model atIndex:(NSUInteger)index
{
    [super modelAdded:model atIndex:index];
    
    BOOL inBatch = [self.currentBatchModels indexOfObject:model] != NSNotFound;
    
    for (id <CWFirebaseCollectionDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(collection:modelAdded:atIndex:inBatch:)]) {
            [delegate collection:self modelAdded:model atIndex:index inBatch:inBatch];
        }
    }
}

- (void)setIsLoading:(BOOL)isLoading
{
    _isLoading = isLoading;
    
	SEL selector = isLoading ? @selector(collectionDidStartLoad:) : @selector(collectionDidEndLoad:);

    for (id <CWFirebaseCollectionDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:selector]) {
            IMP imp = class_getMethodImplementation(delegate.class, selector);
            void (*func)(id, SEL, CWCollection *) = (void *)imp;
            func(delegate, selector, self);
        }
    }
}

@end
