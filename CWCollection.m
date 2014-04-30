//
//  CWCollection.m
//
//  Created by Clément Wehrung on 08/04/2014.
//  Copyright (c) 2014 Clément Wehrung. All rights reserved.
//

#import "CWCollection.h"

@interface CWCollection()

@property (nonatomic, strong, readwrite) NSMutableArray *models;

@property (nonatomic, strong) NSMutableDictionary *dictionary;
@property (nonatomic, strong) NSComparator comparator;

@end

@implementation CWCollection

- (id)init
{
    if (self = [super init]) {
        _dictionary = [NSMutableDictionary dictionary];
        _models = [NSMutableArray array];
        _sortUpdate = YES;
    }
	return self;
}

#pragma mark - Models Management

- (void)sort
{
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(collection:sortCompareModel:withModel:)])
    {
        __weak CWCollection *this = self;
        
        [_models sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [this.dataSource collection:this sortCompareModel:obj1 withModel:obj2];
        }];
    }
}

- (void)addModel:(id <CWCollectionModelProtocol>)model
{
    return [self addModel:model silent:NO];
}

- (void)addModel:(id <CWCollectionModelProtocol>)model silent:(BOOL)silent
{
    id localModel = [self objectForKey:model.identifier];
    if (!localModel)
    {
        if ([model respondsToSelector:@selector(setCollection:)]) {
            model.collection = self;
        }
        
        [self setObject:model forKey:model.identifier];
        [self sort];
        
        if (!silent) {
            [self modelAdded:model atIndex:[self indexOf:model]];
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
    id <CWCollectionModelProtocol> localModel = [self objectForKey:identifier];
    if (localModel)
    {
        NSUInteger index = [self indexOf:localModel];
        
        [self removeObjectForKey:identifier];
        
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
    id localModel = [self objectForKey:model.identifier];
    if (localModel)
    {
        NSUInteger indexBeforeUpdate = [self indexOf:localModel];
        
        BOOL didChange = [localModel updateWithDictionary:model.dictionary];
        
        if (!silent && didChange)
        {
            [self modelUpdated:localModel atIndex:indexBeforeUpdate];
            
            if (self.sortUpdate) {
                
                [self sort];
                
                NSUInteger indexAfterUpdate = [self indexOf:localModel];
                BOOL modelDidMove = indexBeforeUpdate != indexAfterUpdate;
                
                if (modelDidMove)
                {
                    [self modelMoved:localModel fromIndex:indexBeforeUpdate toIndex:indexAfterUpdate];
                }
                
            }
        }
    }
}

#pragma mark - Delegate Notifiers

- (void)modelAdded:(id <CWCollectionModelProtocol>)model atIndex:(NSUInteger)index
{
    if ([_delegate respondsToSelector:@selector(collection:modelAdded:atIndex:)]) {
        [_delegate collection:self modelAdded:model atIndex:index];
    }
}

- (void)modelRemoved:(id <CWCollectionModelProtocol>)model atIndex:(NSUInteger)index
{
    if ([_delegate respondsToSelector:@selector(collection:modelRemoved:atIndex:)]) {
        [_delegate collection:self modelRemoved:model atIndex:index];
    }
}

- (void)modelUpdated:(id <CWCollectionModelProtocol>)model atIndex:(NSUInteger)index
{
    if ([_delegate respondsToSelector:@selector(collection:modelUpdated:atIndex:)]) {
        [_delegate collection:self modelUpdated:model atIndex:index];
    }
}

- (void)modelMoved:(id <CWCollectionModelProtocol>)model fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    if ([_delegate respondsToSelector:@selector(collection:modelMoved:fromIndex:toIndex:)]) {
        [_delegate collection:self modelMoved:model fromIndex:fromIndex toIndex:toIndex];
    }
}

#pragma mark - NSMutableDictionary

- (void)setObject:(id)anObject forKey:(id)aKey
{
    if (![_dictionary objectForKey:aKey])
    {
        [_models addObject:anObject];
        [_dictionary setObject:anObject forKey:aKey];
    }
}

- (void)removeObjectForKey:(id)aKey
{
    [_models removeObject:[_dictionary objectForKey:aKey]];
    [_dictionary removeObjectForKey:aKey];
}

- (NSUInteger)count
{
    return [_models count];
}

- (id)objectForKey:(id)aKey
{
    return [_dictionary objectForKey:aKey];
}

- (NSEnumerator *)keyEnumerator
{
    return [_models objectEnumerator];
}

#pragma mark - Helpers

- (NSUInteger)indexOf:(id <CWCollectionModelProtocol>)model
{
    return [_models indexOfObject:model];
}

- (BOOL)hasModel:(id <CWCollectionModelProtocol>)model
{
    // hasObject is not used as it may lead to duplicates
    return [self objectForKey:model.identifier] ? YES : NO;
}

@end
