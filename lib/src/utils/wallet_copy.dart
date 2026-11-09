import 'dart:convert' show jsonDecode, jsonEncode;

import '../delegates/wallet_delegate.dart';

/// The wallet's fields as text to keep on the phone, and back: plain values as JSON, a stored date (whatever type the
/// backend gives, read by [WalletDelegate.timeOf]) as `{"$time": milliseconds}`, given back as the backend's own
/// ([WalletDelegate.storedTime]). Anything else (a value still on its way) is left out.
abstract final class WalletCopy {
  static const _time = r'$time';

  static String encode(Map<String, dynamic> wallet, WalletDelegate delegate) => jsonEncode(_out(wallet, delegate));

  /// [text]'s wallet; null when it is none, or can't be read.
  static Map<String, dynamic>? decode(String? text, WalletDelegate delegate) {
    if (text == null) return null;
    try {
      final value = _in(jsonDecode(text), delegate);
      return value is Map<String, dynamic> ? value : null;
    } catch (_) {
      return null;
    }
  }

  static Object? _out(Object? value, WalletDelegate delegate) {
    if (value == null || value is String || value is num || value is bool) return value;
    if (value is Map) {
      return {
        for (final MapEntry(:key, :value) in value.entries)
          if (_out(value, delegate) case final kept? when kept != _skip) '$key': kept,
      };
    }
    if (value is List) return [for (final v in value) _out(v, delegate)];
    final time = delegate.timeOf(value);
    return time == null ? _skip : {_time: time.millisecondsSinceEpoch};
  }

  static const _skip = Object();

  static Object? _in(Object? value, WalletDelegate delegate) {
    if (value is Map) {
      final ms = value[_time];
      if (value.length == 1 && ms is int) return delegate.storedTime(DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true));
      return <String, dynamic>{for (final MapEntry(:key, :value) in value.entries) '$key': _in(value, delegate)};
    }
    if (value is List) return [for (final v in value) _in(v, delegate)];
    return value;
  }
}
