import '../delegates/wallet_delegate.dart';
import '../models/ledger_entry.dart';
import 'wallet_doc.dart';

/// The signed-in account's ledger: every movement of its balance, newest first, read a page at a time (for a history
/// screen, or support). Spends offline show here once the delegate has them.
class Ledger {
  const Ledger(this._doc, this._delegate, this._historyOn);

  final WalletDoc _doc;
  final WalletDelegate _delegate;
  final bool Function() _historyOn;

  /// The app shows the history now (`ShopKit.setup`'s `history`): a history screen shows only then.
  bool get enabled => _historyOn();

  /// Up to [limit] entries after [after] (the last one of the page before; from the newest when null). Empty when no one
  /// is signed in, or the history is off (no read).
  Future<List<LedgerEntry>> page({LedgerEntry? after, int limit = 20}) async {
    final uid = _doc.uid;
    if (uid.isEmpty || !enabled) return const [];
    final docs = await _delegate.ledger(uid, afterId: after?.id, limit: limit);
    return [for (final d in docs) LedgerEntry.from(d.id, d.data, _delegate.timeOf)];
  }
}
