// Tests for `JamSession`, `JamParticipant`, `JamQueueItem`, `JamChatMessage`,
// y los enums asociados (JamSessionType, JamParticipantRole, JamSessionStatus,
// JamVoteType, JamChatMessageType).

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/domain/models/jam_session.dart';
import 'package:neom_audio_player/utils/enums/jam_session_type.dart';

void main() {
  group('JamSessionType', () {
    test('tiene 3 valores', () {
      expect(JamSessionType.values, hasLength(3));
    });

    test('value de cada tipo', () {
      expect(JamSessionType.open.value, 'open');
      expect(JamSessionType.private.value, 'private');
      expect(JamSessionType.friendsOnly.value, 'friends_only');
    });
  });

  group('JamParticipantRole — capabilities', () {
    test('host tiene todas las capabilities', () {
      const role = JamParticipantRole.host;
      expect(role.canControlPlayback, isTrue);
      expect(role.canAddSongs, isTrue);
      expect(role.canRemoveSongs, isTrue);
      expect(role.canKickUsers, isTrue);
      expect(role.canPromoteUsers, isTrue);
    });

    test('coHost: control + remove + promote, NO kick', () {
      const role = JamParticipantRole.coHost;
      expect(role.canControlPlayback, isTrue);
      expect(role.canAddSongs, isTrue);
      expect(role.canRemoveSongs, isTrue);
      expect(role.canKickUsers, isFalse);
      expect(role.canPromoteUsers, isTrue);
    });

    test('dj: solo agregar songs', () {
      const role = JamParticipantRole.dj;
      expect(role.canAddSongs, isTrue);
      expect(role.canControlPlayback, isFalse);
      expect(role.canRemoveSongs, isFalse);
      expect(role.canKickUsers, isFalse);
    });

    test('listener: NO puede hacer nada', () {
      const role = JamParticipantRole.listener;
      expect(role.canAddSongs, isFalse);
      expect(role.canControlPlayback, isFalse);
      expect(role.canRemoveSongs, isFalse);
      expect(role.canKickUsers, isFalse);
      expect(role.canPromoteUsers, isFalse);
    });
  });

  group('JamSessionStatus / JamVoteType / JamChatMessageType', () {
    test('JamSessionStatus tiene 4 estados', () {
      expect(JamSessionStatus.values, hasLength(4));
    });

    test('JamVoteType tiene 3 tipos con weights', () {
      expect(JamVoteType.values, hasLength(3));
      expect(JamVoteType.upvote.weight, 1);
      expect(JamVoteType.downvote.weight, -1);
      expect(JamVoteType.superVote.weight, 3);
    });

    test('JamChatMessageType tiene 4 tipos', () {
      expect(JamChatMessageType.values, hasLength(4));
    });
  });

  group('JamSession — defaults & getters', () {
    JamSession buildSession({
      List<JamQueueItem> queue = const [],
      List<JamParticipant> participants = const [],
      int currentIndex = 0,
      int maxParticipants = 50,
    }) =>
        JamSession(
          id: 's1', name: 'My Jam',
          type: JamSessionType.open,
          status: JamSessionStatus.active,
          hostId: 'u1', hostName: 'Alice',
          joinCode: 'ABC123',
          createdAt: DateTime(2026),
          queue: queue,
          participants: participants,
          currentIndex: currentIndex,
          maxParticipants: maxParticipants,
        );

    test('defaults razonables', () {
      final s = buildSession();
      expect(s.description, '');
      expect(s.imageUrl, '');
      expect(s.isPlaying, isFalse);
      expect(s.maxParticipants, 50);
      expect(s.allowRequests, isTrue);
      expect(s.allowVoting, isTrue);
      expect(s.superVotesPerUser, 3);
      expect(s.autoSkipThreshold, -5);
    });

    test('currentItem: null si queue vacío', () {
      final s = buildSession();
      expect(s.currentItem, isNull);
    });

    test('currentItem: null si currentIndex fuera de rango', () {
      final item = JamQueueItem(
        id: 'q1', mediaItem: const MediaItem(id: 'm1', title: 'X'),
        addedByUserId: 'u1', addedByName: 'Alice',
        addedAt: DateTime(2026),
      );
      final s = buildSession(queue: [item], currentIndex: 5);
      expect(s.currentItem, isNull);
    });

    test('currentItem: retorna queue[currentIndex]', () {
      final item1 = JamQueueItem(
        id: 'q1', mediaItem: const MediaItem(id: 'm1', title: 'X'),
        addedByUserId: 'u1', addedByName: 'Alice',
        addedAt: DateTime(2026),
      );
      final item2 = JamQueueItem(
        id: 'q2', mediaItem: const MediaItem(id: 'm2', title: 'Y'),
        addedByUserId: 'u1', addedByName: 'Alice',
        addedAt: DateTime(2026),
      );
      final s = buildSession(queue: [item1, item2], currentIndex: 1);
      expect(s.currentItem?.id, 'q2');
    });

    test('upcomingItems: vacío si no hay songs después', () {
      final item = JamQueueItem(
        id: 'q1', mediaItem: const MediaItem(id: 'm1', title: 'X'),
        addedByUserId: 'u1', addedByName: 'Alice',
        addedAt: DateTime(2026),
      );
      final s = buildSession(queue: [item], currentIndex: 0);
      expect(s.upcomingItems, isEmpty);
    });

    test('upcomingItems: retorna queue después de currentIndex', () {
      final items = List.generate(5, (i) => JamQueueItem(
        id: 'q$i',
        mediaItem: MediaItem(id: 'm$i', title: 'X$i'),
        addedByUserId: 'u1', addedByName: 'A',
        addedAt: DateTime(2026),
      ));
      final s = buildSession(queue: items, currentIndex: 1);
      expect(s.upcomingItems, hasLength(3));
      expect(s.upcomingItems.first.id, 'q2');
    });

    test('participantCount = participants.length', () {
      final s = buildSession();
      expect(s.participantCount, 0);
    });

    test('isFull: true cuando alcanza maxParticipants', () {
      final participants = List.generate(3, (i) => JamParticipant(
        oderId: 'u$i', displayName: 'U$i',
        role: JamParticipantRole.listener,
        joinedAt: DateTime(2026),
      ));
      final s = buildSession(
        participants: participants, maxParticipants: 3,
      );
      expect(s.isFull, isTrue);
    });

    test('activeParticipants: solo los conectados', () {
      final participants = [
        JamParticipant(
          oderId: 'u1', displayName: 'A',
          role: JamParticipantRole.listener,
          joinedAt: DateTime(2026), isConnected: true,
        ),
        JamParticipant(
          oderId: 'u2', displayName: 'B',
          role: JamParticipantRole.listener,
          joinedAt: DateTime(2026), isConnected: false,
        ),
      ];
      final s = buildSession(participants: participants);
      expect(s.activeParticipants, hasLength(1));
      expect(s.activeParticipants.first.oderId, 'u1');
    });

    test('shareUrl formato neom://jam/<joinCode>', () {
      final s = buildSession();
      expect(s.shareUrl, 'neom://jam/ABC123');
    });
  });

  group('JamSession — round-trip JSON', () {
    test('preserva campos básicos', () {
      final original = JamSession(
        id: 's1', name: 'My Jam',
        description: 'Una sesión chévere',
        imageUrl: 'https://x/img.jpg',
        type: JamSessionType.private,
        status: JamSessionStatus.active,
        hostId: 'u1', hostName: 'Alice',
        joinCode: 'ABC123',
        createdAt: DateTime(2026, 1, 15),
        startedAt: DateTime(2026, 1, 15, 10),
        maxParticipants: 100,
        allowRequests: false,
        autoSkipThreshold: -3,
      );
      final restored = JamSession.fromJson(original.toJson());
      expect(restored.id, 's1');
      expect(restored.type, JamSessionType.private);
      expect(restored.maxParticipants, 100);
      expect(restored.allowRequests, isFalse);
      expect(restored.autoSkipThreshold, -3);
      expect(restored.startedAt, isNotNull);
    });
  });

  group('JamParticipant', () {
    test('defaults: isConnected=true, songsAdded=0, superVotesRemaining=3', () {
      final p = JamParticipant(
        oderId: 'u1', displayName: 'Alice',
        role: JamParticipantRole.dj,
        joinedAt: DateTime(2026),
      );
      expect(p.isConnected, isTrue);
      expect(p.songsAdded, 0);
      expect(p.superVotesRemaining, 3);
    });

    test('round-trip JSON', () {
      final original = JamParticipant(
        oderId: 'u1', displayName: 'Alice',
        avatarUrl: 'https://x/a.jpg',
        role: JamParticipantRole.host,
        joinedAt: DateTime(2026),
        isConnected: false,
        songsAdded: 5,
        superVotesRemaining: 1,
      );
      final restored = JamParticipant.fromJson(original.toJson());
      expect(restored.oderId, 'u1');
      expect(restored.role, JamParticipantRole.host);
      expect(restored.isConnected, isFalse);
      expect(restored.songsAdded, 5);
      expect(restored.superVotesRemaining, 1);
    });
  });

  group('JamQueueItem.score', () {
    test('score = upvotes - downvotes', () {
      final item = JamQueueItem(
        id: 'q1', mediaItem: const MediaItem(id: 'm1', title: 'X'),
        addedByUserId: 'u1', addedByName: 'A',
        addedAt: DateTime(2026),
        upvotes: 10, downvotes: 3,
      );
      expect(item.score, 7);
    });

    test('score puede ser negativo', () {
      final item = JamQueueItem(
        id: 'q1', mediaItem: const MediaItem(id: 'm1', title: 'X'),
        addedByUserId: 'u1', addedByName: 'A',
        addedAt: DateTime(2026),
        upvotes: 2, downvotes: 5,
      );
      expect(item.score, -3);
    });

    test('defaults: upvotes=0, downvotes=0, score=0', () {
      final item = JamQueueItem(
        id: 'q1', mediaItem: const MediaItem(id: 'm1', title: 'X'),
        addedByUserId: 'u1', addedByName: 'A',
        addedAt: DateTime(2026),
      );
      expect(item.score, 0);
      expect(item.isPlayed, isFalse);
    });
  });

  group('JamChatMessage', () {
    test('default type=text', () {
      final msg = JamChatMessage(
        id: 'm1', oderId: 'u1', senderName: 'Alice',
        message: 'Hola', sentAt: DateTime(2026),
      );
      expect(msg.type, JamChatMessageType.text);
    });

    test('round-trip JSON', () {
      final original = JamChatMessage(
        id: 'm1', oderId: 'u1', senderName: 'Alice',
        senderAvatarUrl: 'https://x/a.jpg',
        message: 'Hola', sentAt: DateTime(2026),
        type: JamChatMessageType.songRequest,
      );
      final restored = JamChatMessage.fromJson(original.toJson());
      expect(restored.id, 'm1');
      expect(restored.message, 'Hola');
      expect(restored.type, JamChatMessageType.songRequest);
    });
  });
}
