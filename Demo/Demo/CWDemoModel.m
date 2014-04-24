//
//  CWDemoModel.m
//  Demo
//
//  Created by Clément Wehrung on 24/04/2014.
//  Copyright (c) 2014 Clement Wehrung. All rights reserved.
//

#import "CWDemoModel.h"

@implementation CWDemoModel

- (id)initWithIdentifier:(NSString *)identifier andDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        _identifier = identifier;
        [self updateWithDictionary:dictionary];
    }
    return self;
}

- (void)updateWithDictionary:(NSDictionary *)dictionary
{
    _contentSnippet = dictionary[@"contentSnippet"];
    _link = dictionary[@"link"];
    _title = dictionary[@"title"];
    _url = dictionary[@"url"];
}

- (NSDictionary *)dictionary
{
    return @{ @"contentSnippet": _contentSnippet,
              @"link": _link,
              @"title": _title,
              @"url": _url
            };
}

@end
