import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/neom_audio_handler.dart';
import 'package:neom_audio_player/utils/audio_item_source_availability.dart';
import 'package:neom_audio_player/utils/mappers/media_item_mapper.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/utils/enums/app_media_source.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';

void main() {
  group('Public Domain Casete exclusion & mapping', () {
    test('marks AppMediaSource.publicDomain as non-Casete and preserves source & localPath', () {
      final pdTrack = AppMediaItem(
        id: 'pd_001',
        name: 'Morning Mood',
        ownerName: 'Musopen Symphony',
        ownerId: 'neom_public_domain',
        ownerEmail: '',
        album: 'Peer Gynt Suite No. 1',
        duration: 263,
        url: 'https://archive.org/download/example/morning.mp3',
        path: '/data/user/0/com.gigmeout.letsgig/files/neom_public_domain/pd_001.mp3',
        imgUrl: 'https://archive.org/download/example/__ia_thumb.jpg',
        type: MediaItemType.song,
        mediaSource: AppMediaSource.publicDomain,
      );

      final mapped = MediaItemMapper.fromAppMediaItem(item: pdTrack);

      expect(mapped.extras?['source'], AppMediaSource.publicDomain.name);
      expect(mapped.extras?['isPublicDomain'], isTrue);
      expect(mapped.extras?['casete'], isFalse);
      expect(mapped.extras?['localPath'], pdTrack.path);
      expect(NeomAudioHandler.isPublicDomainMediaItem(mapped), isTrue);

      final roundTripped = MediaItemMapper.toAppMediaItem(mapped);
      expect(roundTripped.mediaSource, AppMediaSource.publicDomain);
      expect(roundTripped.path, pdTrack.path);
    });

    test('recognizes browser blob: URLs for offline public domain playback', () {
      expect(
        isBlobAudioSource('blob:https://gig-me-out.web.app/1234-5678'),
        isTrue,
      );
      expect(isBlobAudioSource('blob:'), isFalse);
      expect(isBlobAudioSource('https://archive.org/file.mp3'), isFalse);

      final offlineBlobTrack = AppMediaItem(
        id: 'pd_001',
        name: 'Morning Mood',
        ownerName: 'Musopen Symphony',
        ownerId: 'neom_public_domain',
        ownerEmail: '',
        url: 'blob:https://gig-me-out.web.app/1234-5678',
        type: MediaItemType.song,
        mediaSource: AppMediaSource.publicDomain,
      );
      expect(isAudioPlaybackItem(offlineBlobTrack), isTrue);
      expect(hasNoAudioSource(offlineBlobTrack), isFalse);
    });

    test('keeps independent internal tracks eligible for Casete royalties', () {
      final indieTrack = AppMediaItem(
        id: 'indie_001',
        name: 'Indie Song',
        ownerName: 'Independent Band',
        ownerId: 'artist_uid_123',
        ownerEmail: 'artist@example.com',
        album: 'First EP',
        duration: 210,
        url: 'https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/indie.mp3',
        imgUrl: 'https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/cover.jpg',
        type: MediaItemType.song,
        mediaSource: AppMediaSource.internal,
      );

      final mapped = MediaItemMapper.fromAppMediaItem(item: indieTrack);

      expect(mapped.extras?['source'], AppMediaSource.internal.name);
      expect(mapped.extras?['isPublicDomain'], isFalse);
      expect(mapped.extras?['casete'], isTrue);
      expect(NeomAudioHandler.isPublicDomainMediaItem(mapped), isFalse);

      final roundTripped = MediaItemMapper.toAppMediaItem(mapped);
      expect(roundTripped.mediaSource, AppMediaSource.internal);
    });
  });
}
