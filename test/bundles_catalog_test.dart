import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_shop_kit/flutter_shop_kit.dart';

import 'fakes/test_shop_kit.dart';

void main() {
  test('a bundle gives its items and passes in one spend', () async {
    await TestShopKit.make();
    expect(await ShopKit.bundles.buy('welcome', ShopKit.catalog.bundle('welcome')!), SpendResult.done);
    await TestShopKit.settle();
    expect(ShopKit.wallet.amount, 700);
    expect(ShopKit.inventory.owns('a1') && ShopKit.inventory.owns('a2'), isTrue);
    expect(ShopKit.passes.on('filters'), isTrue);
    expect(ShopKit.passes.left('likes'), 20);
  });

  test('a bundle past its limit is not sold again', () async {
    final t = await TestShopKit.make();
    await ShopKit.bundles.buy('welcome', ShopKit.catalog.bundle('welcome')!);
    await TestShopKit.settle();
    t.clock.pass(const Duration(hours: 2));
    expect(await ShopKit.bundles.buy('welcome', ShopKit.catalog.bundle('welcome')!), SpendResult.overLimit);
  });

  test('a bundle whose pass is held for good is not sold', () async {
    await TestShopKit.make(
      more: {
        WalletKeys.passes: {
          'vip': {WalletKeys.owned: true},
        },
      },
    );
    expect(await ShopKit.bundles.buy('royal', ShopKit.catalog.bundle('royal')!), SpendResult.overLimit);
    expect(ShopKit.wallet.amount, 1000);
  });

  test('a sale charges its price while it runs', () async {
    final t = await TestShopKit.make();
    expect(ShopKit.catalog.offer('a2')!.priceAt(t.clock.now), 150);
    t.clock.now = DateTime.utc(2026, 11, 11);
    expect(ShopKit.catalog.offer('a2')!.priceAt(t.clock.now), 200);
  });

  test("an item the catalog doesn't list isn't sold", () async {
    await TestShopKit.make();
    expect(ShopKit.catalog.sells('a1'), isTrue);
    expect(ShopKit.catalog.sells('zz'), isFalse);
  });

  test('before any copy, the fallback passes are sold', () async {
    final t = await TestShopKit.make();
    ShopKit.reset();
    ShopKit.setup(
      walletDelegate: t.delegate,
      now: () => t.clock.now,
      catalogDelegate: _Empty(),
      fallbackPasses: const {
        'filters': {CatalogKeys.type: 'duration', CatalogKeys.minutes: 60, CatalogKeys.price: 100},
      },
    );
    expect(ShopKit.catalog.pass('filters')?.minutes, 60);
  });
}

class _Empty implements CatalogDelegate {
  @override
  Map<String, Object?>? cached() => null;
  @override
  Future<Map<String, Object?>?> fetch(int version) async => null;
  @override
  int? get version => null;
  @override
  final versionChanges = _Never();
}

class _Never extends ChangeNotifier {}
