// flutter_shop_kit's server side, for Cloud Functions (or any Node server) with the Firebase Admin SDK: the only place
// currency is added or taken back. Call grantPack from your store webhook (RevenueCat, App Store Server Notifications,
// Google Play RTDN) when a pack is bought, and refundPack when it is refunded. Each runs in one transaction and counts a
// store transaction once, however often the webhook is retried. Paths match rules/firestore.rules; change them with it.
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

const wallet = (uid: string) => getFirestore().doc(`accounts/${uid}/wallet/main`);
const purchase = (uid: string, transaction: string) => getFirestore().doc(`accounts/${uid}/purchases/points_${transaction}`);
const entry = (uid: string, id: string) => getFirestore().doc(`accounts/${uid}/wallet/main/ledger/${id}`);

/** A ledger entry written by the server: [amount] in (positive) or out (negative), for [reason] of [ref]. */
const serverEntry = (kind: 'credit' | 'debit', reason: 'packBought' | 'refund', ref: string, amount: number) => ({
  kind,
  reason,
  ref,
  amount,
  at: FieldValue.serverTimestamp(),
  source: 'server',
});

/**
 * Gives [points] for store [transaction] to [uid]: the balance up, the last purchase (for the app's "you've got N"),
 * the purchase kept (so a retried webhook gives nothing twice) and its credit in the ledger. 'seen' when already given.
 */
export async function grantPack(uid: string, transaction: string, points: number, product: string): Promise<'given' | 'seen'> {
  return getFirestore().runTransaction(async (tx) => {
    const bought = await tx.get(purchase(uid, transaction));
    if (bought.exists) return 'seen';
    tx.create(purchase(uid, transaction), { product, points, at: FieldValue.serverTimestamp() });
    tx.set(
      wallet(uid),
      { points: { amount: FieldValue.increment(points), last_purchase_at: FieldValue.serverTimestamp(), last_purchase_amount: points } },
      { merge: true },
    );
    tx.set(entry(uid, `points_${transaction}`), serverEntry('credit', 'packBought', transaction, points));
    return 'given';
  });
}

/**
 * Takes back what store [transaction] gave [uid], all of it: when some was spent, the balance goes below zero (a debt
 * the app shows and that blocks spending until bought currency pays it back), so a refund never leaves what it bought
 * free. Records its debit and `lastRefund` (the app tells it once, when it leaves a debt). 'seen' when already taken
 * back, 'unknown' when the transaction gave nothing here.
 */
export async function refundPack(uid: string, transaction: string): Promise<'taken' | 'seen' | 'unknown'> {
  return getFirestore().runTransaction(async (tx) => {
    const bought = await tx.get(purchase(uid, transaction));
    if (!bought.exists) return 'unknown';
    if (bought.get('refundedAt')) return 'seen';
    const points = Number(bought.get('points') ?? 0);
    tx.update(purchase(uid, transaction), { refundedAt: FieldValue.serverTimestamp(), takenBack: points });
    tx.set(
      wallet(uid),
      {
        points: { amount: FieldValue.increment(-points) },
        lastRefund: { ref: transaction, amount: points, at: FieldValue.serverTimestamp() },
      },
      { merge: true },
    );
    tx.set(entry(uid, `refund_${transaction}`), serverEntry('debit', 'refund', transaction, -points));
    return 'taken';
  });
}
