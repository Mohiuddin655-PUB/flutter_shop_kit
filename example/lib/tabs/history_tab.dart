import 'package:flutter/material.dart';
import 'package:flutter_shop_kit/flutter_shop_kit.dart';

/// The ledger, newest first: each balance movement with its amount (green in, red out).
class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // A new entry comes with every balance change.
      listenable: ShopKit.wallet,
      builder: (context, _) => FutureBuilder<List<LedgerEntry>>(
        future: ShopKit.ledger.page(),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? const <LedgerEntry>[];
          if (entries.isEmpty) return const Center(child: Text('Nothing bought yet'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = entries[i], color = e.amount < 0 ? Colors.red.shade700 : Colors.green.shade700;
              return ListTile(
                title: Text('${e.reason} · ${e.ref}'),
                subtitle: Text(e.at == null ? 'On its way' : TimeOfDay.fromDateTime(e.at!.toLocal()).format(context)),
                trailing: Text(
                  '${e.amount > 0 ? '+' : ''}${e.amount}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
