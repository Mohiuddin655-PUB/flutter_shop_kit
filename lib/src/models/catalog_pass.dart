import '../../keys/catalog_keys.dart';
import '../enums/pass_type.dart';
import '../utils/catalog_buy_limit.dart';
import 'buy_limit.dart';
import 'offer.dart';
import 'pass_terms.dart';

/// One pass the catalog sells (`passes`), read leniently: its [type], what that type needs ([minutes], [count],
/// [days], [until], whether it [stack]s), its [offer] (price and sale), its counter's [max] and its buying [limit].
class CatalogPass {
  const CatalogPass({
    required this.type,
    required this.offer,
    this.minutes = 0,
    this.count = 0,
    this.days = 0,
    this.stack = false,
    this.until,
    this.max = 0,
    this.limit,
  });

  /// [source]'s pass; null when its type is unknown, it lacks what its type needs, or it has no whole price.
  static CatalogPass? from(Object? source) {
    if (source is! Map) return null;
    final type = PassType.values.where((t) => t.name == source[CatalogKeys.type]).firstOrNull;
    final offer = Offer.from(source);
    if (type == null || offer == null) return null;
    int some(String key) => source[key] is int && (source[key] as int) > 0 ? source[key] as int : 0;
    final until = source[CatalogKeys.until];
    final pass = CatalogPass(
      type: type,
      offer: offer,
      minutes: some(CatalogKeys.minutes),
      count: some(CatalogKeys.count),
      days: some(CatalogKeys.days),
      stack: source[CatalogKeys.stack] == true,
      until: until is int ? DateTime.fromMillisecondsSinceEpoch(until, isUtc: true) : null,
      max: some(CatalogKeys.max),
      limit: catalogBuyLimit(source[CatalogKeys.limit]),
    );
    return pass.complete ? pass : null;
  }

  final PassType type;
  final Offer offer;
  final int minutes, count, days, max;
  final bool stack;
  final DateTime? until;
  final BuyLimit? limit;

  /// It has what its type needs.
  bool get complete => switch (type) {
    PassType.duration => minutes > 0,
    PassType.counter => count > 0,
    PassType.lifetime => true,
    PassType.daily => count > 0 && days > 0,
    PassType.limited => count > 0 && minutes > 0,
    PassType.until => until != null,
  };

  /// Its terms at [now]: its sale's price while the sale runs.
  PassTerms termsAt(DateTime now) =>
      (type: type, price: offer.priceAt(now), minutes: minutes, count: count, days: days, stack: stack, until: until, max: max, limit: limit);
}
