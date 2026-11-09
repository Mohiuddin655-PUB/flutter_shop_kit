/// How a pass works.
enum PassType {
  /// Runs a number of minutes from the server's time it was bought; bought again only once over, or, if it stacks,
  /// adding its minutes while it runs.
  duration,

  /// A number of uses, each use taking one.
  counter,

  /// On for good once bought.
  lifetime,

  /// A number of uses in each 24 hours from when it was bought, for a number of days.
  daily,

  /// A number of uses within a number of minutes of when it was bought.
  limited,

  /// On until a date the catalog sets.
  until,
}
