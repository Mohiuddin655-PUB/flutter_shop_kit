import 'package:flutter/material.dart';
import 'package:flutter_shop_kit/flutter_shop_kit.dart';

import '../shop_page.dart';

/// The bundle: a hat, a boost and 5 hints at once, sold once.
class BundlesTab extends StatelessWidget {
  const BundlesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final terms = ShopKit.catalog.bundle('starter'), scheme = Theme.of(context).colorScheme;
    if (terms == null) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: scheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🎩 ⚡ 💡', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text('Starter bundle', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('A top hat, a boost and 5 hints. Once per account.'),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => tell(context, ShopKit.bundles.buy('starter', terms)), child: Text('Buy for ${terms.price}')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
