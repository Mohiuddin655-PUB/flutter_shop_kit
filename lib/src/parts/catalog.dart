import 'dart:async' show Timer, unawaited;

import 'package:flutter/widgets.dart' show AppLifecycleListener, ChangeNotifier;

import '../../keys/catalog_keys.dart';
import '../delegates/catalog_delegate.dart';
import '../delegates/clock.dart';
import '../models/bundle_terms.dart';
import '../models/catalog_bundle.dart';
import '../models/catalog_pass.dart';
import '../models/offer.dart';
import '../models/pass_terms.dart';

/// What the admin's catalog sells now and for how much: the phone's copy at once, the server's when its version
/// changes. An item no longer listed isn't sold (what is owned stays); one on sale costs its sale's price while the
/// sale runs, by the server's clock, as the rules charge. Before the first copy, every item is sold and the passes are
/// the app's [fallbackPasses]. Told when the copy changes, and when a sale starts or ends.
class Catalog extends ChangeNotifier {
  Catalog(this._source, this._clock, {Map<String, Object?> fallbackPasses = const {}}) : _fallback = fallbackPasses {
    _set(_source.cached());
    _source.versionChanges.addListener(ask);
    // A sleeping phone holds its timer back: back from the background, prices are worked out again and it is set anew.
    _resume = AppLifecycleListener(onResume: _schedule);
    // The version may be known already, before the first page that sells asks.
    ask();
  }

  final CatalogDelegate _source;
  final Clock _clock;
  final Map<String, Object?> _fallback;
  late final AppLifecycleListener _resume;

  Map<String, Object?>? _config;
  Map<String, Offer>? _offers;
  Map<String, CatalogPass> _passes = const {};
  Map<String, CatalogBundle> _bundles = const {};

  int? _version;
  Future<void>? _reading;
  Timer? _change;

  /// The copy as it came (for what the app keeps in it besides); null before the first.
  Map<String, Object?>? get config => _config;

  /// [id] is for sale now.
  bool sells(String id) => _offers == null || _offers!.containsKey(id);

  /// Item [id]'s offer; null when the copy doesn't list it, or before the first copy.
  Offer? offer(String id) => _offers?[id];

  /// The passes sold, by id.
  Iterable<String> get passIds => _passes.keys;

  /// Pass [id]'s terms now (its sale's price while the sale runs); null when it isn't sold.
  PassTerms? pass(String id) => _passes[id]?.termsAt(_clock.now);

  /// The bundles sold, by id.
  Iterable<String> get bundleIds => _bundles.keys;

  /// Bundle [id]'s terms now (its sale's price while the sale runs); null when it isn't sold.
  BundleTerms? bundle(String id) => _bundles[id]?.termsAt(_clock.now);

  /// Reads the server's catalog when its version differs from the copy's; a second caller waits for the first.
  Future<void> refresh() {
    final version = _source.version;
    if (version == null || version == _version) return _reading ?? Future.value();
    return _reading ??= _read(version).whenComplete(() => _reading = null);
  }

  /// [refresh], without waiting for it.
  void ask() => unawaited(refresh());

  Future<void> _read(int version) async {
    final config = await _source.fetch(version);
    if (config != null) _set(config);
  }

  void _set(Map<String, Object?>? config) {
    final version = config?[CatalogKeys.version], items = config?[CatalogKeys.items];
    _config = config;
    _version = version is int ? version : null;
    _offers = items is Map ? {for (final MapEntry(:key, :value) in items.entries) '$key': ?Offer.from(value)} : null;
    final passes = _byId(config?[CatalogKeys.passes], CatalogPass.from);
    _passes = passes.isEmpty ? _byId(_fallback, CatalogPass.from) : passes;
    _bundles = _byId(config?[CatalogKeys.bundles], CatalogBundle.from);
    _schedule();
  }

  static Map<String, T> _byId<T>(Object? source, T? Function(Object? value) read) => {
    if (source is Map)
      for (final MapEntry(:key, :value) in source.entries) '$key': ?read(value),
  };

  /// Told now, and again when a sale next starts or ends, so prices on screen follow it.
  void _schedule() {
    final now = _clock.now;
    final changes = [
      ...?_offers?.values,
      for (final pass in _passes.values) pass.offer,
      for (final bundle in _bundles.values) bundle.offer,
    ].map((o) => o.nextChange(now)).whereType<DateTime>().toList()..sort();
    _change?.cancel();
    if (changes.isNotEmpty) _change = Timer(changes.first.difference(now), _schedule);
    notifyListeners();
  }

  @override
  void dispose() {
    _change?.cancel();
    _resume.dispose();
    _source.versionChanges.removeListener(ask);
    super.dispose();
  }
}
