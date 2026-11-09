import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_shop_kit/flutter_shop_kit.dart';

import 'fake_catalog_delegate.dart';
import 'fake_clock.dart';
import 'fake_wallet_delegate.dart';

/// A test's kit: [uid] signed in with [points] and [more] fields, on [catalog], heard once.
class TestShopKit {
  TestShopKit._(this.clock, this.delegate);

  static Future<TestShopKit> make({int points = 1000, Map<String, dynamic> more = const {}, Map<String, Object?>? catalog}) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final clock = FakeClock(), delegate = FakeWalletDelegate(clock);
    delegate.server = {
      WalletKeys.points: {WalletKeys.amount: points},
      ...more,
    };
    ShopKit.reset();
    ShopKit.setup(
      walletDelegate: delegate,
      now: () => clock.now,
      catalogDelegate: FakeCatalogDelegate(catalog ?? testCatalog),
      writeWait: const Duration(milliseconds: 50),
    );
    ShopKit.start(uid);
    await settle();
    return TestShopKit._(clock, delegate);
  }

  static const uid = 'u1';

  final FakeClock clock;
  final FakeWalletDelegate delegate;

  /// The wallet as the phone shows it.
  Map<String, dynamic> get local => delegate.local ?? {};

  /// The app closed and opened again on the same phone (its delegate, its clock), signed in.
  Future<void> reopen() async {
    delegate.closeApp();
    ShopKit.reset();
    ShopKit.setup(
      walletDelegate: delegate,
      now: () => clock.now,
      catalogDelegate: FakeCatalogDelegate(testCatalog),
      writeWait: const Duration(milliseconds: 50),
    );
    ShopKit.start(uid);
    await settle();
  }

  /// Lets the streams and the queue run.
  static Future<void> settle() => Future<void>.delayed(Duration.zero);
}

/// Items `a1` (100) and `a2` (200, on sale for 150 within its dates); passes of each type; bundles.
final testCatalog = <String, Object?>{
  CatalogKeys.items: {
    'a1': {CatalogKeys.price: 100},
    'a2': {
      CatalogKeys.price: 200,
      CatalogKeys.sale: {CatalogKeys.price: 150, CatalogKeys.until: DateTime.utc(2026, 11, 10).millisecondsSinceEpoch},
    },
  },
  CatalogKeys.passes: {
    'filters': {CatalogKeys.type: 'duration', CatalogKeys.minutes: 60, CatalogKeys.price: 100},
    'boost': {CatalogKeys.type: 'duration', CatalogKeys.minutes: 30, CatalogKeys.stack: true, CatalogKeys.price: 50},
    'likes': {CatalogKeys.type: 'counter', CatalogKeys.count: 20, CatalogKeys.max: 30, CatalogKeys.price: 150},
    'vip': {CatalogKeys.type: 'lifetime', CatalogKeys.price: 500},
    'daily': {CatalogKeys.type: 'daily', CatalogKeys.days: 3, CatalogKeys.count: 2, CatalogKeys.price: 120},
    'supers': {CatalogKeys.type: 'limited', CatalogKeys.minutes: 1440, CatalogKeys.count: 3, CatalogKeys.price: 80},
    'eid': {CatalogKeys.type: 'until', CatalogKeys.until: DateTime.utc(2026, 11, 15).millisecondsSinceEpoch, CatalogKeys.price: 90},
    'deal': {
      CatalogKeys.type: 'counter',
      CatalogKeys.count: 5,
      CatalogKeys.price: 40,
      CatalogKeys.limit: {CatalogKeys.count: 1, CatalogKeys.minutes: 1440},
    },
  },
  CatalogKeys.bundles: {
    'welcome': {
      CatalogKeys.price: 300,
      CatalogKeys.items: ['a1', 'a2'],
      CatalogKeys.passes: ['filters', 'likes'],
      CatalogKeys.limit: {CatalogKeys.count: 1},
    },
    'royal': {
      CatalogKeys.price: 400,
      CatalogKeys.passes: ['vip'],
    },
  },
};
