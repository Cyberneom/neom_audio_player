import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/utils/casete_session_fields.dart';
import 'package:neom_audio_player/utils/mappers/media_item_mapper.dart';
import 'package:neom_core/domain/model/app_media_item.dart';

void main() {
  group('the owner a session is attributed to', () {
    test('the owner email wins over ownerId, which may be a profile id', () {
      expect(CaseteSessionFields.ownerEmail({'ownerId': 'profile-9', 'ownerEmail': 'artist@x.com'}),
          'artist@x.com');
    });

    test('ownerId is the fallback for items with no email', () {
      expect(CaseteSessionFields.ownerEmail({'ownerId': 'external-artist'}), 'external-artist');
      expect(CaseteSessionFields.ownerEmail({'ownerEmail': 'null', 'ownerId': 'x'}), 'x');
      expect(CaseteSessionFields.ownerEmail(null), '');
    });

    test('the email survives the player mappers and the saved queue', () {
      // Without it, sessions stored the profile id and the creator's
      // royalty screen, which matches by email, counted zero.
      final item = MediaItemMapper.fromAppMediaItem(
        item: AppMediaItem(id: 'song', name: 'Song', ownerId: 'profile-9', ownerEmail: 'artist@x.com'),
      );
      expect(CaseteSessionFields.ownerEmail(item.extras), 'artist@x.com');

      final restored = MediaItemMapper.fromJSON(MediaItemMapper.toJSON(item));
      expect(CaseteSessionFields.ownerEmail(restored.extras), 'artist@x.com');
    });
  });

  group('whether the listener owns the item', () {
    bool owns(Map<String, dynamic>? extras, {String itemId = 'song', List<String>? legacy}) =>
        CaseteSessionFields.listenerOwnsItem(
          extras: extras,
          itemId: itemId,
          listenerEmail: 'artist@x.com',
          listenerProfileIds: ['profile-9'],
          legacyReleaseItemIds: legacy,
        );

    test('matched by email, by profile id, or by the old id conventions', () {
      expect(owns({'ownerEmail': 'artist@x.com'}), isTrue);
      expect(owns({'ownerId': 'profile-9'}), isTrue);
      expect(owns({}, itemId: 'artist@x.com'), isTrue);
      expect(owns({}, legacy: ['song']), isTrue);
    });

    test('someone else\'s item is not owned', () {
      expect(owns({'ownerEmail': 'other@x.com', 'ownerId': 'profile-1'}), isFalse);
    });
  });
}
