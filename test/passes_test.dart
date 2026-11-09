import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_shop_kit/flutter_shop_kit.dart';

import 'fakes/test_shop_kit.dart';

void main() {
  Future<(TestShopKit, SpendResult)> buy(String id, {Map<String, dynamic> more = const {}}) async {
    final t = await TestShopKit.make(more: more);
    final result = await ShopKit.passes.buy(id, ShopKit.catalog.pass(id)!);
    await TestShopKit.settle();
    return (t, result);
  }

  test('a duration pass runs its minutes, then is off', () async {
    final (t, result) = await buy('filters');
    expect(result, SpendResult.done);
    expect(ShopKit.wallet.amount, 900);
    expect(ShopKit.passes.on('filters'), isTrue);
    t.clock.pass(const Duration(minutes: 61));
    expect(ShopKit.passes.on('filters'), isFalse);
  });

  test('a running duration pass is not sold again', () async {
    await buy('filters');
    expect(await ShopKit.passes.buy('filters', ShopKit.catalog.pass('filters')!), SpendResult.done);
    expect(ShopKit.wallet.amount, 900);
  });

  test('a stacking pass adds its minutes while it runs', () async {
    await buy('boost');
    await ShopKit.passes.buy('boost', ShopKit.catalog.pass('boost')!);
    await TestShopKit.settle();
    expect(ShopKit.passes.state('boost').minutes, 60);
    expect(ShopKit.wallet.amount, 900);
  });

  test('a counter gives its uses, each use takes one, up to its max', () async {
    await buy('likes');
    expect(ShopKit.passes.left('likes'), 20);
    expect(await ShopKit.passes.use('likes'), isTrue);
    await TestShopKit.settle();
    expect(ShopKit.passes.left('likes'), 19);
    expect(await ShopKit.passes.buy('likes', ShopKit.catalog.pass('likes')!), SpendResult.overLimit);
  });

  test('a lifetime pass is on for good, bought once', () async {
    final (t, _) = await buy('vip');
    t.clock.pass(const Duration(days: 999));
    expect(ShopKit.passes.on('vip'), isTrue);
    expect(await ShopKit.passes.buy('vip', ShopKit.catalog.pass('vip')!), SpendResult.done);
    expect(ShopKit.wallet.amount, 500);
  });

  test('a daily pass gives its count each 24 hours, for its days', () async {
    final (t, _) = await buy('daily');
    expect(await ShopKit.passes.use('daily'), isTrue);
    expect(await ShopKit.passes.use('daily'), isTrue);
    await TestShopKit.settle();
    expect(ShopKit.passes.left('daily'), 0);
    expect(await ShopKit.passes.use('daily'), isFalse);
    t.clock.pass(const Duration(hours: 25));
    expect(ShopKit.passes.left('daily'), 2);
    t.clock.pass(const Duration(days: 3));
    expect(ShopKit.passes.on('daily'), isFalse);
  });

  test('a limited pass is off once its uses or its minutes are over', () async {
    await buy('supers');
    for (var i = 0; i < 3; i++) {
      await ShopKit.passes.use('supers');
    }
    await TestShopKit.settle();
    expect(ShopKit.passes.on('supers'), isFalse);
    final (u, _) = await buy('supers');
    u.clock.pass(const Duration(hours: 25));
    expect(ShopKit.passes.on('supers'), isFalse);
  });

  test('an until pass runs to its date and is not sold after it', () async {
    final (t, _) = await buy('eid');
    expect(ShopKit.passes.on('eid'), isTrue);
    t.clock.now = DateTime.utc(2026, 11, 16);
    expect(ShopKit.passes.on('eid'), isFalse);
    expect(await ShopKit.passes.buy('eid', ShopKit.catalog.pass('eid')!), SpendResult.failed);
  });

  test('a buying limit counts buys and resets after its minutes', () async {
    final (t, _) = await buy('deal');
    expect(await ShopKit.passes.buy('deal', ShopKit.catalog.pass('deal')!), SpendResult.overLimit);
    t.clock.pass(const Duration(hours: 25));
    expect(await ShopKit.passes.buy('deal', ShopKit.catalog.pass('deal')!), SpendResult.done);
    await TestShopKit.settle();
    expect(t.local[WalletKeys.passBuys]['deal'][WalletKeys.count], 1);
  });

  test('each write names its pass for the rules', () async {
    final (t, _) = await buy('likes');
    expect(t.local[LastWriteKeys.field], {LastWriteKeys.kind: LastWriteKeys.passBought, LastWriteKeys.id: 'likes', LastWriteKeys.entry: 'e1'});
    await ShopKit.passes.use('likes');
    await TestShopKit.settle();
    expect(t.local[LastWriteKeys.field][LastWriteKeys.kind], LastWriteKeys.passUsed);
  });
}
