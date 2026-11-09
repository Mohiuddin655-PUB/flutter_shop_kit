## 0.2.0

- **Breaking**: the delegates are named for what they hand over: `ShopBackend` is `WalletDelegate` and `CatalogSource`
  is `CatalogDelegate`; `ShopKit.setup` takes `walletDelegate:` and `catalogDelegate:`.
- The package's repository link points at `flutter_shop_kit`.

## 0.1.0

- First release: `ShopKit` with its `wallet` (balance), `inventory` (owned items), `passes` (duration, counter,
  lifetime, daily, limited, until), `bundles` (items and up to 3 passes at once) and `catalog` (prices, sales, buying
  limits), offline too.
- Delegates for the app: `WalletDelegate`, `Clock`, `CatalogDelegate`, `ErrorReporter`.
- Firestore security rules template in `rules/firestore.rules`.
