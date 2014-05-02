//
//  CWDemoModel.h
//  Demo
//
//  Created by Clément Wehrung on 24/04/2014.
//  Copyright (c) 2014 Clement Wehrung. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CWFirebaseCollection.h"
#import "CWModel.h"

@interface CWDemoModel : CWModel

@property (nonatomic, strong) NSString *contentSnippet;
@property (nonatomic, strong) NSString *link;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *url;

@end
