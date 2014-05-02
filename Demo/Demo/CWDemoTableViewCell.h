//
//  CWDemoTableViewCell.h
//  Demo
//
//  Created by Clément Wehrung on 02/05/2014.
//  Copyright (c) 2014 Clement Wehrung. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CWDemoModel;

@interface CWDemoTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *snippetLabel;
@property (nonatomic, strong) IBOutlet UITextView *linkTextView;

@property (nonatomic, assign) CWDemoModel *model;

@end
