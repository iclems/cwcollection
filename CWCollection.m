//
//  CWCollection.m
//
//  Created by Clément Wehrung on 08/04/2014.
//  Copyright (c) 2014 Clément Wehrung. All rights reserved.
//

#import "CWCollection.h"
#import "CWModel.h"

#define IS_OBJECT(T) _Generic( (T), id: YES, default: NO)

@interface CWCollection()

@property (nonatomic, strong, readwrite) NSMutableArray *models;
@property (nonatomic, strong, readwrite) NSArray *filteredModels;

@property (nonatomic, strong) NSMutableDictionary *dictionary;
@property (nonatomic, strong) NSComparator comparator;

@end

@implementation CWCollection

- (id)init
{
    if (self = [super init]) {
        _dictionary = [NSMutableDictionary dictionary];
        _models = [NSMutableArray array];
        _filteredModels = [NSArray array];
    }
	return self;
}

- (void)dealloc
{
    for (id <CWCollectionModelProtocol> model in self.models) {
        if (model.collection == self) {
            model.collection = nil;
        }
    }
    
    _delegate = nil;
    _dataSource = nil;
}

#pragma mark - Sort

/** 
 * Sort
 * Performs a full resort of the collection. Never called internally. Beware, the delegate won't be called with model 
 **/

- (void)sort
{
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(collection:sortCompareModel:withModel:)])
    {
        __weak CWCollection *weakSelf = self;
        
        [self.models sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [weakSelf.dataSource collection:weakSelf sortCompareModel:obj1 withModel:obj2];
        }];
    }
}

/**
 * @return Provides the insert index of the model in the array. If no sort comparator is found, returns NSNotFound.
 **/

- (NSUInteger)indexForInsertingModel:(id <CWCollectionModelProtocol>)model
{
    NSUInteger topIndex = self.models.count;

    if (self.dataSource && [self.dataSource respondsToSelector:@selector(collection:sortCompareModel:withModel:)])
    {
        // Inspired from: http://www.jayway.com/2009/03/28/adding-sorted-inserts-to-uimutablearray/
        
        NSUInteger index = 0;
        
        while (index < topIndex) {
            NSUInteger midIndex = (index + topIndex) / 2;
            id <CWCollectionModelProtocol> testModel = [self.models objectAtIndex:midIndex];
            if ([self.dataSource collection:self sortCompareModel:model withModel:testModel] > 0) {
                index = midIndex + 1;
            } else {
                topIndex = midIndex;
            }
        }
        
        return index;
    }
    
    return topIndex;
}

#pragma mark - Accessors

- (id <CWCollectionModelProtocol>)modelWithIdentifier:(NSString *)identifier
{
    return [self.dictionary objectForKey:identifier];
}


- (id)modelAtIndex:(NSUInteger)index
{
    return [self.models objectAtIndex:index];
}

- (NSUInteger)indexOf:(id <CWCollectionModelProtocol>)model
{
    return [self.models indexOfObject:model];
}

- (BOOL)hasModel:(id <CWCollectionModelProtocol>)model
{
    return [self modelWithIdentifier:model.identifier] ? YES : NO;
}

#pragma mark - Add / Change / Move / Remove

- (void)addModel:(id <CWCollectionModelProtocol>)model
{
    return [self addModel:model silent:NO];
}

- (void)addModel:(id <CWCollectionModelProtocol>)model silent:(BOOL)silent
{
    id localModel = [self modelWithIdentifier:model.identifier];
    if (!localModel)
    {
        if ([model respondsToSelector:@selector(setCollection:)]) {
            model.collection = self;
        }
        
        if (![self.dictionary objectForKey:model.identifier])
        {
            NSUInteger insertIndex = [self indexForInsertingModel:model];
            [self.models insertObject:model atIndex:insertIndex];
            [self.dictionary setObject:model forKey:model.identifier];
            [self refilter];
        
            if (!silent) {
                [self modelAdded:model atIndex:insertIndex];
            }
        }
    }
}

- (void)removeModel:(id <CWCollectionModelProtocol>)model
{
    [self removeModel:model silent:NO];
}

- (void)removeModel:(id <CWCollectionModelProtocol>)model silent:(BOOL)silent
{
    return [self removeModelWithIdentifier:model.identifier silent:silent];
}

- (void)removeModelWithIdentifier:(NSString *)identifier
{
    return [self removeModelWithIdentifier:identifier silent:NO];
}

- (void)removeModelWithIdentifier:(NSString *)identifier silent:(BOOL)silent
{
    id <CWCollectionModelProtocol> localModel = [self modelWithIdentifier:identifier];
    if (localModel)
    {
        NSUInteger index = [self indexOf:localModel];
        
        [self.models removeObject:[_dictionary objectForKey:identifier]];
        [self.dictionary removeObjectForKey:identifier];
        [self refilter];
        
        if (!silent) {
            [self modelRemoved:localModel atIndex:index];
        }
    }
}

- (void)updateModel:(id <CWCollectionModelProtocol>)model
{
    return [self updateModel:model silent:NO];
}

- (void)updateModel:(id <CWCollectionModelProtocol>)model silent:(BOOL)silent
{
    id localModel = [self modelWithIdentifier:model.identifier];
    if (localModel)
    {
        NSUInteger indexBeforeUpdate = [self indexOf:localModel];
        
        BOOL didChange = [localModel updateWithDictionary:model.dictionary];
        
        if (!silent && didChange)
        {
            [self modelUpdated:localModel atIndex:indexBeforeUpdate];
            [self sort];
            [self refilter];
            
            NSUInteger indexAfterUpdate = [self indexOf:localModel];
            BOOL modelDidMove = indexBeforeUpdate != indexAfterUpdate;
            
            if (modelDidMove)
            {
                [self.models removeObject:localModel];
                [self.models insertObject:localModel atIndex:indexAfterUpdate];
                
                [self modelMoved:localModel fromIndex:indexBeforeUpdate toIndex:indexAfterUpdate];
            }
        }
    }
}

#pragma mark - Delegate Notifiers

- (void)modelAdded:(id <CWCollectionModelProtocol>)model atIndex:(NSUInteger)index
{
    if ([self.delegate respondsToSelector:@selector(collection:modelAdded:atIndex:)]) {
        [self.delegate collection:self modelAdded:model atIndex:index];
    }
}

- (void)modelRemoved:(id <CWCollectionModelProtocol>)model atIndex:(NSUInteger)index
{
    if ([self.delegate respondsToSelector:@selector(collection:modelRemoved:atIndex:)]) {
        [self.delegate collection:self modelRemoved:model atIndex:index];
    }
}

- (void)modelUpdated:(id <CWCollectionModelProtocol>)model atIndex:(NSUInteger)index
{
    if ([self.delegate respondsToSelector:@selector(collection:modelUpdated:atIndex:)]) {
        [self.delegate collection:self modelUpdated:model atIndex:index];
    }
}

- (void)modelMoved:(id <CWCollectionModelProtocol>)model fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    if ([self.delegate respondsToSelector:@selector(collection:modelMoved:fromIndex:toIndex:)]) {
        [self.delegate collection:self modelMoved:model fromIndex:fromIndex toIndex:toIndex];
    }
}

#pragma mark - Filter

- (void)setFilter:(NSPredicate *)filter
{
    _filter = filter;
    
    [self refilter];
}

- (void)refilter
{
    self.filteredModels = self.filter ? [self.models filteredArrayUsingPredicate:self.filter] : nil;
}

- (NSArray *)filteredModels
{
    return _filteredModels ?: self.models;
}

#pragma mark - Compliance

- (id)objectForKeyedSubscript:(id)key
{
    return [self.dictionary objectForKey:key];
}

- (id)objectAtIndexedSubscript:(NSUInteger)index
{
    return [self modelAtIndex:index];
}

- (id)objectAtIndex:(NSUInteger)index
{
    return [self modelAtIndex:index];
}

- (NSEnumerator *)keyEnumerator
{
    return [self.models objectEnumerator];
}

- (NSUInteger)count
{
    return [self.models count];
}

@end
