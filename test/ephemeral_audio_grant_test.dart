import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/domain/use_cases/ephemeral_audio_service.dart';

void main() {
  final now = DateTime.utc(2026, 10, 4);
  final url = Uri.parse('https://media.example/track.mp3?signature=server');
  EphemeralAudioGrant grant({Uri? uri, bool Function()? authorized}) =>
      EphemeralAudioGrant(
        itemId: 'provider:item:grant',
        uri: uri ?? url,
        expiresAt: now.add(const Duration(minutes: 1)),
        isAuthorized: authorized ?? () => true,
      );
  test('authorization binds exact item and signed URL, including query', () {
    final access = grant();
    expect(access.permits(access.itemId, url.toString(), now: now), isTrue);
    expect(access.permits('other', url.toString(), now: now), isFalse);
    expect(
      access.permits(
        access.itemId,
        url.replace(query: '').toString(),
        now: now,
      ),
      isFalse,
    );
    expect(
      access.permits(
        access.itemId,
        'https://other.example/track.mp3?signature=server',
        now: now,
      ),
      isFalse,
    );
  });
  test('expiry has no grace period and revocation is terminal', () {
    final access = grant();
    expect(
      access.permits(access.itemId, url.toString(), now: access.expiresAt),
      isFalse,
    );
    access.revoke();
    expect(access.permits(access.itemId, url.toString(), now: now), isFalse);
  });
  test(
    'account or route invalidation is checked on every transport action',
    () {
      var current = true;
      final access = grant(authorized: () => current);
      expect(access.permits(access.itemId, url.toString(), now: now), isTrue);
      current = false;
      expect(access.permits(access.itemId, url.toString(), now: now), isFalse);
    },
  );
  test('failed session callback denies access', () {
    final access = grant(
      authorized: () => throw StateError('session disposed'),
    );
    expect(access.permits(access.itemId, url.toString(), now: now), isFalse);
  });
  test('unsafe source URI cannot become an authorized stream', () {
    for (final value in [
      'http://media.example/track',
      'https://u:p@media.example/track',
      'https://media.example/track#fragment',
    ]) {
      final access = grant(uri: Uri.parse(value));
      expect(access.permits(access.itemId, value, now: now), isFalse);
    }
  });
}
