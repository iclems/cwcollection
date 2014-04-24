//
//  CWFirebaseCollection.h
//
//  Created by Clément Wehrung on 08/04/2014.
//  Copyright (c) 2014 Clément Wehrung. All rights reserved.
//

#import <Firebase/Firebase.h>

#import "CWCollection.h"

@protocol CWFirebaseCollectionDelegate <CWCollectionDelegate>

@optional

- (void)collection:(CWCollection *)collection modelAdded:(id<CWCollectionModelProtocol>)model atIndex:(NSUInteger)index inBatch:(BOOL)inBatch;

@end


@protocol CWFirebaseCollectionDataSource <NSObject>

@required

- (void)collection:(CWCollection *)collection prepareModelWithData:(FDataSnapshot *)dataSnapshot completion:(CWCollectionPrepareResult)completionBlock;

@end

@interface CWFirebaseCollection : CWCollection

@property (nonatomic, strong, readonly) Firebase* reference;
@property (nonatomic, assign) NSUInteger batchSize;
@property (nonatomic, assign) BOOL isAscending;
@property (nonatomic, assign, readonly) BOOL isLoading;
@property (nonatomic, assign) BOOL autoStartListeners;

- (id)initWithReference:(Firebase *)reference dataSource:(id <CWFirebaseCollectionDataSource>)dataSource;
- (void)loadAllWithCompletion:(void (^)(CWCollection *collection, NSArray *models))completion;
- (void)loadMoreWithCompletion:(void (^)(CWCollection *collection, NSArray *models))completion;

- (void)startListeners;
- (void)startListeningForNew;
- (void)startListeningForChange;
- (void)startListeningForMove;

@end
