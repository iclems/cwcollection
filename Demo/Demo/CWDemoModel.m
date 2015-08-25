//
//  CWDemoModel.m
//  Demo
//
//  Created by Clément Wehrung on 24/04/2014.
//  Copyright (c) 2014 Clement Wehrung. All rights reserved.
//

#import "CWDemoModel.h"

@implementation CWDemoModel

/**
 * managedProperties declares the properties which should be automatically synced: @{ localPropertyName: remotePropertyName }
 * @discussion: CWModel does not automatically convert a property to its local equivalent if not specified.
 * Otherwise, security and unstability issues may arise when the data evolves.
 */

- (NSDictionary *)managedProperties
{
    return @{ @"score": @"score",
              @"by": @"by",
              @"title": @"title",
              @"text": @"text",
              @"url": @"url"
            };
}

@end
