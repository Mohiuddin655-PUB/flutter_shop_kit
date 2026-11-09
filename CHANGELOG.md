## 0.1.0

- First release: `ShopKit` with its `wallet` (balance), `inventory` (owned items), `passes` (duration, counter,
  lifetime, daily, limited, until), `bundles` (items and up to 3 passes at once) and `catalog` (prices, sales, buying
  limits), offline too.
- Delegates for the app: `ShopBackend`, `Clock`, `CatalogSource`, `ErrorReporter`.
- Firestore security rules template in `rules/firestore.rules`.
