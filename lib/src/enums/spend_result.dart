/// How a spend (a buy or a pass's use) went.
enum SpendResult {
  /// Done, or nothing was owed (already owned, a pass still running).
  done,

  /// Taken on this phone and waiting in the queue: the server takes it when the link is back (or answers late), and may
  /// yet refuse it, which undoes it.
  pending,

  /// Past what may be held (a pass's most uses) or bought (its limit in its minutes, or for good): nothing was spent.
  overLimit,

  /// The balance doesn't cover the price.
  notEnough,

  /// The server couldn't be reached.
  offline,

  /// Refused or broken: nothing was spent.
  failed,
}
