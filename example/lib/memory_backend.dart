import 'dart:async';

import 'package:flutter_shop_kit/flutter_shop_kit.dart';

/// A wallet in memory that behaves like Firestore offline: a write shows at once and, while [online] is off, waits in
/// a queue that goes through when it comes back.
class MemoryBackend implements ShopBackend {
  MemoryBackend({Map<String, dynamic> start = const {}}) : _server = _copy(start);

  Map<String, dynamic> _server;
  final _queue = <(Map<String, Object?>, Completer<void>)>[];
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
    for (final (change, _) in _queue) {
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
  Future<void> update(String uid, Map<String, Object?> change) {
    final done = Completer<void>();
    _queue.add((change, done));
    _out.add(_local);
    if (_online) scheduleMicrotask(_flush);
    return done.future;
  }

  void _flush() {
    while (_queue.isNotEmpty) {
      final (change, done) = _queue.removeAt(0);
      _server = _apply(_copy(_server), change, DateTime.now().toUtc());
      done.complete();
    }
    _out.add(_local);
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
