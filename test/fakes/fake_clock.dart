import 'package:flutter_shop_kit/flutter_shop_kit.dart';

/// The server's time, moved by the test.
class FakeClock implements Clock {
  FakeClock([DateTime? start]) : now = start ?? DateTime.utc(2026, 11, 9, 12);

  @override
  DateTime now;

  void pass(Duration d) => now = now.add(d);
}
