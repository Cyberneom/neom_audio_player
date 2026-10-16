/// A host-verified server grant for one short-lived remote audio item.
/// This is not a local subscription override: the host must verify the server
/// response and keep isAuthorized bound to its account and route lifetime.
class EphemeralAudioGrant {
  EphemeralAudioGrant({
    required this.itemId,
    required this.uri,
    required this.expiresAt,
    required this.isAuthorized,
  });
  final String itemId;
  final Uri uri;
  final DateTime expiresAt;
  final bool Function() isAuthorized;
  bool _revoked = false;

  bool permits(String id, String url, {DateTime? now}) {
    if (_revoked ||
        id != itemId ||
        url != uri.toString() ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        !(now ?? DateTime.now()).isBefore(expiresAt)) {
      return false;
    }
    try {
      return isAuthorized();
    } catch (_) {
      return false;
    }
  }

  void revoke() => _revoked = true;
}

/// Optional capability: ordinary audio invokers need not support remote grants.
abstract interface class EphemeralAudioService {
  Future<void> beginEphemeralAudio(EphemeralAudioGrant grant);
}
