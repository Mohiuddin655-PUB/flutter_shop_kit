import 'package:flutter/foundation.dart';
import 'package:flutter_shop_kit/flutter_shop_kit.dart';

/// A catalog on the phone, with no server.
class FakeCatalogDelegate implements CatalogDelegate {
  FakeCatalogDelegate(this.copy);

  Map<String, Object?>? copy;

  @override
  Map<String, Object?>? cached() => copy;

  @override
  Future<Map<String, Object?>?> fetch(int version) async => copy;

  @override
  int? get version => null;

  @override
  final Listenable versionChanges = ChangeNotifier();
}
