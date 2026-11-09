import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_shop_kit/flutter_shop_kit.dart';

import 'fakes/test_shop_kit.dart';

void main() {
  test('buys an item: the price is taken and it is owned', () async {
    await TestShopKit.make();
    expect(await ShopKit.inventory.buy('a1', 100), SpendResult.done);
    await TestShopKit.settle();
    expect(ShopKit.wallet.amount, 900);
    expect(ShopKit.inventory.owns('a1'), isTrue);
  });

  test('takes nothing for an item owned already', () async {
    await TestShopKit.make(
      more: {
        WalletKeys.items: ['a1'],
      },
    );
    expect(await ShopKit.inventory.buy('a1', 100), SpendResult.done);
    expect(ShopKit.wallet.amount, 1000);
  });

  test("refuses what the balance doesn't cover", () async {
    await TestShopKit.make(points: 50);
    expect(await ShopKit.inventory.buy('a1', 100), SpendResult.notEnough);
    expect(ShopKit.inventory.owns('a1'), isFalse);
  });

  test('in debt, nothing can be spent and the debt is told', () async {
    await TestShopKit.make(points: -150);
    expect(ShopKit.wallet.debt, 150);
    expect(await ShopKit.inventory.buy('a1', 100), SpendResult.inDebt);
    expect(ShopKit.inventory.owns('a1'), isFalse);
  });

  test('no debt with a balance at or above zero', () async {
    await TestShopKit.make(points: 0);
    expect(ShopKit.wallet.debt, 0);
  });

  test('tells each part only of its own change', () async {
    final t = await TestShopKit.make();
    var balance = 0, inventory = 0, passes = 0;
    ShopKit.wallet.addListener(() => balance++);
    ShopKit.inventory.addListener(() => inventory++);
    ShopKit.passes.addListener(() => passes++);
    t.delegate.serverSets({
      WalletKeys.points: {WalletKeys.amount: 1500},
    });
    await TestShopKit.settle();
    expect((balance, inventory, passes), (1, 0, 0));
  });

  test('hears a pack bought after the last one', () async {
    final t = await TestShopKit.make();
    final arrived = ShopKit.wallet.purchaseAfter(null, const Duration(seconds: 1));
    t.delegate.serverSets({
      WalletKeys.points: {WalletKeys.amount: 2000, WalletKeys.lastPurchaseAt: t.clock.now, WalletKeys.lastPurchaseAmount: 1000},
    });
    expect(await arrived, 1000);
  });

  test('a signed-out kit holds nothing', () async {
    await TestShopKit.make();
    await ShopKit.clear();
    expect(ShopKit.wallet.amount, 0);
    expect(await ShopKit.inventory.buy('a1', 100), SpendResult.failed);
  });
}
