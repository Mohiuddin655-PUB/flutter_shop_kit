import 'package:flutter/material.dart';
import 'package:flutter_shop_kit/flutter_shop_kit.dart';

import '../shop_page.dart';

/// The passes, each with its kind, whether it is on and its uses left, and Buy (and Use when it has uses).
class PassesTab extends StatelessWidget {
  const PassesTab({super.key});

  static const _looks = {
    'boost': ('Boost', '⚡', '30 minutes, stacks'),
    'hints': ('Hints', '💡', '5 uses, up to 20'),
    'gift': ('Daily gift', '🎁', '1 a day for 7 days'),
    'vip': ('VIP', '⭐', 'For good'),
  };

  /// On, with its uses left when it counts them (a counter, a daily or a limited pass); else what it gives.
  static String _status(String id, String what) {
    if (!ShopKit.passes.on(id)) return what;
    final state = ShopKit.passes.state(id);
    final left = ShopKit.passes.left(id);
    return state.counts || state.days > 0 ? 'On · $left ${left == 1 ? 'use' : 'uses'} left' : 'On';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ShopKit.passes, ShopKit.catalog]),
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final MapEntry(key: id, value: (name, emoji, what)) in _looks.entries)
            if (ShopKit.catalog.pass(id) case final terms?)
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                  leading: Text(emoji, style: const TextStyle(fontSize: 32)),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(_status(id, what)),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      if (ShopKit.passes.left(id) > 0) OutlinedButton(onPressed: () => ShopKit.passes.use(id), child: const Text('Use')),
                      FilledButton(onPressed: () => tell(context, ShopKit.passes.buy(id, terms)), child: Text('${terms.price}')),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
