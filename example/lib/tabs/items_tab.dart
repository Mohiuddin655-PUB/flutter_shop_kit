import 'package:flutter/material.dart';
import 'package:flutter_shop_kit/flutter_shop_kit.dart';

import '../shop_page.dart';

/// The items, as cards: a sale shows its price with the full one struck through; one owned shows a check.
class ItemsTab extends StatelessWidget {
  const ItemsTab({super.key});

  static const _items = {'hat': ('Top hat', '🎩'), 'cape': ('Royal cape', '🦸'), 'crown': ('Crown', '👑'), 'shades': ('Shades', '🕶️')};

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ShopKit.inventory, ShopKit.catalog]),
      builder: (context, _) {
        final now = DateTime.now().toUtc();
        return GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
          children: [
            for (final MapEntry(key: id, value: (name, emoji)) in _items.entries)
              if (ShopKit.catalog.offer(id) case final offer?) _ItemCard(id: id, name: name, emoji: emoji, offer: offer, now: now),
          ],
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.id, required this.name, required this.emoji, required this.offer, required this.now});

  final String id, name, emoji;
  final Offer offer;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme, owned = ShopKit.inventory.owns(id), onSale = offer.onSale(now);
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (onSale) Chip(label: Text('-${((offer.price - offer.priceAt(now)) * 100 / offer.price).round()}%'), visualDensity: VisualDensity.compact),
                const Spacer(),
                if (owned) Icon(Icons.check_circle_rounded, color: scheme.primary),
              ],
            ),
            Expanded(
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 56))),
            ),
            Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            owned
                ? const Text('Owned')
                : FilledButton(
                    onPressed: () => tell(context, ShopKit.inventory.buy(id, offer.priceAt(now))),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${offer.priceAt(now)}'),
                          if (onSale)
                            TextSpan(
                              text: '  ${offer.price}',
                              style: const TextStyle(decoration: TextDecoration.lineThrough),
                            ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
