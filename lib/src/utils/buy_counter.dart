import '../../keys/wallet_keys.dart';
import '../delegates/wallet_delegate.dart';
import '../models/buy_limit.dart';

/// The fields that count one more buy of [id] in [wallet]'s [buys] (`passBuys` or `bundleBuys`) under [limit]: a new
/// count from the server's time once its minutes are over, else one more. Empty without a limit; null when the limit
/// is reached, by the server's clock at [now].
Map<String, Object?>? countBuy(WalletDelegate delegate, Map<String, dynamic>? wallet, String buys, String id, BuyLimit? limit, DateTime now) {
  if (limit == null) return const {};
  final kept = wallet?[buys], entry = kept is Map ? kept[id] : null;
  final from = entry is Map ? delegate.timeOf(entry[WalletKeys.from]) : null, count = entry is Map ? entry[WalletKeys.count] : null;
  // A buy still on its way has no server time yet: it counts from now.
  final start = from ?? (entry is Map ? now : null);
  final fresh = start == null || (limit.minutes > 0 && !start.add(Duration(minutes: limit.minutes)).isAfter(now));
  if (fresh) {
    return {
      '$buys.$id': {WalletKeys.count: 1, WalletKeys.from: delegate.serverTime},
    };
  }
  final done = count is num ? count.toInt() : 0;
  return done >= limit.count ? null : {'$buys.$id.${WalletKeys.count}': delegate.increment(1)};
}
