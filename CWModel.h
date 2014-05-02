//
//  CWModel.h
//
//  Created by Clément Wehrung on 01/05/2014.
//  Copyright (c) 2014 Clément Wehrung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CWCollection.h"

@interface CWModel : NSObject <CWCollectionModelProtocol>

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, assign) CWCollection *collection;

- (id)initWithIdentifier:(NSString *)identifier;
- (NSDictionary *)dictionary;
- (BOOL)updateWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)managedProperties;

@end
