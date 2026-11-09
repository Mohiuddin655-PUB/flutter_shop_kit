import 'buy_limit.dart';

/// What a bundle gives: its [items] and its [passes] (by id, up to [bundleMaxPasses]), for [price], within
/// [limit].
typedef BundleTerms = ({int price, List<String> items, List<String> passes, BuyLimit? limit});

/// The most passes a bundle holds, as the security rules check them one by one.
const bundleMaxPasses = 3;
