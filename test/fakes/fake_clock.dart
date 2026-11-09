/// The server's time, moved by the test.
class FakeClock {
  FakeClock([DateTime? start]) : now = start ?? DateTime.utc(2026, 11, 9, 12);

  DateTime now;

  void pass(Duration d) => now = now.add(d);
}
