## 0.4.0

- **Refund debt**: `ShopKit.wallet.debt` is what is owed when the balance is below zero (a server taking back a refund
  in full), and a spend then is `SpendResult.inDebt`, before `notEnough`.
- **Breaking**: `SpendResult` has a new value, `inDebt`, so a `switch` over it needs a case for it.

## 0.3.0

- **Ledger**: every spend is recorded as a debit in the wallet's `ledger`, written in the same batch as the spend
  (offline too), with an id made by the app so a write sent twice records once. `ShopKit.ledger.page()` reads it,
  newest first, a page at a time; a server records credits (a pack bought) and refunds the same way.
- **Breaking**: `WalletDelegate.update` takes the ledger entry (`entry:`), and the delegate gives `newEntryId` and
  `ledger` (a page of entries). `Wallet.spend` takes the `reason` and `ref` it records. Item buys now name themselves in
  `lastWrite` (`itemBought`), with the spend's ledger `entry`.
- The rules template checks each spend's ledger entry.

## 0.2.0

- **Breaking**: the delegates are named for what they hand over: `ShopBackend` is `WalletDelegate` and `CatalogSource`
  is `CatalogDelegate`; `ShopKit.setup` takes `walletDelegate:` and `catalogDelegate:`.
- **Breaking**: `Clock` is gone: `ShopKit.setup` takes an optional `now` function for the server's time (the phone's
  clock, UTC, when none is given).
- The package's repository link points at `flutter_shop_kit`.

## 0.1.0

- First release: `ShopKit` with its `wallet` (balance), `inventory` (owned items), `passes` (duration, counter,
  lifetime, daily, limited, until), `bundles` (items and up to 3 passes at once) and `catalog` (prices, sales, buying
  limits), offline too.
- Delegates for the app: `WalletDelegate`, `Clock`, `CatalogDelegate`, `ErrorReporter`.
- Firestore security rules template in `rules/firestore.rules`.
