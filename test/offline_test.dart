import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_shop_kit/flutter_shop_kit.dart';

import 'fakes/test_shop_kit.dart';

void main() {
  test('offline, a buy shows at once and goes through once back online', () async {
    final t = await TestShopKit.make();
    t.backend.online = false;
    expect(await ShopKit.inventory.buy('a1', 100), SpendResult.pending);
    await TestShopKit.settle();
    expect(ShopKit.wallet.amount, 900);
    expect(ShopKit.inventory.owns('a1'), isTrue);
    t.backend.goOnline();
    await TestShopKit.settle();
    expect(t.backend.server![WalletKeys.items], ['a1']);
  });

  test('offline, a pass bought shows on at once', () async {
    final t = await TestShopKit.make();
    t.backend.online = false;
    expect(await ShopKit.passes.buy('filters', ShopKit.catalog.pass('filters')!), SpendResult.pending);
    await TestShopKit.settle();
    expect(ShopKit.passes.on('filters'), isTrue);
  });

  test('offline buys follow one another: the second sees the first', () async {
    final t = await TestShopKit.make(points: 150);
    t.backend.online = false;
    expect(await ShopKit.inventory.buy('a1', 100), SpendResult.pending);
    await TestShopKit.settle();
    expect(await ShopKit.inventory.buy('a2', 100), SpendResult.notEnough);
  });

  test('a buy the server refuses later is undone and counted', () async {
    final t = await TestShopKit.make();
    t.backend.online = false;
    t.backend.refuse = (_) => true;
    await ShopKit.inventory.buy('a1', 100);
    await TestShopKit.settle();
    t.backend.goOnline();
    await TestShopKit.settle();
    await TestShopKit.settle();
    expect(ShopKit.wallet.amount, 1000);
    expect(ShopKit.inventory.owns('a1'), isFalse);
    expect(ShopKit.wallet.refusedSpends, 1);
  });

  test('online, a refused buy fails and changes nothing', () async {
    final t = await TestShopKit.make();
    t.backend.refuse = (_) => true;
    expect(await ShopKit.inventory.buy('a1', 100), SpendResult.failed);
    await TestShopKit.settle();
    expect(ShopKit.wallet.amount, 1000);
  });

  test('online, a server answering late leaves the buy pending', () async {
    final t = await TestShopKit.make();
    t.backend.holding = true;
    expect(await ShopKit.inventory.buy('a1', 100), SpendResult.pending);
    t.backend.goOnline();
    await TestShopKit.settle();
    expect(t.backend.server![WalletKeys.items], ['a1']);
  });
}
