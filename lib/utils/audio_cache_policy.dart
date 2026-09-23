import 'package:neom_core/utils/enums/subscription_level.dart';

/// Decides whether a track may be kept whole on the device.
///
/// Caching a full file is a download in all but name: `LockCachingAudioSource`
/// fetches the entire song on first play and keeps it, and it does not stop
/// when the listener skips — just_audio only ends that fetch when the file is
/// complete or fails. Keeping songs on the device is a subscriber benefit, so
/// everyone else streams instead, which fetches only the ranges that are
/// actually played.
///
/// "Downloads" live in this cache only; nothing is written where the user
/// could copy the file out of the app.
class AudioCachePolicy {
  AudioCachePolicy._();

  static bool canCacheFully({
    required bool isWeb,
    required bool canPersistUserActivity,
    required SubscriptionLevel? subscriptionLevel,
    required bool cacheSetting,
    required bool isInternalUrl,
  }) {
    // The browser manages its own HTTP cache; there is no file to keep.
    if (isWeb) return false;
    if (!canPersistUserActivity) return false;
    if (!hasSubscription(subscriptionLevel)) return false;
    return cacheSetting && isInternalUrl;
  }

  /// Any paid or granted level above freemium — the same line the playback
  /// gate draws for full access.
  static bool hasSubscription(SubscriptionLevel? level) =>
      level != null && level.value > SubscriptionLevel.freemium.value;
}
