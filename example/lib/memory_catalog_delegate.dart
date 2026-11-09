import 'package:flutter/foundation.dart';
import 'package:flutter_shop_kit/flutter_shop_kit.dart';

/// The admin's catalog, kept in the app for the example: two items (one on sale for a day), four passes and a bundle.
class MemoryCatalogDelegate implements CatalogDelegate {
  @override
  Map<String, Object?>? cached() => {
    CatalogKeys.items: {
      'hat': {CatalogKeys.price: 100},
      'cape': {
        CatalogKeys.price: 300,
        CatalogKeys.sale: {CatalogKeys.price: 200, CatalogKeys.until: DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch},
      },
    },
    CatalogKeys.passes: {
      'boost': {CatalogKeys.type: 'duration', CatalogKeys.minutes: 30, CatalogKeys.stack: true, CatalogKeys.price: 50},
      'hints': {CatalogKeys.type: 'counter', CatalogKeys.count: 5, CatalogKeys.max: 20, CatalogKeys.price: 40},
      'gift': {CatalogKeys.type: 'daily', CatalogKeys.days: 7, CatalogKeys.count: 1, CatalogKeys.price: 120},
      'vip': {CatalogKeys.type: 'lifetime', CatalogKeys.price: 500},
    },
    CatalogKeys.bundles: {
      'starter': {
        CatalogKeys.price: 250,
        CatalogKeys.items: ['hat'],
        CatalogKeys.passes: ['boost', 'hints'],
        CatalogKeys.limit: {CatalogKeys.count: 1},
      },
    },
  };

  @override
  Future<Map<String, Object?>?> fetch(int version) async => cached();

  @override
  int? get version => null;

  @override
  final Listenable versionChanges = ChangeNotifier();
}
