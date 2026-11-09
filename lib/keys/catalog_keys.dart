/// The admin's catalog (as the security rules read it), with times as milliseconds since the epoch, UTC.
abstract final class CatalogKeys {
  /// The items sold, by id: `{price, sale}` (and whatever else the app keeps on them).
  static const items = 'items';
  static const price = 'price';

  /// The passes sold, by id: `{type, price, sale}` and its type's own (`minutes`, `count`, `days`, `stack`, `until`,
  /// `max`, `limit`).
  static const passes = 'passes';
  static const type = 'type';
  static const minutes = 'minutes';
  static const count = 'count';
  static const days = 'days';
  static const stack = 'stack';
  static const max = 'max';
  static const limit = 'limit';

  /// Several things at once, by id: `{price, items, passes, limit, sale}`, `passes` by id.
  static const bundles = 'bundles';

  /// A discount: `{price, from, until}`, the price while the server's time is from `from` (or always) to `until`.
  static const sale = 'sale';
  static const from = 'from';
  static const until = 'until';

  /// The version the copy was read at.
  static const version = 'version';
}
