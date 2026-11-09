import 'package:flutter/material.dart';
import 'package:flutter_shop_kit/flutter_shop_kit.dart';

import 'memory_wallet_delegate.dart';
import 'tabs/bundles_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/items_tab.dart';
import 'tabs/passes_tab.dart';

/// The shop: the balance and an offline switch on top, then items, passes, bundles and the history in tabs. Each part
/// rebuilds only when its own part of the kit changes.
class ShopPage extends StatefulWidget {
  const ShopPage({super.key, required this.wallet});

  final MemoryWalletDelegate wallet;

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Shop', style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            ListenableBuilder(
              listenable: ShopKit.wallet,
              builder: (_, _) => Chip(
                avatar: Icon(Icons.toll_rounded, color: scheme.primary),
                label: Text('${ShopKit.wallet.amount}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message: widget.wallet.online ? 'Online' : 'Offline',
              child: Switch(value: widget.wallet.online, onChanged: (on) => setState(() => widget.wallet.online = on)),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Items'),
              Tab(text: 'Passes'),
              Tab(text: 'Bundles'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (!widget.wallet.online)
              MaterialBanner(
                leading: const Icon(Icons.cloud_off_rounded),
                content: const Text('Offline: buys show at once and go through when you are back.'),
                actions: [TextButton(onPressed: () => setState(() => widget.wallet.online = true), child: const Text('Go online'))],
              ),
            const Expanded(child: TabBarView(children: [ItemsTab(), PassesTab(), BundlesTab(), HistoryTab()])),
          ],
        ),
      ),
    );
  }
}

/// Says how a buy went, in a snack bar.
Future<void> tell(BuildContext context, Future<SpendResult> buy) async {
  final result = await buy;
  if (!context.mounted) return;
  final text = switch (result) {
    SpendResult.done => 'Bought',
    SpendResult.pending => 'Bought: it goes through once you are back online',
    SpendResult.notEnough => 'Not enough coins',
    SpendResult.inDebt => 'Buy coins to pay back what you owe first',
    SpendResult.overLimit => 'You have it already, or its limit is reached',
    SpendResult.offline || SpendResult.failed => "Couldn't buy it",
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
}
