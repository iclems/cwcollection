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
    Firebase *reference = [[Firebase alloc] initWithUrl:@"https://cwcollection-demo.firebaseio.com/model"];
    
    if (self = [super initWithReference:reference dataSource:self])
    {
        self.batchSize = 17;
        self.modelClass = CWDemoModel.class;
    }
    
    return self;
}

@end
