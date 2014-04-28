//
//  CWDemoModel.h
//  Demo
//
//  Created by Clément Wehrung on 24/04/2014.
//  Copyright (c) 2014 Clement Wehrung. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CWFirebaseCollection.h"

@interface CWDemoModel : NSObject <CWCollectionModelProtocol>

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *contentSnippet;
@property (nonatomic, strong) NSString *link;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *url;

- (id)initWithIdentifier:(NSString *)identifier andDictionary:(NSDictionary *)dictionary;

- (void)updateWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionary;

@end
