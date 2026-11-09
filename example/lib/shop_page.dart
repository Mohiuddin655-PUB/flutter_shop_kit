import 'package:flutter/material.dart';
import 'package:flutter_shop_kit/flutter_shop_kit.dart';

import 'memory_backend.dart';

/// The shop: the balance, the items, the passes and a bundle, each rebuilt only when its own part changes, with a
/// switch to go offline and see buys wait for the link.
class ShopPage extends StatelessWidget {
  const ShopPage({super.key, required this.backend});

  final MemoryBackend backend;

  Future<void> _say(BuildContext context, Future<SpendResult> buy) async {
    final result = await buy;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_words(result))));
  }

  static String _words(SpendResult r) => switch (r) {
    SpendResult.done => 'Bought',
    SpendResult.pending => 'Bought: it goes through once back online',
    SpendResult.notEnough => 'Not enough coins',
    SpendResult.overLimit => 'You have it, or its limit is reached',
    SpendResult.offline => "Couldn't reach the server",
    SpendResult.failed => "Couldn't buy it",
  };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(listenable: ShopKit.wallet, builder: (_, _) => Text('${ShopKit.wallet.amount} coins')),
        actions: [
          StatefulBuilder(
            builder: (context, set) => Switch(value: backend.online, onChanged: (on) => set(() => backend.online = on)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Title('Items'),
          ListenableBuilder(
            listenable: Listenable.merge([ShopKit.inventory, ShopKit.catalog]),
            builder: (context, _) => Column(
              children: [
                for (final id in ['hat', 'cape'])
                  if (ShopKit.catalog.offer(id) case final offer?)
                    ListTile(
                      title: Text(id),
                      subtitle: Text(offer.onSale(now) ? 'Sale: ${offer.priceAt(now)} (was ${offer.price})' : '${offer.price}'),
                      trailing: ShopKit.inventory.owns(id)
                          ? const Icon(Icons.check)
                          : FilledButton(onPressed: () => _say(context, ShopKit.inventory.buy(id, offer.priceAt(now))), child: const Text('Buy')),
                    ),
              ],
            ),
          ),
          const _Title('Passes'),
          ListenableBuilder(
            listenable: ShopKit.passes,
            builder: (context, _) => Column(
              children: [
                for (final id in ShopKit.catalog.passIds)
                  if (ShopKit.catalog.pass(id) case final terms?)
                    ListTile(
                      title: Text('$id (${terms.type.name})'),
                      subtitle: Text(ShopKit.passes.on(id) ? 'On · ${ShopKit.passes.left(id)} uses left' : '${terms.price}'),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          if (ShopKit.passes.left(id) > 0) OutlinedButton(onPressed: () => ShopKit.passes.use(id), child: const Text('Use')),
                          FilledButton(onPressed: () => _say(context, ShopKit.passes.buy(id, terms)), child: const Text('Buy')),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          const _Title('Bundle'),
          if (ShopKit.catalog.bundle('starter') case final terms?)
            Card(
              child: ListTile(
                title: const Text('Starter: a hat, a boost and 5 hints'),
                subtitle: Text('${terms.price} · once'),
                trailing: FilledButton(onPressed: () => _say(context, ShopKit.bundles.buy('starter', terms)), child: const Text('Buy')),
              ),
            ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}
