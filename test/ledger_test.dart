import 'package:flutter_shop_kit/flutter_shop_kit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/test_shop_kit.dart';

void main() {
  test('a spend writes its debit with the wallet change, in one batch', () async {
    final t = await TestShopKit.make();
    await ShopKit.inventory.buy('a1', 100);
    await TestShopKit.settle();
    final entries = await ShopKit.ledger.page();
    expect(entries, hasLength(1));
    final e = entries.single;
    expect((e.debit, e.reason, e.ref, e.amount, e.source), (true, LedgerKeys.itemBought, 'a1', -100, LedgerKeys.app));
    expect(e.at, t.clock.now);
    expect(t.local[LastWriteKeys.field][LastWriteKeys.entry], e.id);
  });

  test('passes and bundles are recorded for their price', () async {
    await TestShopKit.make();
    await ShopKit.passes.buy('filters', ShopKit.catalog.pass('filters')!);
    await ShopKit.bundles.buy('royal', ShopKit.catalog.bundle('royal')!);
    await TestShopKit.settle();
    final entries = await ShopKit.ledger.page();
    expect({for (final e in entries) (e.reason, e.ref, e.amount)}, {(LedgerKeys.bundleBought, 'royal', -400), (LedgerKeys.passBought, 'filters', -100)});
  });

  test('a use and a free buy write nothing', () async {
    final t = await TestShopKit.make(
      more: {
        WalletKeys.items: ['a1'],
        WalletKeys.passes: {
          'likes': {WalletKeys.left: 3},
        },
      },
    );
    await ShopKit.passes.use('likes');
    await ShopKit.inventory.buy('a1', 100);
    await TestShopKit.settle();
    expect(await ShopKit.ledger.page(), isEmpty);
    expect(t.delegate.ledgerOnServer, isEmpty);
  });

  test('offline, the entry shows at once and reaches the server once back online', () async {
    final t = await TestShopKit.make();
    t.delegate.online = false;
    await ShopKit.inventory.buy('a1', 100);
    final pending = await ShopKit.ledger.page();
    expect(pending.single.at, isNull);
    t.delegate.goOnline();
    await TestShopKit.settle();
    expect(t.delegate.ledgerOnServer, hasLength(1));
  });

  test('a refused spend leaves no entry', () async {
    final t = await TestShopKit.make();
    t.delegate.refuse = (_) => true;
    await ShopKit.inventory.buy('a1', 100);
    await TestShopKit.settle();
    expect(await ShopKit.ledger.page(), isEmpty);
  });

  test('pages follow on from the last entry, newest first', () async {
    final t = await TestShopKit.make();
    for (final id in ['a1', 'a2']) {
      await ShopKit.inventory.buy(id, 100);
      await TestShopKit.settle();
      t.clock.pass(const Duration(minutes: 1));
    }
    final first = await ShopKit.ledger.page(limit: 1);
    final second = await ShopKit.ledger.page(after: first.single, limit: 1);
    expect([first.single.ref, second.single.ref], ['a2', 'a1']);
  });

  test('with the ledger and history off, a spend writes no entry and the history reads nothing', () async {
    final t = await TestShopKit.make(ledger: false);
    expect(ShopKit.ledger.enabled, isFalse);
    expect(await ShopKit.inventory.buy('a1', 100), SpendResult.done);
    await TestShopKit.settle();
    expect(ShopKit.inventory.owns('a1'), isTrue);
    expect(t.delegate.ledgerOnServer, isEmpty);
    expect(t.local[LastWriteKeys.field], {LastWriteKeys.kind: LastWriteKeys.itemBought, LastWriteKeys.id: 'a1'});
    expect(await ShopKit.ledger.page(), isEmpty);
    expect(t.delegate.phone['u1/pending'], isNull);
  });

  test('with the ledger off, a refusal while open is still told', () async {
    final t = await TestShopKit.make(ledger: false);
    t.delegate.online = false;
    t.delegate.refuse = (_) => true;
    await ShopKit.inventory.buy('a1', 100);
    t.delegate.goOnline();
    await TestShopKit.settle();
    await TestShopKit.settle();
    expect(ShopKit.wallet.refusals.single.ref, 'a1');
  });
}
