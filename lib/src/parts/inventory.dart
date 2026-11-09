import 'package:flutter/foundation.dart';

import '../../keys/last_write_keys.dart';
import '../../keys/wallet_keys.dart';
import '../delegates/wallet_delegate.dart';
import '../enums/spend_result.dart';
import 'wallet.dart';
import 'wallet_doc.dart';

/// The items the account bought, kept for good (`items`), and buying one. Told only when what is owned changes.
class Inventory extends ChangeNotifier {
  Inventory(this._doc, this._balance, this._delegate) {
    _doc.addListener(_docChanged);
  }

  final WalletDoc _doc;
  final Wallet _balance;
  final WalletDelegate _delegate;

  List<String> _items = const [];

  /// The items owned.
  List<String> get items => _items;

  /// [id] was bought.
  bool owns(String id) => _items.contains(id);

  /// Item [id] for [price], offline too; nothing is taken when it is owned already.
  Future<SpendResult> buy(String id, int price) async {
    if (owns(id)) return SpendResult.done;
    return _balance.spend(
      price,
      {
        WalletKeys.items: _delegate.arrayUnion([id]),
      },
      reason: LastWriteKeys.itemBought,
      ref: id,
    );
  }

  void _docChanged() {
    final items = _doc.data?[WalletKeys.items];
    final owned = items is List ? items.whereType<String>().toList() : const <String>[];
    if (listEquals(owned, _items)) return;
    _items = owned;
    notifyListeners();
  }

  @override
  void dispose() {
    _doc.removeListener(_docChanged);
    super.dispose();
  }
}
