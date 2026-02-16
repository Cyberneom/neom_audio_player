import 'package:audio_service/audio_service.dart';

import '../../utils/enums/jam_session_type.dart';

/// Represents a collaborative listening session (Jam)
class JamSession {
  /// Unique session identifier
  final String id;

  /// Session name
  final String name;

  /// Session description
  final String description;

  /// Cover image URL
  final String imageUrl;

  /// Session type (open, private, friends only)
  final JamSessionType type;

  /// Session status
  final JamSessionStatus status;

  /// Host user ID
  final String hostId;

  /// Host display name
  final String hostName;

  /// Join code for sharing
  final String joinCode;

  /// List of participants
  final List<JamParticipant> participants;

  /// Current queue
  final List<JamQueueItem> queue;

  /// Current playing index
  final int currentIndex;

  /// Current playback position in milliseconds
  final int playbackPositionMs;

  /// Whether currently playing
  final bool isPlaying;

  /// Creation timestamp
  final DateTime createdAt;

  /// Session start time (when first song plays)
  final DateTime? startedAt;

  /// Session end time
  final DateTime? endedAt;

  /// Maximum participants allowed
  final int maxParticipants;

  /// Whether to allow song requests
  final bool allowRequests;

  /// Whether to allow voting
  final bool allowVoting;

  /// Number of super votes per user
  final int superVotesPerUser;

  /// Auto-skip threshold (negative votes)
  final int autoSkipThreshold;

  /// Chat messages (last N messages)
  final List<JamChatMessage> recentMessages;

  const JamSession({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    required this.type,
    required this.status,
    required this.hostId,
    required this.hostName,
    required this.joinCode,
    this.participants = const [],
    this.queue = const [],
    this.currentIndex = 0,
    this.playbackPositionMs = 0,
    this.isPlaying = false,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.maxParticipants = 50,
    this.allowRequests = true,
    this.allowVoting = true,
    this.superVotesPerUser = 3,
    this.autoSkipThreshold = -5,
    this.recentMessages = const [],
  });

  JamSession copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    JamSessionType? type,
    JamSessionStatus? status,
    String? hostId,
    String? hostName,
    String? joinCode,
    List<JamParticipant>? participants,
    List<JamQueueItem>? queue,
    int? currentIndex,
    int? playbackPositionMs,
    bool? isPlaying,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
    int? maxParticipants,
    bool? allowRequests,
    bool? allowVoting,
    int? superVotesPerUser,
    int? autoSkipThreshold,
    List<JamChatMessage>? recentMessages,
  }) {
    return JamSession(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      status: status ?? this.status,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      joinCode: joinCode ?? this.joinCode,
      participants: participants ?? this.participants,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      playbackPositionMs: playbackPositionMs ?? this.playbackPositionMs,
      isPlaying: isPlaying ?? this.isPlaying,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      allowRequests: allowRequests ?? this.allowRequests,
      allowVoting: allowVoting ?? this.allowVoting,
      superVotesPerUser: superVotesPerUser ?? this.superVotesPerUser,
      autoSkipThreshold: autoSkipThreshold ?? this.autoSkipThreshold,
      recentMessages: recentMessages ?? this.recentMessages,
    );
  }

  /// Get current song
  JamQueueItem? get currentItem {
    if (queue.isEmpty || currentIndex >= queue.length) return null;
    return queue[currentIndex];
  }

  /// Get upcoming songs
  List<JamQueueItem> get upcomingItems {
    if (currentIndex >= queue.length - 1) return [];
    return queue.sublist(currentIndex + 1);
  }

  /// Get participant count
  int get participantCount => participants.length;

  /// Check if session is full
  bool get isFull => participantCount >= maxParticipants;

  /// Get active participants (not disconnected)
  List<JamParticipant> get activeParticipants =>
      participants.where((p) => p.isConnected).toList();

  /// Get share URL
  String get shareUrl => 'neom://jam/$joinCode';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'type': type.value,
      'status': status.value,
      'hostId': hostId,
      'hostName': hostName,
      'joinCode': joinCode,
      'participants': participants.map((p) => p.toJson()).toList(),
      'queue': queue.map((q) => q.toJson()).toList(),
      'currentIndex': currentIndex,
      'playbackPositionMs': playbackPositionMs,
      'isPlaying': isPlaying,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'maxParticipants': maxParticipants,
      'allowRequests': allowRequests,
      'allowVoting': allowVoting,
      'superVotesPerUser': superVotesPerUser,
      'autoSkipThreshold': autoSkipThreshold,
    };
  }

  factory JamSession.fromJson(Map<String, dynamic> json) {
    return JamSession(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      type: JamSessionType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => JamSessionType.open,
      ),
      status: JamSessionStatus.values.firstWhere(
        (e) => e.value == json['status'],
        orElse: () => JamSessionStatus.creating,
      ),
      hostId: json['hostId'] as String,
      hostName: json['hostName'] as String,
      joinCode: json['joinCode'] as String,
      participants: (json['participants'] as List?)
              ?.map((p) => JamParticipant.fromJson(p))
              .toList() ??
          [],
      queue: (json['queue'] as List?)
              ?.map((q) => JamQueueItem.fromJson(q))
              .toList() ??
          [],
      currentIndex: json['currentIndex'] as int? ?? 0,
      playbackPositionMs: json['playbackPositionMs'] as int? ?? 0,
      isPlaying: json['isPlaying'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      maxParticipants: json['maxParticipants'] as int? ?? 50,
      allowRequests: json['allowRequests'] as bool? ?? true,
      allowVoting: json['allowVoting'] as bool? ?? true,
      superVotesPerUser: json['superVotesPerUser'] as int? ?? 3,
      autoSkipThreshold: json['autoSkipThreshold'] as int? ?? -5,
    );
  }
}

/// Participant in a Jam Session
class JamParticipant {
  final String oderId;
  final String displayName;
  final String? avatarUrl;
  final JamParticipantRole role;
  final DateTime joinedAt;
  final bool isConnected;
  final int songsAdded;
  final int superVotesRemaining;

  const JamParticipant({
    required this.oderId,
    required this.displayName,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
    this.isConnected = true,
    this.songsAdded = 0,
    this.superVotesRemaining = 3,
  });

  JamParticipant copyWith({
    String? oderId,
    String? displayName,
    String? avatarUrl,
    JamParticipantRole? role,
    DateTime? joinedAt,
    bool? isConnected,
    int? songsAdded,
    int? superVotesRemaining,
  }) {
    return JamParticipant(
      oderId: oderId ?? this.oderId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isConnected: isConnected ?? this.isConnected,
      songsAdded: songsAdded ?? this.songsAdded,
      superVotesRemaining: superVotesRemaining ?? this.superVotesRemaining,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'oderId': oderId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'role': role.value,
      'joinedAt': joinedAt.toIso8601String(),
      'isConnected': isConnected,
      'songsAdded': songsAdded,
      'superVotesRemaining': superVotesRemaining,
    };
  }

  factory JamParticipant.fromJson(Map<String, dynamic> json) {
    return JamParticipant(
      oderId: json['oderId'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: JamParticipantRole.values.firstWhere(
        (e) => e.value == json['role'],
        orElse: () => JamParticipantRole.listener,
      ),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      isConnected: json['isConnected'] as bool? ?? true,
      songsAdded: json['songsAdded'] as int? ?? 0,
      superVotesRemaining: json['superVotesRemaining'] as int? ?? 3,
    );
  }
}

/// Queue item in a Jam Session with voting
class JamQueueItem {
  final String id;
  final MediaItem mediaItem;
  final String addedByUserId;
  final String addedByName;
  final DateTime addedAt;
  final int upvotes;
  final int downvotes;
  final List<String> upvoterIds;
  final List<String> downvoterIds;
  final bool isPlayed;

  const JamQueueItem({
    required this.id,
    required this.mediaItem,
    required this.addedByUserId,
    required this.addedByName,
    required this.addedAt,
    this.upvotes = 0,
    this.downvotes = 0,
    this.upvoterIds = const [],
    this.downvoterIds = const [],
    this.isPlayed = false,
  });

  /// Net score (upvotes - downvotes)
  int get score => upvotes - downvotes;

  JamQueueItem copyWith({
    String? id,
    MediaItem? mediaItem,
    String? addedByUserId,
    String? addedByName,
    DateTime? addedAt,
    int? upvotes,
    int? downvotes,
    List<String>? upvoterIds,
    List<String>? downvoterIds,
    bool? isPlayed,
  }) {
    return JamQueueItem(
      id: id ?? this.id,
      mediaItem: mediaItem ?? this.mediaItem,
      addedByUserId: addedByUserId ?? this.addedByUserId,
      addedByName: addedByName ?? this.addedByName,
      addedAt: addedAt ?? this.addedAt,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      upvoterIds: upvoterIds ?? this.upvoterIds,
      downvoterIds: downvoterIds ?? this.downvoterIds,
      isPlayed: isPlayed ?? this.isPlayed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mediaItemId': mediaItem.id,
      'addedByUserId': addedByUserId,
      'addedByName': addedByName,
      'addedAt': addedAt.toIso8601String(),
      'upvotes': upvotes,
      'downvotes': downvotes,
      'upvoterIds': upvoterIds,
      'downvoterIds': downvoterIds,
      'isPlayed': isPlayed,
    };
  }

  factory JamQueueItem.fromJson(Map<String, dynamic> json) {
    return JamQueueItem(
      id: json['id'] as String,
      mediaItem: MediaItem(
        id: json['mediaItemId'] as String,
        title: json['title'] as String? ?? '',
      ),
      addedByUserId: json['addedByUserId'] as String,
      addedByName: json['addedByName'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      upvoterIds: List<String>.from(json['upvoterIds'] ?? []),
      downvoterIds: List<String>.from(json['downvoterIds'] ?? []),
      isPlayed: json['isPlayed'] as bool? ?? false,
    );
  }
}

/// Chat message in a Jam Session
class JamChatMessage {
  final String id;
  final String oderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String message;
  final DateTime sentAt;
  final JamChatMessageType type;

  const JamChatMessage({
    required this.id,
    required this.oderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.message,
    required this.sentAt,
    this.type = JamChatMessageType.text,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'oderId': oderId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'message': message,
      'sentAt': sentAt.toIso8601String(),
      'type': type.value,
    };
  }

  factory JamChatMessage.fromJson(Map<String, dynamic> json) {
    return JamChatMessage(
      id: json['id'] as String,
      oderId: json['oderId'] as String,
      senderName: json['senderName'] as String,
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      message: json['message'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      type: JamChatMessageType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => JamChatMessageType.text,
      ),
    );
  }
}

/// Type of chat message
enum JamChatMessageType {
  text('text'),
  songRequest('song_request'),
  reaction('reaction'),
  system('system');

  final String value;
  const JamChatMessageType(this.value);
}
