import 'package:flutter/foundation.dart' show visibleForTesting;

import 'delegates/catalog_delegate.dart';
import 'delegates/error_reporter.dart';
import 'delegates/wallet_delegate.dart';
import 'parts/bundles.dart';
import 'parts/catalog.dart';
import 'parts/inventory.dart';
import 'parts/ledger.dart';
import 'parts/passes.dart';
import 'parts/wallet.dart';
import 'parts/wallet_doc.dart';
import 'parts/wallet_writer.dart';

/// What the signed-in account holds and buys: its [wallet] (the balance), the items it owns ([inventory]), its
/// [passes], buying [bundles], what the admin's [catalog] sells, and the [ledger] of every balance movement. One wallet
/// document heard once; each part tells its listeners only when its own part changes. Set up once as the app starts
/// ([setup]), then [start] at sign-in and [clear] at sign-out.
abstract final class ShopKit {
  static _Parts? _parts;

  static DateTime _phoneNow() => DateTime.now().toUtc();

  static _Parts get _p => _parts ?? (throw StateError('ShopKit.setup must be called first.'));

  /// Sets the kit up with what the app gives it, once, as the app starts (after Flutter's binding is ready). [now]
  /// gives the server's time, as the security rules go by it (the phone's clock, which its owner can move, when none
  /// is given). Before the catalog has a copy, [fallbackPasses] (the catalog's `passes`, as the admin writes them) are
  /// sold.
  static void setup({
    required WalletDelegate walletDelegate,
    DateTime Function()? now,
    required CatalogDelegate catalogDelegate,
    ErrorReporter? onError,
    Map<String, Object?> fallbackPasses = const {},
    Duration writeWait = const Duration(seconds: 10),
  }) {
    if (_parts != null) throw StateError('ShopKit.setup was called already.');
    _parts = _Parts(walletDelegate, now ?? _phoneNow, catalogDelegate, onError, fallbackPasses, writeWait);
  }

  static Wallet get wallet => _p.wallet;
  static Inventory get inventory => _p.inventory;
  static Passes get passes => _p.passes;
  static Bundles get bundles => _p.bundles;
  static Catalog get catalog => _p.catalog;
  static Ledger get ledger => _p.ledger;

  /// The signed-in account; empty when none.
  static String get uid => _p.doc.uid;

  /// [uid] is signed in (a login, or a launch still signed in).
  static void start(String uid) => _p.doc.start(uid);

  /// Signed out: nothing of the account stays.
  static Future<void> clear() {
    _p.wallet.forgetRefusals();
    return _p.doc.clear();
  }

  /// Undoes [setup], so a test can set it up anew.
  @visibleForTesting
  static void reset() {
    _parts?.dispose();
    _parts = null;
  }
}

class _Parts {
  _Parts(WalletDelegate delegate, DateTime Function() now, CatalogDelegate source, ErrorReporter? onError, Map<String, Object?> fallback, Duration wait)
    : doc = WalletDoc(delegate, onError) {
    final writer = WalletWriter(delegate, onError, wait: wait);
    wallet = Wallet(doc, writer, delegate);
    inventory = Inventory(doc, wallet, delegate);
    passes = Passes(doc, wallet, writer, delegate, now);
    catalog = Catalog(source, now, fallbackPasses: fallback);
    bundles = Bundles(doc, wallet, inventory, passes, catalog, delegate, now);
    ledger = Ledger(doc, delegate);
  }

  final WalletDoc doc;
  late final Wallet wallet;
  late final Inventory inventory;
  late final Passes passes;
  late final Bundles bundles;
  late final Catalog catalog;
  late final Ledger ledger;

  void dispose() {
    wallet.dispose();
    inventory.dispose();
    passes.dispose();
    catalog.dispose();
    doc.dispose();
  }
}
