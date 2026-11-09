import '../../keys/catalog_keys.dart';

/// What the catalog asks for one thing (an item, a pass, a bundle): its [price], and a [salePrice] from [saleFrom] (or
/// always) until [saleUntil], by the server's clock; read leniently.
class Offer {
  const Offer({required this.price, this.salePrice, this.saleFrom, this.saleUntil});

  /// [source]'s offer; null when it has no whole price.
  static Offer? from(Object? source) {
    if (source is! Map) return null;
    final price = source[CatalogKeys.price], sale = source[CatalogKeys.sale];
    if (price is! int) return null;
    if (sale is! Map || sale[CatalogKeys.price] is! int || sale[CatalogKeys.until] is! int) return Offer(price: price);
    final from = sale[CatalogKeys.from];
    return Offer(
      price: price,
      salePrice: sale[CatalogKeys.price] as int,
      saleFrom: from is int ? DateTime.fromMillisecondsSinceEpoch(from, isUtc: true) : null,
      saleUntil: DateTime.fromMillisecondsSinceEpoch(sale[CatalogKeys.until] as int, isUtc: true),
    );
  }

  /// The full price.
  final int price;
  final int? salePrice;
  final DateTime? saleFrom;
  final DateTime? saleUntil;

  /// The sale runs at [now] (the server's time).
  bool onSale(DateTime now) {
    final until = saleUntil;
    if (salePrice == null || until == null || !now.isBefore(until)) return false;
    final from = saleFrom;
    return from == null || !now.isBefore(from);
  }

  /// The price at [now]: the sale's while it runs, as the rules charge.
  int priceAt(DateTime now) => onSale(now) ? salePrice! : price;

  /// When the price next changes after [now] (the sale starting or ending); null when it won't.
  DateTime? nextChange(DateTime now) {
    final from = saleFrom, until = saleUntil;
    if (salePrice == null || until == null) return null;
    if (from != null && now.isBefore(from)) return from;
    return now.isBefore(until) ? until : null;
  }
}
