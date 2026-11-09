/// The fields of the account's wallet document, as the security rules and the server keep them.
abstract final class WalletKeys {
  /// `{amount, last_purchase_at, last_purchase_amount}`: the balance, and the last pack bought with money (written by
  /// the server only).
  static const points = 'points';
  static const amount = 'amount';
  static const lastPurchaseAt = 'last_purchase_at';
  static const lastPurchaseAmount = 'last_purchase_amount';

  /// [amount] inside [points], as a field path for an update.
  static const pointsAmount = '$points.$amount';

  /// The items owned, by id.
  static const items = 'items';

  /// The passes by id, each as its type keeps it: `from` (the server's time it was bought), `minutes`, `days`,
  /// `count`, `left`, `window` and `used`, `until`, `owned`.
  static const passes = 'passes';
  static const from = 'from';
  static const minutes = 'minutes';
  static const days = 'days';
  static const count = 'count';
  static const left = 'left';
  static const window = 'window';
  static const used = 'used';
  static const until = 'until';
  static const owned = 'owned';

  /// The buys of a pass or a bundle with a limit, by id: `{count, from}`, `from` the server's time of the first buy of
  /// its minutes.
  static const passBuys = 'passBuys';
  static const bundleBuys = 'bundleBuys';

  /// The last refund, written by the server (`{ref, amount, at}`: the store transaction, the currency taken back, the
  /// server's time), and the one the app has told (`refundSeen`: its `ref`).
  static const lastRefund = 'lastRefund';
  static const refundSeen = 'refundSeen';
  static const ref = 'ref';
  static const at = 'at';

  /// [key] of pass [id], as a field path for an update.
  static String pass(String id, String key) => '$passes.$id.$key';
}
