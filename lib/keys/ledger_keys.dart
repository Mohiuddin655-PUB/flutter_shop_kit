/// The wallet's ledger (`ledger`, one document per currency movement, under the wallet): append-only, written with the
/// wallet change it records, by the app (a spend) or the server (a pack bought, a refund).
abstract final class LedgerKeys {
  /// The ledger's collection, under the wallet document.
  static const collection = 'ledger';

  /// `debit` (currency out) or `credit` (currency in).
  static const kind = 'kind';
  static const debit = 'debit';
  static const credit = 'credit';

  /// Why: what was bought, or [packBought] / [refund] from the server.
  static const reason = 'reason';
  static const itemBought = 'itemBought';
  static const passBought = 'passBought';
  static const bundleBought = 'bundleBought';
  static const packBought = 'packBought';
  static const refund = 'refund';

  /// The item, pass, bundle or store transaction it is for.
  static const ref = 'ref';

  /// The balance's change: negative for a debit.
  static const amount = 'amount';

  /// The server's time it was written.
  static const at = 'at';

  /// Who wrote it: `app` or `server`.
  static const source = 'source';
  static const app = 'app';
  static const server = 'server';
}
