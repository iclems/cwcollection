//
//  CWDemoCollection.m
//  Demo
//
//  Created by Clément Wehrung on 24/04/2014.
//  Copyright (c) 2014 Clement Wehrung. All rights reserved.
//

#import "CWDemoCollection.h"
#import "CWDemoModel.h"

@implementation CWDemoCollection

- (id)init
{
    Firebase *reference = [[Firebase alloc] initWithUrl:@"https://hacker-news.firebaseio.com/v0/topstories"];
    
    if (self = [super initWithReference:reference dataSource:self])
    {
        self.batchSize = 17;
        self.modelClass = [CWDemoModel class];
    }
    
    return self;
}

// This example shows how to load async data where the collection onlys contains a list of IDs.
// If the ref directly contains the actual data, the following method isn't necessary.
- (void)collection:(CWCollection *)collection prepareModelWithData:(FDataSnapshot *)snapshot
        completion:(CWCollectionPrepareResult)completionBlock
{
    Firebase *itemRef = [[[self.reference parent] childByAppendingPath:@"item"] childByAppendingPath:snapshot.key];
    
    [itemRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        CWDemoModel *model = [[CWDemoModel alloc] initWithIdentifier:snapshot.key];
        [model updateWithDictionary:snapshot.value];
        completionBlock(model, snapshot);
    }];
}

@end
