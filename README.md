CWCollection
============

CWCollection provides:
- a basic Collection (somehow similar in the approach to Backbone Collection)
- a Firebase adapter to this collection, to make it easy to represent a Firebase Collection using UITableView, UICollectionView, etc. The Firebase adapter also provides support for progressive loading (by batch of size N), completion blocks, etc.

A Firebase collection can either be represented:
- live with full display of all its elements with support for child added, changed, moved, removed
- progressive loading by batch, with parallel new child support

The main requirement is that the model needs to correspond to CWCollectionModelProtocol: it must have an `identifier`, and provide NSDictionary binding:
`
- (NSString *)identifier;
- (NSDictionary *)dictionary;
- (void)updateWithDictionary:(NSDictionary *)dictionary;
`
