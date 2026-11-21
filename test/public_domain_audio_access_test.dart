import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/neom_audio_handler.dart';
import 'package:neom_core/utils/enums/app_media_source.dart';

void main() {
  group('NeomAudioHandler.isPublicDomainMediaItem', () {
    test('returns true for publicDomain and jamendo sources', () {
      final pd = MediaItem(
        id: 'pd_ab_quijote_ch1',
        title: 'Capítulo 1',
        extras: {'source': AppMediaSource.publicDomain.name},
      );
      final jamendo = MediaItem(
        id: 'jam_123',
        title: 'CC Track',
        extras: {'source': AppMediaSource.jamendo.name},
      );

      expect(NeomAudioHandler.isPublicDomainMediaItem(pd), isTrue);
      expect(NeomAudioHandler.isPublicDomainMediaItem(jamendo), isTrue);
    });

    test('returns false for internal, external, offline, and null items', () {
      expect(NeomAudioHandler.isPublicDomainMediaItem(null), isFalse);
      for (final src in [
        AppMediaSource.internal,
        AppMediaSource.external,
        AppMediaSource.offline,
      ]) {
        final item = MediaItem(
          id: 'item_${src.name}',
          title: 'Paid Track',
          extras: {'source': src.name},
        );
        expect(NeomAudioHandler.isPublicDomainMediaItem(item), isFalse);
      }
    });
  });
}
