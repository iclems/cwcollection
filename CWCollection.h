//
//  CWCollection.h
//
//  Created by Clément Wehrung on 08/04/2014.
//  Copyright (c) 2014 Clément Wehrung. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CWCollection;

/**
 * CWCollectionModelProtocol
 */

@protocol CWCollectionModelProtocol <NSObject>

@required

- (NSString *)identifier;
- (NSDictionary *)dictionary;
- (void)updateWithDictionary:(NSDictionary *)dictionary;

@optional

@property (nonatomic, weak) CWCollection *collection;

@end

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

@interface CWCollection : NSMutableDictionary

@property (nonatomic, strong, readonly) NSMutableArray *models;
@property (nonatomic, strong, readonly) NSMutableArray *delegates;
@property (nonatomic, weak) id <CWCollectionDataSource> dataSource;

- (void)addModel:(id <CWCollectionModelProtocol>)model;
- (void)removeModel:(id <CWCollectionModelProtocol>)model;
- (void)removeModelWithIdentifier:(NSString *)identifier;
- (void)updateModel:(id <CWCollectionModelProtocol>)model;
- (void)updateModel:(id <CWCollectionModelProtocol>)model silent:(BOOL)silent;

- (void)sort;

- (NSUInteger)indexOf:(id <CWCollectionModelProtocol>)model;
- (BOOL)hasModel:(id <CWCollectionModelProtocol>)model;

- (void)setDelegate:(id <CWCollectionDelegate>)delegate; // performs addDelegate
- (void)addDelegate:(id <CWCollectionDelegate>)delegate;
- (void)removeDelegate:(id <CWCollectionDelegate>)delegate;

// Internal methods

- (void)modelAdded:(id <CWCollectionModelProtocol>)model atIndex:(NSUInteger)index;
- (void)modelRemoved:(id <CWCollectionModelProtocol>)model atIndex:(NSUInteger)index;
- (void)modelUpdated:(id <CWCollectionModelProtocol>)model atIndex:(NSUInteger)index;
- (void)modelMoved:(id <CWCollectionModelProtocol>)model fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

@end