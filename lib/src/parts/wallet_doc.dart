import 'dart:async' show StreamSubscription, Timer;

import 'package:flutter/foundation.dart';

import '../delegates/error_reporter.dart';
import '../delegates/shop_backend.dart';

/// The signed-in account's wallet document, heard once for [ShopKit]: its parts read their own fields from here. The
/// backend's copy at once (its own writes included), then the server's, and each change.
class WalletDoc extends ChangeNotifier {
  WalletDoc(this._backend, this._report);

  final ShopBackend _backend;
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
    _set(null);
    _retryAfter = _firstRetry;
    _listen();
  }

  /// Signed out: nothing of the account stays.
  Future<void> clear() async {
    _retry?.cancel();
    await _watch?.cancel();
    _watch = null;
    _uid = '';
    _set(null);
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
    _watch = _backend
        .watch(uid)
        .listen(
          (data) {
            _retryAfter = _firstRetry;
            _set(data);
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
