/// A spend (or a pass's use) taken on this phone, offline or answered late, that the server then refused and that was
/// undone by itself: what it was for ([reason], a `LastWriteKeys` kind, and [ref]), the [price] given back (0 for a
/// use), and when it was refused ([at], the phone's time).
class RefusedSpend {
  const RefusedSpend({required this.reason, required this.ref, required this.price, required this.at});

  final String reason, ref;
  final int price;
  final DateTime at;
}
