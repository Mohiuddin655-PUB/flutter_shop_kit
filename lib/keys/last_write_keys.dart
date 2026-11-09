/// `lastWrite` on the wallet: `{kind, id, entry}`, what a write is, for the security rules alone (they can't find which
/// pass changed): its kind, the item, pass or bundle it is for, and the ledger entry written with it (a spend's). The app
/// never reads it; each such write sets it whole.
abstract final class LastWriteKeys {
  static const field = 'lastWrite';
  static const kind = 'kind';
  static const id = 'id';
  static const entry = 'entry';

  /// The kinds.
  static const itemBought = 'itemBought';
  static const passBought = 'passBought';
  static const passUsed = 'passUsed';
  static const bundleBought = 'bundleBought';

  /// The field naming a write of [kind] for [of], with its ledger [entry] (a spend's).
  static Map<String, Object?> of(String kind, String of, {String? entry}) => {
    field: {LastWriteKeys.kind: kind, id: of, LastWriteKeys.entry: ?entry},
  };
}
