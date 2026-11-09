import 'package:flutter/foundation.dart' show Listenable;

/// Where the admin's catalog comes from, given by the app: its copy on the phone, the server's at a version, and that
/// version. Times in it are milliseconds since the epoch (UTC), and each copy keeps its version (`version`).
abstract interface class CatalogDelegate {
  /// The copy on the phone; null when there is none.
  Map<String, Object?>? cached();

  /// The server's catalog at [version], kept as the phone's copy; null when it couldn't be read.
  Future<Map<String, Object?>?> fetch(int version);

  /// The server's version now; null before it is known.
  int? get version;

  /// Told when [version] changes.
  Listenable get versionChanges;
}
