import '../models/ledger_write.dart';
import 'catalog_delegate.dart';

/// The server side of the account's wallet document, given by the app (Firestore, its own API, or a fake in tests):
/// hearing and writing the wallet, and the server's own values (an increment, a list union, its time). The catalog
/// comes from [CatalogDelegate] instead. A write must show in [watch] at once, before the server has it, and wait in a
/// queue while offline: that is what lets buying work offline.
abstract interface class WalletDelegate {
  /// Account [uid]'s wallet fields now and each time they change, its own writes included at once; null when it has
  /// none.
  Stream<Map<String, dynamic>?> watch(String uid);

  /// [change] (field paths with dots) written on [uid]'s wallet, with ledger [entry] created in the same batch when
  /// given: completes once the server has both, and throws when the server refuses them, which undoes both.
  Future<void> update(String uid, Map<String, Object?> change, {LedgerWrite? entry});

  /// A new id for a ledger entry of [uid]'s, unique without asking the server.
  String newEntryId(String uid);

  /// [uid]'s ledger, newest first: up to [limit] entries after entry [afterId] (from the newest when null), each as its
  /// id and stored fields.
  Future<List<({String id, Map<String, dynamic> data})>> ledger(String uid, {String? afterId, required int limit});

  /// [by] added by the server, as a field's value.
  Object increment(int by);

  /// [values] added to a list field where it lacks them, as a field's value.
  Object arrayUnion(List<Object?> values);

  /// The server's time at the write, as a field's value.
  Object get serverTime;

  /// [time] as a stored date.
  Object storedTime(DateTime time);

  /// A stored date as a time; null when [value] isn't one (a server time still on its way reads as null).
  DateTime? timeOf(Object? value);

  /// The phone is online.
  bool get online;

  /// [error] only says the server couldn't be reached in time, not that it refused.
  bool unreachable(Object error);
}
