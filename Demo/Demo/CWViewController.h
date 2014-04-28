//
//  CWViewController.h
//  Demo
//
//  Created by Clément Wehrung on 24/04/2014.
//  Copyright (c) 2014 Clement Wehrung. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CWDemoCollection.h"

@interface CWViewController : UIViewController <CWFirebaseCollectionDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *loadingIndicator;

@end
