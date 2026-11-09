import 'dart:async' show Completer;

import 'package:flutter/foundation.dart';

import '../../keys/wallet_keys.dart';
import '../delegates/shop_backend.dart';
import '../enums/spend_result.dart';
import 'wallet_doc.dart';
import 'wallet_writer.dart';

/// The account's balance (`points`): the amount, the last pack bought with money, and spending it, offline too. Told
/// only when the balance part changes.
class Wallet extends ChangeNotifier {
  Wallet(this._doc, this._writer, this._backend) {
    _doc.addListener(_docChanged);
  }

  final WalletDoc _doc;
  final WalletWriter _writer;
  final ShopBackend _backend;

  int _amount = 0, _refused = 0;
  int? _lastPurchaseAmount;
  DateTime? _lastPurchaseAt;

  int get amount => _amount;

  /// The last pack bought with money: when (the server's time) and how much it gave.
  DateTime? get lastPurchaseAt => _lastPurchaseAt;
  int? get lastPurchaseAmount => _lastPurchaseAmount;

  /// Spends taken on this phone (offline, or answered late) that the server then refused, each undone by itself: counts
  /// up with each one, for the screen to say so.
  int get refusedSpends => _refused;

  /// Takes [price] for [change] (what is bought, as the wallet's fields), unless the balance doesn't cover it. Offline
  /// it is [SpendResult.pending]: shown at once, sent once back online, undone if the server refuses it.
  Future<SpendResult> spend(int price, Map<String, Object?> change) async {
    final uid = _doc.uid;
    if (uid.isEmpty) return SpendResult.failed;
    if (_amount < price) return SpendResult.notEnough;
    return _writer.write(uid, {...change, WalletKeys.pointsAmount: _backend.increment(-price)}, onRefused: refused);
  }

  /// A spend or a use the server refused after it showed: told on screen.
  void refused() {
    _refused++;
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
    final amount = whole(map[WalletKeys.amount]) ?? 0, at = _backend.timeOf(map[WalletKeys.lastPurchaseAt]);
    final last = whole(map[WalletKeys.lastPurchaseAmount]);
    if (amount == _amount && at == _lastPurchaseAt && last == _lastPurchaseAmount) return;
    _amount = amount;
    _lastPurchaseAt = at;
    _lastPurchaseAmount = last;
    notifyListeners();
  }

  @override
  void dispose() {
    _doc.removeListener(_docChanged);
    super.dispose();
  }
}
