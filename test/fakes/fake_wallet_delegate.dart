import 'dart:async';

import 'package:flutter_shop_kit/flutter_shop_kit.dart';

import 'fake_clock.dart';

/// A wallet in memory that behaves like Firestore offline: a write shows at once (a server time still on its way reads
/// null), waits in a queue while offline or [holding], and a [refuse]d one is undone and throws.
class FakeWalletDelegate implements WalletDelegate {
  FakeWalletDelegate(this.clock);

  final FakeClock clock;

  /// What the server has.
  Map<String, dynamic>? server;

  @override
  bool online = true;

  /// Online, but the server doesn't answer yet.
  bool holding = false;

  /// The rules: true refuses the change.
  bool Function(Map<String, Object?> change)? refuse;

  /// The server's ledger, by entry id.
  final ledgerOnServer = <String, Map<String, dynamic>>{};

  final _queue = <(Map<String, Object?>, LedgerWrite?, Completer<void>)>[];
  var _ids = 0;
  final _watchers = <StreamController<Map<String, dynamic>?>>[];

  /// What the phone shows: the server's, with the queue on top.
  Map<String, dynamic>? get local {
    if (server == null && _queue.isEmpty) return null;
    var doc = _copy(server ?? {});
    for (final (change, _, _) in _queue) {
      doc = _apply(doc, change, null);
    }
    return doc;
  }

  @override
  Stream<Map<String, dynamic>?> watch(String uid) {
    late final StreamController<Map<String, dynamic>?> c;
    c = StreamController<Map<String, dynamic>?>(onListen: () => c.add(local), onCancel: () => _watchers.remove(c));
    _watchers.add(c);
    return c.stream;
  }

  @override
  Future<void> update(String uid, Map<String, Object?> change, {LedgerWrite? entry}) {
    final done = Completer<void>();
    _queue.add((change, entry, done));
    _tell();
    if (online && !holding) scheduleMicrotask(flush);
    return done.future;
  }

  /// The server takes the queue, refusing what the rules refuse.
  void flush() {
    while (_queue.isNotEmpty) {
      final (change, entry, done) = _queue.removeAt(0);
      if (refuse?.call(change) ?? false) {
        done.completeError(StateError('permission-denied'));
      } else {
        server = _apply(_copy(server ?? {}), change, clock.now);
        if (entry != null) ledgerOnServer[entry.id] = _apply({}, entry.data, clock.now);
        done.complete();
      }
    }
    _tell();
  }

  /// Back online: the queue goes to the server.
  void goOnline() {
    online = true;
    holding = false;
    flush();
  }

  /// The server's doc changed by itself (a pack, another phone).
  void serverSets(Map<String, dynamic> doc) {
    server = doc;
    _tell();
  }

  void _tell() {
    final doc = local;
    for (final c in [..._watchers]) {
      c.add(doc);
    }
  }

  @override
  String newEntryId(String uid) => 'e${++_ids}';

  /// The ledger as the phone shows it: the server's, with the queue's entries (their time still on its way).
  @override
  Future<List<({String id, Map<String, dynamic> data})>> ledger(String uid, {String? afterId, required int limit}) async {
    final all = <String, Map<String, dynamic>>{
      ...ledgerOnServer,
      for (final (_, entry, _) in _queue)
        if (entry != null) entry.id: _apply({}, entry.data, null),
    };
    final sorted = all.entries.toList()
      ..sort((a, b) {
        final x = a.value[LedgerKeys.at] as DateTime?, y = b.value[LedgerKeys.at] as DateTime?;
        if (x == null || y == null) return x == null ? (y == null ? b.key.compareTo(a.key) : -1) : 1;
        final byTime = y.compareTo(x);
        return byTime != 0 ? byTime : b.key.compareTo(a.key);
      });
    final from = afterId == null ? 0 : sorted.indexWhere((e) => e.key == afterId) + 1;
    return [for (final e in sorted.skip(from).take(limit)) (id: e.key, data: e.value)];
  }

  @override
  Object increment(int by) => _Increment(by);

  @override
  Object arrayUnion(List<Object?> values) => _Union(values);

  @override
  Object get serverTime => const _ServerTime();

  @override
  Object storedTime(DateTime time) => time;

  @override
  DateTime? timeOf(Object? value) => value is DateTime ? value : null;

  @override
  bool unreachable(Object error) => error is TimeoutException;

  static Map<String, dynamic> _copy(Map<dynamic, dynamic> m) => {
    for (final MapEntry(:key, :value) in m.entries) '$key': value is Map ? _copy(value) : (value is List ? [...value] : value),
  };

  static Map<String, dynamic> _apply(Map<String, dynamic> doc, Map<String, Object?> change, DateTime? at) {
    for (final MapEntry(:key, :value) in change.entries) {
      final path = key.split('.');
      var node = doc;
      for (final part in path.take(path.length - 1)) {
        node = (node[part] is Map ? node[part] : node[part] = <String, dynamic>{}) as Map<String, dynamic>;
      }
      final last = path.last, before = node[last];
      node[last] = _value(value, before, at);
    }
    return doc;
  }

  static Object? _value(Object? value, Object? before, DateTime? at) => switch (value) {
    _Increment(:final by) => (before is num ? before : 0) + by,
    _Union(:final values) => [...(before is List ? before : const []), ...values.where((v) => !(before is List && before.contains(v)))],
    _ServerTime() => at,
    Map() => {for (final MapEntry(:key, :value) in value.entries) '$key': _value(value, null, at)},
    _ => value,
  };
}

class _Increment {
  const _Increment(this.by);
  final int by;
}

class _Union {
  const _Union(this.values);
  final List<Object?> values;
}

class _ServerTime {
  const _ServerTime();
}
