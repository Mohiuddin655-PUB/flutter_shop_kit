import 'dart:async' show TimeoutException, unawaited;

import 'package:flutter/foundation.dart' show VoidCallback;

import '../delegates/error_reporter.dart';
import '../delegates/shop_backend.dart';
import '../enums/spend_result.dart';

/// Writes on the wallet, offline too: a write shows at once; the server answering late, or the link being down, leaves
/// it [SpendResult.pending], and a refusal then undoes it and calls its `onRefused`.
class WalletWriter {
  const WalletWriter(this._backend, this._report, {this.wait = const Duration(seconds: 10)});

  final ShopBackend _backend;
  final ErrorReporter? _report;

  /// How long a write online waits for the server before it is left to finish in the queue.
  final Duration wait;

  Future<SpendResult> write(String uid, Map<String, Object?> change, {VoidCallback? onRefused}) async {
    final write = _backend.update(uid, change);
    if (_backend.online) {
      try {
        await write.timeout(wait);
        return SpendResult.done;
      } on TimeoutException {
        // Still on its way: its answer comes later.
      } catch (error, stack) {
        return _fault('write', error, stack);
      }
    }
    unawaited(
      write.then(
        (_) {},
        onError: (Object error, StackTrace stack) {
          _fault('write queued', error, stack);
          onRefused?.call();
        },
      ),
    );
    return SpendResult.pending;
  }

  /// Offline is expected: only a refusal or a fault is worth a report.
  SpendResult _fault(String where, Object error, StackTrace stack) {
    if (_backend.unreachable(error) || !_backend.online) return SpendResult.offline;
    _report?.call(error, stack, where);
    return SpendResult.failed;
  }
}
