//
//  CWDemoTableViewCell.m
//  Demo
//
//  Created by Clément Wehrung on 02/05/2014.
//  Copyright (c) 2014 Clement Wehrung. All rights reserved.
//

#import <KVOController/FBKVOController.h>

#import "CWDemoTableViewCell.h"
#import "CWDemoModel.h"

@implementation CWDemoTableViewCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.KVOController unobserveAll];
}

- (void)setModel:(CWDemoModel *)model
{
    assert(model);

    [self.KVOController unobserveAll];

    _model = model;
    
    [self.KVOController observe:self.model
                        keyPaths:@[@"title", @"text"]
                        options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                          block:^(typeof(self) weakSelf, CWDemoModel *item, NSDictionary *change) {
                              weakSelf.titleLabel.text = item.title ?: item.text;
                          }];

    [self.KVOController observe:self.model
                        keyPath:@"score"
                        options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                          block:^(typeof(self) weakSelf, CWDemoModel *item, NSDictionary *change) {
                              weakSelf.snippetLabel.text = [NSString stringWithFormat:@"%i - %@", item.score ?: 0, item.by];
                          }];

    [self.KVOController observe:self.model
                        keyPath:@"url"
                        options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                          block:^(typeof(self) weakSelf, id object, NSDictionary *change) {
                              NSString *url = change[NSKeyValueChangeNewKey];
                              weakSelf.linkTextView.text = [url isKindOfClass:[NSNull class]] ? @"No Link" : url;
                          }];
}

@end
