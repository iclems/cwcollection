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
 * managedProperties declares the properties which should be automatically synced:
 * @{ localPropertyName: remotePropertyName }
 */

- (NSDictionary *)managedProperties
{
    return @{ @"contentSnippet": @"contentSnippet",
              @"link": @"link",
              @"title": @"title",
              @"url": @"url"
            };
}

@end
