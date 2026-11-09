import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_shop_kit/flutter_shop_kit.dart';

import 'fakes/test_shop_kit.dart';

void main() {
  test('offline, a buy shows at once and goes through once back online', () async {
    final t = await TestShopKit.make();
    t.delegate.online = false;
    expect(await ShopKit.inventory.buy('a1', 100), SpendResult.pending);
    await TestShopKit.settle();
    expect(ShopKit.wallet.amount, 900);
    expect(ShopKit.inventory.owns('a1'), isTrue);
    t.delegate.goOnline();
    await TestShopKit.settle();
    expect(t.delegate.server![WalletKeys.items], ['a1']);
  });

  test('offline, a pass bought shows on at once', () async {
    final t = await TestShopKit.make();
    t.delegate.online = false;
    expect(await ShopKit.passes.buy('filters', ShopKit.catalog.pass('filters')!), SpendResult.pending);
    await TestShopKit.settle();
    expect(ShopKit.passes.on('filters'), isTrue);
  });

  test('offline buys follow one another: the second sees the first', () async {
    final t = await TestShopKit.make(points: 150);
    t.delegate.online = false;
    expect(await ShopKit.inventory.buy('a1', 100), SpendResult.pending);
    await TestShopKit.settle();
    expect(await ShopKit.inventory.buy('a2', 100), SpendResult.notEnough);
  });

  test('a buy the server refuses later is undone and counted', () async {
    final t = await TestShopKit.make();
    t.delegate.online = false;
    t.delegate.refuse = (_) => true;
    await ShopKit.inventory.buy('a1', 100);
    await TestShopKit.settle();
    t.delegate.goOnline();
    await TestShopKit.settle();
    await TestShopKit.settle();
    expect(ShopKit.wallet.amount, 1000);
    expect(ShopKit.inventory.owns('a1'), isFalse);
    final refusal = ShopKit.wallet.refusals.single;
    expect((refusal.reason, refusal.ref, refusal.price), (LastWriteKeys.itemBought, 'a1', 100));
    ShopKit.wallet.seen(refusal);
    expect(ShopKit.wallet.refusals, isEmpty);
  });

  test('online, a refused buy fails and changes nothing', () async {
    final t = await TestShopKit.make();
    t.delegate.refuse = (_) => true;
    expect(await ShopKit.inventory.buy('a1', 100), SpendResult.failed);
    await TestShopKit.settle();
    expect(ShopKit.wallet.amount, 1000);
  });

  test('online, a server answering late leaves the buy pending', () async {
    final t = await TestShopKit.make();
    t.delegate.holding = true;
    expect(await ShopKit.inventory.buy('a1', 100), SpendResult.pending);
    t.delegate.goOnline();
    await TestShopKit.settle();
    expect(t.delegate.server![WalletKeys.items], ['a1']);
  });

  test('each refusal is kept once, for its own spend, and goes at sign-out', () async {
    final t = await TestShopKit.make();
    t.delegate.online = false;
    t.delegate.refuse = (_) => true;
    await ShopKit.inventory.buy('a1', 100);
    await ShopKit.passes.buy('filters', ShopKit.catalog.pass('filters')!);
    t.delegate.goOnline();
    await TestShopKit.settle();
    await TestShopKit.settle();
    expect([for (final r in ShopKit.wallet.refusals) r.ref], ['a1', 'filters']);
    await ShopKit.clear();
    expect(ShopKit.wallet.refusals, isEmpty);
  });

  test('a spend refused after the app was closed is told at the next start', () async {
    final t = await TestShopKit.make();
    t.delegate.online = false;
    await ShopKit.inventory.buy('a1', 100);
    await t.reopen();
    t.delegate.refuse = (_) => true;
    t.delegate.goOnline();
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect([for (final r in ShopKit.wallet.refusals) (r.ref, r.price)], [('a1', 100)]);
    expect(t.delegate.phone['u1/pending'], isNull);
  });

  test('a spend taken after the app was closed is not told', () async {
    final t = await TestShopKit.make();
    t.delegate.online = false;
    await ShopKit.inventory.buy('a1', 100);
    await t.reopen();
    t.delegate.goOnline();
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(ShopKit.wallet.refusals, isEmpty);
    expect(ShopKit.inventory.owns('a1'), isTrue);
    expect(t.delegate.phone['u1/pending'], isNull);
  });

  test('a spend answered while the app is open leaves nothing on the phone', () async {
    final t = await TestShopKit.make();
    await ShopKit.inventory.buy('a1', 100);
    t.delegate.online = false;
    await ShopKit.inventory.buy('a2', 100);
    t.delegate.goOnline();
    await TestShopKit.settle();
    expect(t.delegate.phone['u1/pending'], isNull);
  });

  test('reopened offline, the wallet last heard shows before the backend answers', () async {
    final t = await TestShopKit.make(
      more: {
        WalletKeys.items: ['a1'],
        WalletKeys.passes: {
          'vip': {WalletKeys.owned: true},
        },
      },
    );
    t.delegate.silent = true;
    await t.reopen();
    await TestShopKit.settle();
    expect(ShopKit.wallet.amount, 1000);
    expect(ShopKit.inventory.owns('a1'), isTrue);
    expect(ShopKit.passes.on('vip'), isTrue);
  });

  test('the copy keeps dates as the backend gives them', () async {
    final t = await TestShopKit.make(
      more: {
        WalletKeys.passes: {
          'filters': {WalletKeys.from: DateTime.utc(2026, 11, 9, 11, 30), WalletKeys.minutes: 60},
        },
      },
    );
    t.delegate.silent = true;
    await t.reopen();
    await TestShopKit.settle();
    expect(ShopKit.passes.on('filters'), isTrue);
  });

  test('sign-out wipes the wallet copy and keeps the spends on their way', () async {
    final t = await TestShopKit.make();
    t.delegate.online = false;
    await ShopKit.inventory.buy('a1', 100);
    await TestShopKit.settle();
    expect(t.delegate.phone['u1/wallet'], isNotNull);
    await ShopKit.clear();
    expect(t.delegate.phone['u1/wallet'], isNull);
    expect(t.delegate.phone['u1/pending'], isNotNull);
  });
}
