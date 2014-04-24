//
//  CWViewController.m
//  Demo
//
//  Created by Clément Wehrung on 24/04/2014.
//  Copyright (c) 2014 Clement Wehrung. All rights reserved.
//

#import "CWViewController.h"
#import "CWDemoCollection.h"
#import "CWDemoModel.h"

@interface CWViewController ()

@property (nonatomic, strong) CWDemoCollection *collection;

@end

@implementation CWViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _collection = [[CWDemoCollection alloc] init];
    
    [self loadMore];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    [_loadingIndicator startAnimating];
}

// You can make the progressive scrolling smoother by moving all the following into scrollViewWillBeginDecelerating:
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [_loadingIndicator stopAnimating];

    NSIndexPath *indexPath = [self.tableView indexPathsForVisibleRows].lastObject;
    if (!self.collection.isLoading && indexPath.row > self.collection.count - 5)
    {
        [self loadMore];
    }
}

- (void)loadMore
{
    [_loadingIndicator startAnimating];
    
    __weak CWViewController *this = self;
    
    [self.collection loadMoreWithCompletion:^(CWCollection *collection, NSArray *models) {
        [_loadingIndicator stopAnimating];
        [_tableView insertRowsAtIndexPaths:[this indexPathsWithModels:models] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

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

#pragma mark - Table View Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.collection.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    CWDemoModel *model = [_collection.models objectAtIndex:indexPath.row];

    cell.textLabel.attributedText = [self attributedStringFromHTMLString:model.title];
    cell.detailTextLabel.attributedText = [self attributedStringFromHTMLString:model.contentSnippet];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

- (NSAttributedString *)attributedStringFromHTMLString:(NSString *)html
{
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithData:[html dataUsingEncoding:NSUTF8StringEncoding] options:@{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType} documentAttributes:nil error:nil];
    
    return attributedString;
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
