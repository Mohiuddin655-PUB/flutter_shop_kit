import '../../keys/last_write_keys.dart';
import '../../keys/wallet_keys.dart';
import '../delegates/clock.dart';
import '../delegates/shop_backend.dart';
import '../enums/spend_result.dart';
import '../models/bundle_terms.dart';
import '../utils/buy_counter.dart';
import 'wallet.dart';
import 'catalog.dart';
import 'inventory.dart';
import 'passes.dart';
import 'wallet_doc.dart';

/// Buying a bundle: its items ([Inventory]) and its passes ([Passes], each on the catalog's terms) in one
/// spend, offline too. Holds nothing itself: what a bundle gives is owned and held as if bought alone.
class Bundles {
  const Bundles(this._doc, this._balance, this._inventory, this._passes, this._catalog, this._backend, this._clock);

  final WalletDoc _doc;
  final Wallet _balance;
  final Inventory _inventory;
  final Passes _passes;
  final Catalog _catalog;
  final ShopBackend _backend;
  final Clock _clock;

  /// Bundle [id] on [terms] (as the screen showed them). Nothing is taken when it has no passes and every item is
  /// owned. A pass the catalog doesn't sell is [SpendResult.failed]; one the rules refuse is its
  /// [Passes.refusal]; one already held, or the bundle's buying limit reached, is [SpendResult.overLimit].
  Future<SpendResult> buy(String id, BundleTerms terms) async {
    if (terms.passes.isEmpty && terms.items.every(_inventory.owns)) return SpendResult.done;
    final grant = <String, Object?>{};
    for (final passId in terms.passes) {
      final pass = _catalog.pass(passId);
      if (pass == null) return SpendResult.failed;
      final refused = _passes.refusal(passId, pass);
      if (refused != null) return refused;
      final given = _passes.grant(passId, pass);
      if (given == null) return SpendResult.overLimit;
      grant.addAll(given);
    }
    final counted = countBuy(_backend, _doc.data, WalletKeys.bundleBuys, id, terms.limit, _clock.now);
    if (counted == null) return SpendResult.overLimit;
    return _balance.spend(terms.price, {
      if (terms.items.isNotEmpty) WalletKeys.items: _backend.arrayUnion(terms.items),
      ...grant,
      ...counted,
      ...LastWriteKeys.of(LastWriteKeys.bundleBought, id),
    });
  }
}
