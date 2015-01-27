//
//  CWDemoTableViewCell.m
//  Demo
//
//  Created by Clément Wehrung on 02/05/2014.
//  Copyright (c) 2014 Clement Wehrung. All rights reserved.
//

#import <Block-KVO/MTKObserving.h>
#import <DTCoreText/DTCoreText.h>

#import "CWDemoTableViewCell.h"
#import "CWDemoModel.h"

@implementation CWDemoTableViewCell

// TODO: Change for FBKVOController

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self removeAllObservations];
}

- (void)setModel:(CWDemoModel *)model
{
    assert(model);

    [self removeAllObservations];

    _model = model;
    
    __weak CWDemoTableViewCell *weakSelf = self;
    
    [self map:@keypath(self.model.title) to:@keypath(self.titleLabel.attributedText) transform:^id(NSString *value) {
        return [weakSelf attributedStringFromHTMLString:value];
    }];
    
    [self map:@keypath(self.model.contentSnippet) to:@keypath(self.snippetLabel.attributedText) transform:^id(NSString *value) {
        return [weakSelf attributedStringFromHTMLString:value];
    }];

    [self map:@keypath(self.model.url) to:@keypath(self.linkTextView.text) null:@"No Link"];
}

- (NSAttributedString *)attributedStringFromHTMLString:(NSString *)html
{
    NSDictionary *options = @{ DTUseiOS6Attributes: @YES, DTAttachmentParagraphSpacingAttribute: @(0) };
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
    NSAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithHTMLData:data
                                                                                       options:options
                                                                            documentAttributes:nil];
    
    return attributedString;
}

@end
