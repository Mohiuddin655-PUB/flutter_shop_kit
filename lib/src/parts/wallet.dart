import 'dart:async' show Completer;

import 'package:flutter/foundation.dart';

import '../../keys/last_write_keys.dart';
import '../../keys/ledger_keys.dart';
import '../../keys/wallet_keys.dart';
import '../delegates/wallet_delegate.dart';
import '../enums/spend_result.dart';
import '../models/refund.dart';
import '../models/refused_spend.dart';
import 'pending_spends.dart';
import 'wallet_doc.dart';
import 'wallet_writer.dart';

/// The account's balance (`points`): the amount, the last pack bought with money, and spending it, offline too. Told
/// only when the balance part changes.
class Wallet extends ChangeNotifier {
  Wallet(this._doc, this._writer, this._delegate, this._ledgerOn) {
    _doc.addListener(_docChanged);
  }

  late final _pending = PendingSpends(_delegate, refused);

  final WalletDoc _doc;
  final WalletWriter _writer;
  final WalletDelegate _delegate;

  /// The app keeps the ledger now (`ShopKit.setup`'s `ledger`).
  final bool Function() _ledgerOn;

  int _amount = 0;
  List<RefusedSpend> _refusals = const [];
  Refund? _refund;
  int? _lastPurchaseAmount;
  DateTime? _lastPurchaseAt;

  int get amount => _amount;

  /// What is owed when the balance is below zero (after a refund of currency already spent); 0 when nothing is.
  int get debt => _amount < 0 ? -_amount : 0;

  /// The last pack bought with money: when (the server's time) and how much it gave.
  DateTime? get lastPurchaseAt => _lastPurchaseAt;
  int? get lastPurchaseAmount => _lastPurchaseAmount;

  /// The last refund that took currency back, until it is told ([seenRefund]) on any of the account's phones; null
  /// when there is none to tell.
  Refund? get refund => _refund;

  /// The last [refund] was told: marked on the server, offline too, so it isn't told again anywhere.
  Future<void> seenRefund() async {
    final refund = _refund, uid = _doc.uid;
    if (refund == null || uid.isEmpty) return;
    await _writer.write(uid, {WalletKeys.refundSeen: refund.ref});
  }

  /// Spends (and passes' uses) taken on this phone, offline or answered late, that the server then refused, each undone
  /// by itself, oldest first: for the screen to say so, each once ([seen]).
  List<RefusedSpend> get refusals => _refusals;

  /// [refusal] was shown: it leaves [refusals], so it isn't shown again.
  void seen(RefusedSpend refusal) {
    if (!_refusals.contains(refusal)) return;
    _refusals = [..._refusals.where((r) => r != refusal)];
    notifyListeners();
  }

  /// Signed out: the refusals of the account go with it.
  void forgetRefusals() {
    if (_refusals.isEmpty) return;
    _refusals = const [];
    notifyListeners();
  }

  /// Takes [price] for [change] (what is bought, as the wallet's fields), unless the balance doesn't cover it, recording
  /// it in the ledger as [reason] (a [LastWriteKeys] kind, which names the write too) for [ref], in one batch. Offline it
  /// is [SpendResult.pending]: shown at once, sent once back online, undone if the server refuses it.
  Future<SpendResult> spend(int price, Map<String, Object?> change, {required String reason, required String ref}) async {
    final uid = _doc.uid;
    if (uid.isEmpty) return SpendResult.failed;
    if (_amount < 0) return SpendResult.inDebt;
    if (_amount < price) return SpendResult.notEnough;
    final paid = {...change, WalletKeys.pointsAmount: _delegate.increment(-price)};
    // With the ledger off, no entry: nothing kept to check after a restart either (it is checked by its entry).
    if (!_ledgerOn()) {
      return _writer.write(uid, {...paid, ...LastWriteKeys.of(reason, ref)}, onRefused: () => refused(reason, ref, price));
    }
    final id = _delegate.newEntryId(uid);
    final entry = {
      LedgerKeys.kind: LedgerKeys.debit,
      LedgerKeys.reason: reason,
      LedgerKeys.ref: ref,
      LedgerKeys.amount: -price,
      LedgerKeys.at: _delegate.serverTime,
      LedgerKeys.source: LedgerKeys.app,
    };
    // Kept on the phone until answered, so a refusal after the app was closed is still told ([checkPending]).
    await _pending.add(uid, (id: id, reason: reason, ref: ref, price: price));
    final result = await _writer.write(
      uid,
      {...paid, ...LastWriteKeys.of(reason, ref, entry: id)},
      entry: (id: id, data: entry),
      onRefused: () {
        refused(reason, ref, price);
        _pending.remove(uid, id);
      },
      onSaved: () => _pending.remove(uid, id),
    );
    if (result != SpendResult.pending) await _pending.remove(uid, id);
    return result;
  }

  /// The account [uid] was signed in: the spends a closed app left on their way are checked once the queue reaches the
  /// server, and each refused is told.
  Future<void> checkPending(String uid) => _pending.check(uid);

  /// A spend of [price] for [reason] of [ref] (or a use, at 0) the server refused after it showed: kept for the screen.
  void refused(String reason, String ref, int price) {
    _refusals = [..._refusals, RefusedSpend(reason: reason, ref: ref, price: price, at: DateTime.now())];
    notifyListeners();
  }

  /// The amount of a pack bought after the one at [before] ([lastPurchaseAt]), once the server has added it; null when
  /// it hasn't come within [timeout] (it still comes, on its own).
  Future<int?> purchaseAfter(DateTime? before, Duration timeout) {
    bool arrived() => _lastPurchaseAt != null && _lastPurchaseAt != before;
    if (arrived()) return Future.value(_lastPurchaseAmount);
    final done = Completer<int?>();
    void check() {
      if (arrived() && !done.isCompleted) done.complete(_lastPurchaseAmount);
    }

    addListener(check);
    return done.future.timeout(timeout, onTimeout: () => null).whenComplete(() => removeListener(check));
  }

  void _docChanged() {
    final points = _doc.data?[WalletKeys.points];
    final map = points is Map ? points : const {};
    int? whole(Object? v) => v is num ? v.toInt() : null;
    final amount = whole(map[WalletKeys.amount]) ?? 0, at = _delegate.timeOf(map[WalletKeys.lastPurchaseAt]);
    final last = whole(map[WalletKeys.lastPurchaseAmount]);
    final refund = _unseenRefund(_doc.data);
    if (amount == _amount && at == _lastPurchaseAt && last == _lastPurchaseAmount && refund?.ref == _refund?.ref) return;
    _refund = refund;
    _amount = amount;
    _lastPurchaseAt = at;
    _lastPurchaseAmount = last;
    notifyListeners();
  }

  Refund? _unseenRefund(Map<String, dynamic>? data) {
    final last = data?[WalletKeys.lastRefund];
    if (last is! Map || last[WalletKeys.ref] is! String || last[WalletKeys.ref] == data?[WalletKeys.refundSeen]) return null;
    final amount = last[WalletKeys.amount];
    return Refund(ref: last[WalletKeys.ref] as String, amount: amount is num ? amount.toInt() : 0, at: _delegate.timeOf(last[WalletKeys.at]));
  }

  @override
  void dispose() {
    _doc.removeListener(_docChanged);
    super.dispose();
  }
}
