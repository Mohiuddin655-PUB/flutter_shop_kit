/// The last refund the server took currency back for: its store transaction ([ref]), the [amount] taken back, and the
/// server's time ([at]).
class Refund {
  const Refund({required this.ref, required this.amount, this.at});

  final String ref;
  final int amount;
  final DateTime? at;
}
