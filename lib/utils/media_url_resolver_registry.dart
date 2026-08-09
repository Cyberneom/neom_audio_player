import 'package:neom_core/domain/use_cases/audio_handler_service.dart';

/// Ordered registry of [MediaUrlResolver]s consulted by the playback error
/// recovery flow before a failing track is retried or declared dead.
///
/// Modules with a source-specific refresh path (expired signed URLs, rotated
/// CDN links…) register a resolver at startup:
/// ```dart
/// Sint.find<AudioHandlerService>().registerUrlResolver('ytmusic', myResolver);
/// ```
/// The first non-empty, actually-different URL wins. A resolver that throws
/// or returns null/empty/the-same URL is skipped — resolvers are isolated
/// from each other so one broken module cannot break recovery.
class MediaUrlResolverRegistry {

  final Map<String, MediaUrlResolver> _resolvers = {};

  int get length => _resolvers.length;
  bool get isEmpty => _resolvers.isEmpty;

  /// Registers [resolver] under [owner]; re-registering the same owner
  /// replaces the previous resolver (registration order is preserved).
  void register(String owner, MediaUrlResolver resolver) {
    _resolvers[owner] = resolver;
  }

  void unregister(String owner) {
    _resolvers.remove(owner);
  }

  /// Asks every registered resolver for a fresh URL for [itemId].
  ///
  /// Returns the first URL that is non-null, non-empty and different from the
  /// item's current `extras['url']`; null when nobody can help.
  Future<String?> resolveFreshUrl(
      String itemId, Map<String, dynamic> extras) async {
    final currentUrl = extras['url']?.toString() ?? '';
    for (final resolver in _resolvers.values) {
      try {
        final url = await resolver(itemId, extras);
        if (url != null && url.isNotEmpty && url != currentUrl) {
          return url;
        }
      } catch (_) {
        // Resolver isolation: a broken module must not break recovery.
      }
    }
    return null;
  }
}
