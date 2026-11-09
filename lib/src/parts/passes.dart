import 'package:flutter/foundation.dart';

import '../../keys/last_write_keys.dart';
import '../../keys/wallet_keys.dart';
import '../delegates/clock.dart';
import '../delegates/wallet_delegate.dart';
import '../enums/pass_type.dart';
import '../enums/spend_result.dart';
import '../models/pass_state.dart';
import '../models/pass_terms.dart';
import '../utils/buy_counter.dart';
import '../utils/deep_equals.dart';
import 'wallet.dart';
import 'wallet_doc.dart';
import 'wallet_writer.dart';

/// The account's passes (`passes`, by id) of any [PassType]: whether one may be used, its uses left, buying and
/// using one, offline too. Told only when the passes change.
class Passes extends ChangeNotifier {
  Passes(this._doc, this._balance, this._writer, this._delegate, this._clock) {
    _doc.addListener(_docChanged);
  }

  final WalletDoc _doc;
  final Wallet _balance;
  final WalletWriter _writer;
  final WalletDelegate _delegate;
  final Clock _clock;

  Map<String, Object?> _passes = const {};

  /// Pass [id] as the wallet keeps it.
  PassState state(String id) => PassState.from(_passes[id], _clock.now, _delegate.timeOf);

  /// Pass [id] may be used now, by the server's clock, whatever its type: running, owned, or with uses left.
  bool on(String id) {
    final p = state(id), now = _clock.now;
    if (p.owned) return true;
    if (p.until != null) return p.until!.isAfter(now);
    if (p.from == null) return p.left > 0;
    if (p.days > 0) return p.dailyLeft(now) > 0;
    return p.within(now) && (!p.counts || p.left > 0);
  }

  /// Pass [id]'s uses left now: a counter's, a limited pass's while it runs, a daily pass's today.
  int left(String id) {
    final p = state(id), now = _clock.now;
    if (p.days > 0) return p.dailyLeft(now);
    return p.from == null || p.within(now) ? p.left : 0;
  }

  /// Why pass [id] on [terms] can't be sold now, as the rules refuse it, alone or in a bundle: an until pass past its
  /// date ([SpendResult.failed]), or past a counter's most uses ([SpendResult.overLimit]); null when it can.
  SpendResult? refusal(String id, PassTerms terms) {
    final until = terms.until;
    if (terms.type == PassType.until && (until == null || !until.isAfter(_clock.now))) return SpendResult.failed;
    if (terms.max > 0 && left(id) + terms.count > terms.max) return SpendResult.overLimit;
    return null;
  }

  /// The fields that give pass [id] on [terms] as its type gives it; null when it is held already (one that stacks adds
  /// its minutes instead). A purchase and a bundle both write them.
  Map<String, Object?>? grant(String id, PassTerms terms) {
    final p = state(id), now = _clock.now, at = _delegate.serverTime, until = terms.until;
    String path(String key) => WalletKeys.pass(id, key);
    final whole = '${WalletKeys.passes}.$id';
    return switch (terms.type) {
      PassType.duration when p.within(now) => terms.stack ? {path(WalletKeys.minutes): _delegate.increment(terms.minutes)} : null,
      PassType.duration => {
        whole: {WalletKeys.from: at, WalletKeys.minutes: terms.minutes},
      },
      PassType.counter => {path(WalletKeys.left): _delegate.increment(terms.count)},
      PassType.lifetime =>
        p.owned
            ? null
            : {
                whole: {WalletKeys.owned: true},
              },
      PassType.daily =>
        p.dailyOn(now)
            ? null
            : {
                whole: {WalletKeys.from: at, WalletKeys.days: terms.days, WalletKeys.count: terms.count, WalletKeys.window: 0, WalletKeys.used: 0},
              },
      PassType.limited =>
        p.within(now) && p.left > 0
            ? null
            : {
                whole: {WalletKeys.from: at, WalletKeys.minutes: terms.minutes, WalletKeys.left: terms.count},
              },
      PassType.until =>
        on(id) || until == null
            ? null
            : {
                whole: {WalletKeys.until: _delegate.storedTime(until)},
              },
    };
  }

  /// Pass [id] on [terms], offline too, as its type sells it; nothing is taken when it is held already. One the rules
  /// refuse is its [refusal]; past the pass's buying limit, [SpendResult.overLimit].
  Future<SpendResult> buy(String id, PassTerms terms) async {
    final refused = refusal(id, terms);
    if (refused != null) return refused;
    final change = grant(id, terms);
    if (change == null) return SpendResult.done;
    final counted = countBuy(_delegate, _doc.data, WalletKeys.passBuys, id, terms.limit, _clock.now);
    if (counted == null) return SpendResult.overLimit;
    return _balance.spend(terms.price, {...change, ...counted, ...LastWriteKeys.of(LastWriteKeys.passBought, id)});
  }

  /// One use of pass [id] (a counter, a limited pass while it runs, a daily pass within today's count), offline too;
  /// false with none left.
  Future<bool> use(String id) async {
    final uid = _doc.uid, p = state(id), now = _clock.now;
    if (uid.isEmpty || left(id) < 1) return false;
    String path(String key) => WalletKeys.pass(id, key);
    final w = p.windowAt(now);
    final Map<String, Object?> change = p.days > 0
        ? (w == p.window ? {path(WalletKeys.used): _delegate.increment(1)} : {path(WalletKeys.window): w, path(WalletKeys.used): 1})
        : {path(WalletKeys.left): _delegate.increment(-1)};
    final result = await _writer.write(uid, {...change, ...LastWriteKeys.of(LastWriteKeys.passUsed, id)}, onRefused: _balance.refused);
    return result == SpendResult.done || result == SpendResult.pending;
  }

  void _docChanged() {
    final passes = _doc.data?[WalletKeys.passes];
    final next = passes is Map ? Map<String, Object?>.from(passes) : const <String, Object?>{};
    if (deepEquals(next, _passes)) return;
    _passes = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _doc.removeListener(_docChanged);
    super.dispose();
  }
}
