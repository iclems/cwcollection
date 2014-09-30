//
//  CWCollection.h
//
//  Created by Clément Wehrung on 08/04/2014.
//  Copyright (c) 2014 Clément Wehrung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CWCollectionModelProtocol.h"

@class CWCollection;

/**
 * CWCollectionDataSource
 */

@protocol CWCollectionDataSource <NSObject>

typedef void (^CWCollectionPrepareResult)(id <CWCollectionModelProtocol> model, id data);

@required

- (void)collection:(CWCollection *)collection prepareModelWithData:(id)data completion:(CWCollectionPrepareResult)completionBlock;

@optional

- (NSComparisonResult)collection:(CWCollection *)collection sortCompareModel:(id <CWCollectionModelProtocol>)model1 withModel:(id <CWCollectionModelProtocol>)model2;

@end

/**
 * CWCollectionDelegate
 */

@protocol CWCollectionDelegate <NSObject>

@optional

- (void)collection:(CWCollection *)collection modelAdded:(id<CWCollectionModelProtocol>)model atIndex:(NSUInteger)index;
- (void)collection:(CWCollection *)collection modelRemoved:(id <CWCollectionModelProtocol>)model atIndex:(NSUInteger)index;
- (void)collection:(CWCollection *)collection modelUpdated:(id <CWCollectionModelProtocol>)model atIndex:(NSUInteger)index;
- (void)collection:(CWCollection *)collection modelMoved:(id <CWCollectionModelProtocol>)model fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

- (void)collectionDidStartLoad:(CWCollection *)collection;
- (void)collectionDidEndLoad:(CWCollection *)collection;

@end

/**
 * CWCollection
 */

@interface CWCollection : NSObject

@property (nonatomic, strong, readonly) NSMutableArray *models;
@property (nonatomic, strong, readonly) NSArray *filteredModels;

@property (nonatomic, assign) id <CWCollectionDelegate> delegate;
@property (nonatomic, assign) id <CWCollectionDataSource> dataSource;
@property (nonatomic, assign) Class modelClass;
@property (nonatomic, strong) NSPredicate *filter;

- (id <CWCollectionModelProtocol>)modelWithIdentifier:(NSString *)identifier;
- (id)modelAtIndex:(NSUInteger)index;
- (NSUInteger)indexForInsertingModel:(id <CWCollectionModelProtocol>)model;
- (void)sort;

- (void)addModel:(id <CWCollectionModelProtocol>)model;
- (void)addModel:(id <CWCollectionModelProtocol>)model silent:(BOOL)silent;
- (void)removeModel:(id <CWCollectionModelProtocol>)model;
- (void)removeModel:(id <CWCollectionModelProtocol>)model silent:(BOOL)silent;
- (void)updateModel:(id <CWCollectionModelProtocol>)model;
- (void)updateModel:(id <CWCollectionModelProtocol>)model silent:(BOOL)silent;

- (NSUInteger)count;
- (NSUInteger)indexOf:(id <CWCollectionModelProtocol>)model;
- (BOOL)hasModel:(id <CWCollectionModelProtocol>)model;

- (id)objectForKeyedSubscript:(id)key;
- (id)objectAtIndexedSubscript:(NSUInteger)index;
- (id)objectAtIndex:(NSUInteger)index;

// Internal methods

- (void)removeModelWithIdentifier:(NSString *)identifier;
- (void)removeModelWithIdentifier:(NSString *)identifier silent:(BOOL)silent;

- (void)modelAdded:(id <CWCollectionModelProtocol>)model atIndex:(NSUInteger)index;
- (void)modelRemoved:(id <CWCollectionModelProtocol>)model atIndex:(NSUInteger)index;
- (void)modelUpdated:(id <CWCollectionModelProtocol>)model atIndex:(NSUInteger)index;
- (void)modelMoved:(id <CWCollectionModelProtocol>)model fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

@end