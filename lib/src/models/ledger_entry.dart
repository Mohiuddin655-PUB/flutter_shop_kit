import '../../keys/ledger_keys.dart';

/// One movement of the balance in the ledger: a [debit] (a spend) or a credit (a pack, a refund), for its [reason] and
/// [ref], by [amount] (negative for a debit), at the server's time [at] (null while it is on its way), written by the
/// app or the server ([source]).
class LedgerEntry {
  const LedgerEntry({required this.id, required this.debit, required this.reason, required this.ref, required this.amount, this.at, required this.source});

  /// Entry [id] from its stored [data]; [timeOf] reads a stored date.
  factory LedgerEntry.from(String id, Map<String, dynamic> data, DateTime? Function(Object? value) timeOf) {
    String text(String key) => data[key] is String ? data[key] as String : '';
    final amount = data[LedgerKeys.amount];
    return LedgerEntry(
      id: id,
      debit: data[LedgerKeys.kind] == LedgerKeys.debit,
      reason: text(LedgerKeys.reason),
      ref: text(LedgerKeys.ref),
      amount: amount is num ? amount.toInt() : 0,
      at: timeOf(data[LedgerKeys.at]),
      source: text(LedgerKeys.source),
    );
  }

  final String id;
  final bool debit;
  final String reason, ref, source;
  final int amount;
  final DateTime? at;
}
