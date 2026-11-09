import '../../keys/wallet_keys.dart';

/// One pass as the wallet keeps it (`passes.{id}`), read leniently whatever its type: when it started ([from], the
/// server's time; one just bought here counts from now), its [minutes], [days] and [count], its uses [left], the day's
/// [window] and its [used] uses, the date it runs [until], and whether it is [owned] for good.
class PassState {
  const PassState({
    this.from,
    this.minutes = 0,
    this.days = 0,
    this.count = 0,
    this.left = 0,
    this.window = 0,
    this.used = 0,
    this.until,
    this.owned = false,
    this.counts = false,
  });

  /// [source] as a pass; [timeOf] reads a stored date.
  factory PassState.from(Object? source, DateTime now, DateTime? Function(Object? value) timeOf) {
    final p = source is Map ? source : const {};
    int whole(Object? v) => v is num ? v.toInt() : 0;
    final from = timeOf(p[WalletKeys.from]);
    return PassState(
      from: from ?? (p.containsKey(WalletKeys.from) ? now : null),
      minutes: whole(p[WalletKeys.minutes]),
      days: whole(p[WalletKeys.days]),
      count: whole(p[WalletKeys.count]),
      left: whole(p[WalletKeys.left]),
      window: whole(p[WalletKeys.window]),
      used: whole(p[WalletKeys.used]),
      until: timeOf(p[WalletKeys.until]),
      owned: p[WalletKeys.owned] == true,
      counts: p.containsKey(WalletKeys.left),
    );
  }

  final DateTime? from;
  final int minutes, days, count, left, window, used;
  final DateTime? until;
  final bool owned;

  /// It counts its uses ([left]): a counter or a limited pass.
  final bool counts;

  /// It runs its [minutes] from [from] at [now].
  bool within(DateTime now) => from != null && from!.add(Duration(minutes: minutes)).isAfter(now);

  /// The 24 hours since [from] that [now] is in: 0 the first.
  int windowAt(DateTime now) => from == null ? 0 : now.difference(from!).inSeconds ~/ Duration.secondsPerDay;

  /// A daily pass still runs its [days] at [now].
  bool dailyOn(DateTime now) => from != null && windowAt(now) < days;

  /// A daily pass's uses left in [now]'s 24 hours.
  int dailyLeft(DateTime now) => !dailyOn(now) ? 0 : count - (windowAt(now) == window ? used : 0);
}
