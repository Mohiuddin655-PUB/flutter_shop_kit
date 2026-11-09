import 'package:flutter/material.dart';
import 'package:flutter_shop_kit/flutter_shop_kit.dart';

import 'memory_catalog_delegate.dart';
import 'memory_wallet_delegate.dart';
import 'shop_page.dart';

/// A shop on a wallet kept in memory, so it runs without a backend. A real app gives Firestore (or its own server)
/// through the same three delegates.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final wallet = MemoryWalletDelegate(
    start: {
      WalletKeys.points: {WalletKeys.amount: 1000},
    },
  );
  ShopKit.setup(walletDelegate: wallet, clock: const SystemClock(), catalogDelegate: MemoryCatalogDelegate());
  ShopKit.start('demo-user');
  runApp(
    MaterialApp(
      title: 'ShopKit example',
      home: ShopPage(wallet: wallet),
    ),
  );
}

/// The phone's clock; a real app gives the server's.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime get now => DateTime.now().toUtc();
}
