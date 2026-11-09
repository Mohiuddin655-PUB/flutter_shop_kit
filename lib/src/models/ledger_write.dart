/// A ledger entry to write with a wallet change, in one batch: its [id] (made by the app, so a write sent twice records
/// once) and its fields.
typedef LedgerWrite = ({String id, Map<String, Object?> data});
