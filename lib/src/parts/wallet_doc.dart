import 'dart:async' show StreamSubscription, Timer, unawaited;

import 'package:flutter/foundation.dart';

import '../delegates/error_reporter.dart';
import '../delegates/wallet_delegate.dart';
import '../utils/wallet_copy.dart';

/// The signed-in account's wallet document, heard once for [ShopKit]: its parts read their own fields from here. The
/// delegate's copy at once (its own writes included), then the server's, and each change.
class WalletDoc extends ChangeNotifier {
  WalletDoc(this._delegate, this._report);

  final WalletDelegate _delegate;
  final ErrorReporter? _report;

  String _uid = '';
  StreamSubscription<Map<String, dynamic>?>? _watch;
  Map<String, dynamic>? _data;

  /// The signed-in account; empty when none.
  String get uid => _uid;

  /// The wallet's fields; null before they are heard, or while it has none.
  Map<String, dynamic>? get data => _data;

  /// [uid] is signed in.
  void start(String uid) {
    if (uid.isEmpty || uid == _uid) return;
    _uid = uid;
    _heard = false;
    _set(null);
    _retryAfter = _firstRetry;
    _listen();
    unawaited(_showKept(uid));
  }

  static const _copy = 'wallet';

  /// The backend has answered since the start, so the phone's copy no longer shows.
  bool _heard = false;

  /// The wallet last heard, kept on the phone, shown until the backend answers (offline, or slow), whatever it is.
  Future<void> _showKept(String uid) async {
    final kept = WalletCopy.decode(await _delegate.loadLocal(uid, _copy), _delegate);
    if (kept != null && !_heard && uid == _uid) _set(kept);
  }

  /// Signed out: nothing of the account stays, on screen or on the phone (its wallet's copy is wiped; its spends still
  /// on their way stay, so a refusal is still told when it signs in again).
  Future<void> clear() async {
    final uid = _uid;
    _retry?.cancel();
    await _watch?.cancel();
    _watch = null;
    _uid = '';
    _set(null);
    if (uid.isNotEmpty) await _delegate.saveLocal(uid, _copy, null).catchError((Object _) {});
  }

  Timer? _retry;
  Duration _retryAfter = _firstRetry;
  static const _firstRetry = Duration(seconds: 30);
  static const _lastRetry = Duration(minutes: 10);

  /// A listener that errors stops for good, so it is started again after a pause, each pause twice the one before (up
  /// to [_lastRetry]), while the same account is signed in.
  void _listen() {
    final uid = _uid;
    _retry?.cancel();
    _watch?.cancel();
    _watch = _delegate
        .watch(uid)
        .listen(
          (data) {
            _retryAfter = _firstRetry;
            _heard = true;
            _set(data);
            unawaited(_delegate.saveLocal(uid, _copy, data == null ? null : WalletCopy.encode(data, _delegate)).catchError((Object _) {}));
          },
          onError: (Object error, StackTrace stack) {
            _report?.call(error, stack, 'wallet');
            _retry?.cancel();
            _retry = Timer(_retryAfter, () {
              if (_uid == uid) _listen();
            });
            final next = _retryAfter * 2;
            _retryAfter = next > _lastRetry ? _lastRetry : next;
          },
        );
  }

  void _set(Map<String, dynamic>? data) {
    _data = data;
    notifyListeners();
  }

  @override
  void dispose() {
    _retry?.cancel();
    _watch?.cancel();
    super.dispose();
  }
}
