import '../../keys/catalog_keys.dart';
import '../models/buy_limit.dart';

/// [source] (a pass's or bundle's `limit` in the catalog) as a buying limit: whole `count` buys in each whole
/// `minutes`, or for good; null when it is none.
BuyLimit? catalogBuyLimit(Object? source) {
  if (source is! Map || source[CatalogKeys.count] is! int) return null;
  final minutes = source[CatalogKeys.minutes];
  return (count: source[CatalogKeys.count] as int, minutes: minutes is int ? minutes : 0);
}
