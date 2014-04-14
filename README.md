CWCollection
============

CWCollection provides:
- a basic Collection (somehow similar in the approach to Backbone Collection)
- a Firebase adapter to this collection, to make it easy to represent a Firebase Collection using UITableView, UICollectionView, etc. The Firebase adapter also provides support for progressive loading (by batch of size N), completion blocks, etc.

A Firebase collection can either be represented:
- live with full display of all its elements with support for child added, changed, moved, removed
- progressive loading by batch, with parallel new child support

CWCollectionModelProtocol
--

The main requirement is that the model needs to correspond to `CWCollectionModelProtocol`:
```
  - (NSString *)identifier;
  - (NSDictionary *)dictionary;
  - (void)updateWithDictionary:(NSDictionary *)dictionary;
```
CWCollectionDataSource
--

Any CWCollection must have a dataSource which transforms a received data object into a model instance. The dataSource can also optionally provide a sort comparator (the collection will automatically be kept sorted):
```
  - (void)collection:(CWCollection *)collection prepareModelWithData:(id)data completion:(LMCollectionPrepareResult)completionBlock;
  - (NSComparisonResult)collection:(CWCollection *)collection sortCompareModel:(id <CWCollectionModelProtocol>)model1 withModel:(id <CWCollectionModelProtocol>)model2;
```

The `collection:prepareModelWithData:completion:` async enables to load "references" collection, and automatically retrieving the referenced object. 

Basic example (without reference): 
```
- (void)collection:(CWCollection *)collection prepareModelWithData:(FDataSnapshot*)snapshot completion:(LMCollectionPrepareResult)completionBlock;
{
    LMPanel *panel = [LMPanel panelWithDictionary:snapshot.valueInExportFormat projectReference:_reference];
    completionBlock(panel, snapshot);
}
```

CWCollectionDelegate
--

The CWCollection delegate(s) provides method meant to be close to UITableView, UICollectionView, etc. and status update regarding the loading state:
```
  - (void)collection:(CWCollection *)collection modelAdded:(id<CWCollectionModelProtocol>)model atIndex:(NSUInteger)index;
  - (void)collection:(CWCollection *)collection modelRemoved:(id <CWCollectionModelProtocol>)model atIndex:(NSUInteger)index;
  - (void)collection:(CWCollection *)collection modelUpdated:(id <CWCollectionModelProtocol>)model atIndex:(NSUInteger)index;
  - (void)collection:(CWCollection *)collection modelMoved:(id <CWCollectionModelProtocol>)model fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;
  
  - (void)collectionDidStartLoad:(CWCollection *)collection;
  - (void)collectionDidEndLoad:(CWCollection *)collection;
```
Firebase: CWFirebaseCollection
--

CWFirebaseCollection offers three main ways to load data:
  - child by child, full realtime, full collection through "startListeners"
  - all at once, and then child by child for new children (e.g. useful to batch insert/reload for the view, as UITableView does not like getting multiple consecutive calls to insertSection/Row)
  - paginated, with a batchSize (as soon as the first batch is retrieved, by default, listeners are started automatically, and new children, moves, changes will automatically be reflected)
