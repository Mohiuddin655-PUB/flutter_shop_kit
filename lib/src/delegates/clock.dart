/// The server's time, given by the app, so passes, sales and limits go by the same clock as the security rules.
abstract interface class Clock {
  DateTime get now;
}
