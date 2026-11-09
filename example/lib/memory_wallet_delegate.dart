import 'dart:async';

import 'package:flutter_shop_kit/flutter_shop_kit.dart';

/// A wallet in memory that behaves like Firestore offline: a write shows at once and, while [online] is off, waits in
/// a queue that goes through when it comes back.
class MemoryWalletDelegate implements WalletDelegate {
  MemoryWalletDelegate({Map<String, dynamic> start = const {}}) : _server = _copy(start);

  Map<String, dynamic> _server;
  final _ledger = <String, Map<String, dynamic>>{};
  final _queue = <(Map<String, Object?>, LedgerWrite?, Completer<void>)>[];
  var _ids = 0;
  final _out = StreamController<Map<String, dynamic>?>.broadcast();
  bool _online = true;

  @override
  bool get online => _online;

  set online(bool on) {
    _online = on;
    if (on) _flush();
  }

  /// The writes still waiting for the link.
  int get waiting => _queue.length;

  Map<String, dynamic> get _local {
    var doc = _copy(_server);
    for (final (change, _, _) in _queue) {
      doc = _apply(doc, change, null);
    }
    return doc;
  }

  @override
  Stream<Map<String, dynamic>?> watch(String uid) async* {
    yield _local;
    yield* _out.stream;
  }

  @override
  Future<void> update(String uid, Map<String, Object?> change, {LedgerWrite? entry}) {
    final done = Completer<void>();
    _queue.add((change, entry, done));
    _out.add(_local);
    if (_online) scheduleMicrotask(_flush);
    return done.future;
  }

  void _flush() {
    while (_queue.isNotEmpty) {
      final (change, entry, done) = _queue.removeAt(0);
      final now = DateTime.now().toUtc();
      _server = _apply(_copy(_server), change, now);
      if (entry != null) _ledger[entry.id] = _apply({}, entry.data, now);
      done.complete();
    }
    _out.add(_local);
  }

  final _phone = <String, String>{};

  @override
  Future<String?> loadLocal(String uid) async => _phone[uid];

  @override
  Future<void> saveLocal(String uid, String? text) async => text == null ? _phone.remove(uid) : _phone[uid] = text;

  @override
  Future<void> settled() async {
    while (_queue.isNotEmpty || !_online) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  @override
  Future<bool?> entryOnServer(String uid, String id) async => _ledger.containsKey(id);

  @override
  String newEntryId(String uid) => 'e${DateTime.now().microsecondsSinceEpoch}-${++_ids}';

  /// The ledger the server has, newest first (an example keeps it simple: the queue's entries show once sent).
  @override
  Future<List<({String id, Map<String, dynamic> data})>> ledger(String uid, {String? afterId, required int limit}) async {
    final sorted = _ledger.entries.toList()..sort((a, b) => (b.value[LedgerKeys.at] as DateTime).compareTo(a.value[LedgerKeys.at] as DateTime));
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
      node[path.last] = _value(value, node[path.last], at);
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
