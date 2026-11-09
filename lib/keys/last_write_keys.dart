/// `lastWrite` on the wallet: `{kind, id}`, what a write of a pass or a bundle is, for the security rules alone (they
/// can't find which pass changed). The app never reads it; each such write sets it whole.
abstract final class LastWriteKeys {
  static const field = 'lastWrite';
  static const kind = 'kind';
  static const id = 'id';

  /// The kinds.
  static const passBought = 'passBought';
  static const passUsed = 'passUsed';
  static const bundleBought = 'bundleBought';

  /// The field naming a write of [kind] for pass or bundle [of].
  static Map<String, Object?> of(String kind, String of) => {
    field: {LastWriteKeys.kind: kind, id: of},
  };
}
