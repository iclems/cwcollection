//
//  CWViewController.m
//  Demo
//
//  Created by Clément Wehrung on 24/04/2014.
//  Copyright (c) 2014 Clement Wehrung. All rights reserved.
//

#import "CWViewController.h"
#import "CWDemoModel.h"
#import "CWDemoTableViewCell.h"

@interface CWViewController ()

@property (nonatomic, strong) CWDemoCollection *collection;

@end

@implementation CWViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _collection = [[CWDemoCollection alloc] init];
    _collection.delegate = self;
    
    [self loadMore:YES];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSIndexPath *indexPath = [self.tableView indexPathsForVisibleRows].lastObject;
    
    if (!self.collection.isLoading && indexPath.row > self.collection.count - 5)
    {
        [self loadMore:NO];
    }
}

- (void)loadMore:(BOOL)animated
{
    __weak CWViewController *this = self;
    
    [self.collection loadMoreWithCompletion:^(CWCollection *collection, NSArray *models) {
        if (!models.count) { return; }
        [UIView setAnimationsEnabled:animated];
        [this.tableView insertRowsAtIndexPaths:[this indexPathsWithModels:models] withRowAnimation:UITableViewRowAnimationAutomatic];
        [UIView setAnimationsEnabled:YES];
    }];
}

#pragma mark - CWCollection Delegate

- (void)collection:(CWCollection *)collection modelAdded:(id<CWCollectionModelProtocol>)model atIndex:(NSUInteger)index inBatch:(BOOL)inBatch
{
    // Batch inserts are performed separately within the batch completion block
    // as it wouldn't be efficient for the UI / main thread to receive
    // numerous consecutive calls to insertSections (especially with iOS 7 bugged UITableViewRowAnimationNone)
    if (!inBatch) {
        [self.tableView insertRowsAtIndexPaths:[self indexPathsFromIndex:index] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)collection:(CWCollection *)collection modelRemoved:(id<CWCollectionModelProtocol>)model atIndex:(NSUInteger)index
{
    [self.tableView deleteRowsAtIndexPaths:[self indexPathsFromIndex:index] withRowAnimation:UITableViewRowAnimationRight];
}

- (void)collection:(CWCollection *)collection modelUpdated:(id<CWCollectionModelProtocol>)model atIndex:(NSUInteger)index
{
    [self.tableView reloadRowsAtIndexPaths:[self indexPathsFromIndex:index] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)collection:(CWCollection *)collection modelMoved:(id<CWCollectionModelProtocol>)model fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    [self.tableView moveRowAtIndexPath:[self indexPathFromIndex:fromIndex] toIndexPath:[self indexPathFromIndex:toIndex]];
}

- (void)collectionDidStartLoad:(CWCollection *)collection
{
    [_loadingIndicator startAnimating];
}

- (void)collectionDidEndLoad:(CWCollection *)collection
{
    [_loadingIndicator stopAnimating];
    // e.g. check if empty, show placeholder
}

#pragma mark - Table View Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.collection.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    CWDemoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    cell.model = [_collection.models objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell prepareForReuse];
}

#pragma mark - Index Helpers

- (NSArray *)indexPathsWithModels:(NSArray *)models
{
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    
    for (id model in models) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:[self.collection indexOf:model] inSection:0]];
    }
    
    return indexPaths;
}

- (NSIndexPath *)indexPathFromIndex:(NSUInteger)index
{
    return [NSIndexPath indexPathForRow:index inSection:0];
}

- (NSArray *)indexPathsFromIndex:(NSUInteger)index
{
    return @[[self indexPathFromIndex:index]];
}

@end
