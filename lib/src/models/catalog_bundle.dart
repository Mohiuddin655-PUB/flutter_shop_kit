import '../../keys/catalog_keys.dart';
import '../utils/catalog_buy_limit.dart';
import 'bundle_terms.dart';
import 'buy_limit.dart';
import 'offer.dart';

/// One bundle the catalog sells (`bundles`): its [items] and its [passes] (by id, up to [bundleMaxPasses]) at
/// once, at its [offer]'s price (and sale), within its [limit]; read leniently.
class CatalogBundle {
  const CatalogBundle({required this.offer, this.items = const [], this.passes = const [], this.limit});

  /// [source]'s bundle; null without a whole price, with nothing in it, or with more passes than the rules check.
  static CatalogBundle? from(Object? source) {
    if (source is! Map) return null;
    final offer = Offer.from(source);
    final items = _ids(source[CatalogKeys.items]), passes = _ids(source[CatalogKeys.passes]);
    if (offer == null || (items.isEmpty && passes.isEmpty) || passes.length > bundleMaxPasses) return null;
    return CatalogBundle(offer: offer, items: items, passes: passes, limit: catalogBuyLimit(source[CatalogKeys.limit]));
  }

  static List<String> _ids(Object? list) => list is List ? list.whereType<String>().toSet().toList() : const [];

  final Offer offer;
  final List<String> items, passes;
  final BuyLimit? limit;

  /// Its terms at [now]: its sale's price while the sale runs.
  BundleTerms termsAt(DateTime now) => (price: offer.priceAt(now), items: items, passes: passes, limit: limit);
}
