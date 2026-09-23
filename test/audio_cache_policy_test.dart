import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/utils/audio_cache_policy.dart';
import 'package:neom_core/utils/enums/subscription_level.dart';

void main() {
  bool cache({
    bool isWeb = false,
    bool canPersist = true,
    SubscriptionLevel? level = SubscriptionLevel.basic,
    bool setting = true,
    bool internal = true,
  }) =>
      AudioCachePolicy.canCacheFully(
        isWeb: isWeb,
        canPersistUserActivity: canPersist,
        subscriptionLevel: level,
        cacheSetting: setting,
        isInternalUrl: internal,
      );

  test('a subscriber with caching on keeps the whole song', () {
    expect(cache(), isTrue);
    expect(cache(level: SubscriptionLevel.plus), isTrue);
  });

  test('freemium streams: no whole-file download', () {
    expect(cache(level: SubscriptionLevel.freemium), isFalse);
  });

  test('a user whose level has not loaded streams', () {
    expect(cache(level: null), isFalse);
  });

  test('a guest streams', () {
    expect(cache(canPersist: false), isFalse);
  });

  test('the subscriber setting still applies', () {
    expect(cache(setting: false), isFalse);
  });

  test('only platform audio is cached, never third-party URLs', () {
    expect(cache(internal: false), isFalse);
  });

  test('the web never caches whole files', () {
    expect(cache(isWeb: true), isFalse);
  });
}
