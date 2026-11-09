import 'dart:convert' show jsonDecode, jsonEncode;

import '../delegates/wallet_delegate.dart';

/// A spend still on its way to the server: its ledger entry's [id], what it was for and its [price].
typedef PendingSpend = ({String id, String reason, String ref, int price});

/// The spends taken on this phone that the server hasn't answered yet, kept on the phone (by the delegate) so a spend
/// the server refuses after the app was closed is still told: at the next start, once the phone's queue has reached
/// the server, a spend whose ledger entry isn't there was refused (the entry goes in the same batch as the spend).
class PendingSpends {
  PendingSpends(this._delegate, this._refused);

  final WalletDelegate _delegate;
  final void Function(String reason, String ref, int price) _refused;

  /// One change of the phone's copy at a time.
  Future<void> _turn = Future.value();

  Future<T> _serial<T>(Future<T> Function() work) {
    final next = _turn.then((_) => work());
    _turn = next.then((_) {}, onError: (Object _) {});
    return next;
  }

  Future<List<PendingSpend>> _load(String uid) async {
    try {
      final text = await _delegate.loadLocal(uid), list = text == null ? null : jsonDecode(text);
      return [
        if (list is List)
          for (final e in list)
            if (e is Map && e['id'] is String && e['reason'] is String && e['ref'] is String && e['price'] is int)
              (id: e['id'] as String, reason: e['reason'] as String, ref: e['ref'] as String, price: e['price'] as int),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _save(String uid, List<PendingSpend> list) => _delegate.saveLocal(
    uid,
    list.isEmpty
        ? null
        : jsonEncode([
            for (final p in list) {'id': p.id, 'reason': p.reason, 'ref': p.ref, 'price': p.price},
          ]),
  );

  /// [spend] of [uid]'s is on its way.
  Future<void> add(String uid, PendingSpend spend) => _serial(() async => _save(uid, [...await _load(uid), spend]));

  /// Spend [id] of [uid]'s was answered (taken, refused here, or never sent).
  Future<void> remove(String uid, String id) => _serial(() async {
    final list = await _load(uid);
    if (list.any((p) => p.id == id)) await _save(uid, [...list.where((p) => p.id != id)]);
  });

  /// At start, the spends a closed app left on their way: once the phone's queue has reached the server, each whose
  /// entry isn't there is told as refused; each found was taken. One that couldn't be read waits for the next start.
  Future<void> check(String uid) async {
    final left = await _serial(() => _load(uid));
    if (left.isEmpty) return;
    await _delegate.settled();
    for (final spend in left) {
      final taken = await _delegate.entryOnServer(uid, spend.id);
      if (taken == null) continue;
      final still = await _serial(() => _load(uid));
      if (!still.any((p) => p.id == spend.id)) continue;
      if (!taken) _refused(spend.reason, spend.ref, spend.price);
      await remove(uid, spend.id);
    }
  }
}
