import 'dart:async' show TimeoutException, unawaited;

import 'package:flutter/foundation.dart' show VoidCallback;

import '../delegates/error_reporter.dart';
import '../delegates/wallet_delegate.dart';
import '../enums/spend_result.dart';
import '../models/ledger_write.dart';

/// Writes on the wallet, offline too: a write shows at once; the server answering late, or the link being down, leaves
/// it [SpendResult.pending], and a refusal then undoes it and calls its `onRefused`.
class WalletWriter {
  const WalletWriter(this._delegate, this._report, {this.wait = const Duration(seconds: 10)});

  final WalletDelegate _delegate;
  final ErrorReporter? _report;

  /// How long a write online waits for the server before it is left to finish in the queue.
  final Duration wait;

  /// [change], with ledger [entry] in the same batch when given.
  /// [onSaved] when a write left pending reaches the server.
  Future<SpendResult> write(String uid, Map<String, Object?> change, {LedgerWrite? entry, VoidCallback? onRefused, VoidCallback? onSaved}) async {
    final write = _delegate.update(uid, change, entry: entry);
    if (_delegate.online) {
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
        (_) => onSaved?.call(),
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
    if (_delegate.unreachable(error) || !_delegate.online) return SpendResult.offline;
    _report?.call(error, stack, where);
    return SpendResult.failed;
  }
}
