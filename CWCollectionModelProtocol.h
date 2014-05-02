//
//  CWCollectionModelProtocol.h
//  Demo
//
//  Created by Clément Wehrung on 02/05/2014.
//  Copyright (c) 2014 Clement Wehrung. All rights reserved.
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
- (BOOL)updateWithDictionary:(NSDictionary *)dictionary;

@optional

@property (nonatomic, assign) CWCollection *collection;

@end
