import 'package:audio_service/audio_service.dart';

import '../../utils/enums/jam_session_type.dart';

const int _maxSafeEpochMs = 8640000000000000;
final RegExp _unsafeJamTextChars = RegExp(
  r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F\u0085\u061C\u200B\u200C\u200E\u200F\u2028\u2029\u202A-\u202E\u2060-\u2069\uFEFF]',
);
final RegExp _unsafeJamIdChars = RegExp(
  r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028\u2029\u202A-\u202E\u2060-\u2069\uFEFF]',
);
final RegExp _encodedJamBidi = RegExp(
  r'%(?:c2%[89][0-9a-f]|e2%80%(?:8[b-f]|a[8-e])|e2%81%a[0-9]|d8%9c|ef%bb%bf)',
  caseSensitive: false,
);
final RegExp _idnJamDots = RegExp(r'[\u3002\uFF0E\uFF61]');
final RegExp _jamSvgExt = RegExp(
  r'\.svgz?(?:$|[?#])',
  caseSensitive: false,
);
final RegExp _jamPairedBrackets = RegExp(
  r'\[\s*(BIOCHIP|MEMORY_RECALL|AUTO_MEMORY|SYSTEM_CONTEXT)\b[^\]]*\](?:(?!\[\s*/?\s*\1\b)[\s\S])*?\[\s*/\s*\1\b[^\]]*\]',
  caseSensitive: false,
);
final RegExp _jamLlmArtifacts = RegExp(
  r'<\|(?:channel|turn)>\s*thought\b[\s\S]*?(?:<(?:channel|turn)\|>|$)|<\|tool_call>[\s\S]*?(?:<tool_call\|>|$)|<think>[\s\S]*?(?:</think>|$)|<\|/?(?:turn|channel|tool_call|eot)\|?>?|<(?:turn|channel|tool_call)\|>|<\s*/?\s*(?:think|thought|memory_recall|auto_memory|system_context)\b[^>]*>|\[\s*/?\s*(?:MEMORY_RECALL|AUTO_MEMORY|SYSTEM_CONTEXT|BIOCHIP)\b[^\]]*\]',
  caseSensitive: false,
);
final RegExp _jamClosingContentTag = RegExp(
  r'</\s*content\s*>',
  caseSensitive: false,
);
final RegExp _jamDangerousMediaIdScheme = RegExp(
  r'^\s*(?:javascript|vbscript|data|file|blob|ms-msdt|search-ms)\s*:',
  caseSensitive: false,
);

String _sliceJamSafe(String s, int maxChars) {
  if (maxChars <= 0 || s.isEmpty) return '';
  if (s.length <= maxChars) return s;
  var end = maxChars;
  final cu = s.codeUnitAt(end - 1);
  if (cu >= 0xD800 && cu <= 0xDBFF) end--;
  return end <= 0 ? '' : s.substring(0, end);
}

bool _isReservedJamKey(String lower) =>
    lower == '__proto__' ||
    lower == 'constructor' ||
    lower == 'prototype' ||
    (lower.startsWith('__') && lower.endsWith('__'));

String _cleanJamId(dynamic raw, {int maxChars = 128}) {
  if (raw == null) return '';
  final rawStr = raw.toString();
  if (_unsafeJamIdChars.hasMatch(rawStr) || _encodedJamBidi.hasMatch(rawStr)) {
    return '';
  }
  final cleaned = rawStr.trim();
  if (cleaned.isEmpty ||
      cleaned == '.' ||
      cleaned == '..' ||
      cleaned.contains('..') ||
      cleaned.contains('/') ||
      cleaned.contains(r'\') ||
      cleaned.contains(':')) {
    return '';
  }
  final lower = cleaned.toLowerCase();
  if (_isReservedJamKey(lower) ||
      lower.contains('%00') ||
      lower.contains('%2e') ||
      lower.contains('%2f') ||
      lower.contains('%5c') ||
      lower.contains('%25')) {
    return '';
  }
  return _sliceJamSafe(cleaned, maxChars);
}

String _cleanJamMediaId(dynamic raw, {int maxChars = 1024}) {
  if (raw == null) return '';
  final rawStr = raw.toString();
  if (_unsafeJamIdChars.hasMatch(rawStr) || _encodedJamBidi.hasMatch(rawStr)) {
    return '';
  }
  final cleaned = rawStr.trim();
  if (cleaned.isEmpty || _jamDangerousMediaIdScheme.hasMatch(cleaned)) {
    return '';
  }
  final lower = cleaned.toLowerCase();
  if (cleaned == '.' ||
      cleaned == '..' ||
      cleaned.contains('..') ||
      _isReservedJamKey(lower) ||
      lower.contains('%00') ||
      lower.contains('%2e') ||
      lower.contains('%5c') ||
      lower.contains('%25')) {
    return '';
  }
  if (cleaned.contains('://')) {
    return _cleanJamUrl(cleaned);
  }
  return _sliceJamSafe(cleaned, maxChars);
}

String _cleanJamText(dynamic raw, {int maxChars = 512}) {
  if (raw == null) return '';
  final cleaned = raw
      .toString()
      .replaceAll(_jamPairedBrackets, ' ')
      .replaceAll(_jamLlmArtifacts, ' ')
      .replaceAll(_jamClosingContentTag, '[content_end]')
      .replaceAll(_unsafeJamTextChars, '')
      .trim();
  return _sliceJamSafe(cleaned, maxChars);
}

bool _isPrivateJamIpv4(int a, int b, int c, int d) {
  if (a == 0 || a == 10 || a == 127) return true;
  if (a == 169 && b == 254) return true;
  if (a == 172 && b >= 16 && b <= 31) return true;
  if (a == 192 && b == 168) return true;
  if (a == 100 && b >= 64 && b <= 127) return true;
  if (a == 198 && (b == 18 || b == 19)) return true;
  if (a >= 224) return true;
  return false;
}

String _cleanJamUrl(dynamic raw, {bool rasterImageOnly = false}) {
  if (raw == null) return '';
  final rawStr = raw.toString();
  if (_unsafeJamIdChars.hasMatch(rawStr) ||
      _idnJamDots.hasMatch(rawStr) ||
      _encodedJamBidi.hasMatch(rawStr)) {
    return '';
  }
  final candidate = _sliceJamSafe(rawStr.trim(), 2048);
  if (candidate.isEmpty ||
      candidate.contains(r'\') ||
      (rasterImageOnly && _jamSvgExt.hasMatch(candidate))) {
    return '';
  }
  final lower = candidate.toLowerCase();
  if (lower.contains('%00') ||
      lower.contains('%5c') ||
      lower.contains('%2e') ||
      lower.contains('%25') ||
      lower.contains('/..')) {
    return '';
  }
  final uri = Uri.tryParse(candidate);
  if (uri == null ||
      !uri.hasAuthority ||
      uri.userInfo.isNotEmpty ||
      uri.pathSegments.any((s) => s == '..') ||
      (rasterImageOnly && _jamSvgExt.hasMatch(uri.path))) {
    return '';
  }
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'https' && scheme != 'http') return '';
  var host = uri.host.toLowerCase().trim();
  if (host.startsWith('[') && host.endsWith(']')) {
    host = host.substring(1, host.length - 1);
  }
  while (host.endsWith('.')) {
    host = host.substring(0, host.length - 1);
  }
  if (host.isEmpty ||
      host.contains('%') ||
      host == 'null' ||
      host == 'localhost' ||
      host.endsWith('.localhost') ||
      host.endsWith('.local') ||
      host.endsWith('.internal') ||
      host.endsWith('.lan') ||
      host.endsWith('.corp') ||
      host.endsWith('.home.arpa') ||
      host.endsWith('.invalid') ||
      host.endsWith('.ts.net') ||
      host.endsWith('.onion') ||
      host == 'metadata' ||
      host == 'instance-data' ||
      host == 'metadata.goog' ||
      host.endsWith('.metadata.goog') ||
      host == 'metadata.google.internal' ||
      host.endsWith('.metadata.google.internal') ||
      host == 'metadata.azure.com' ||
      host.endsWith('.metadata.azure.com') ||
      host == 'metadata.azure.internal' ||
      host.endsWith('.metadata.azure.internal') ||
      (!host.contains(':') && !host.contains('.'))) {
    return '';
  }
  if (host.contains(':')) {
    if (host == '::' ||
        host == '::1' ||
        host.startsWith('fc') ||
        host.startsWith('fd') ||
        host.startsWith('fe8') ||
        host.startsWith('fe9') ||
        host.startsWith('fea') ||
        host.startsWith('feb') ||
        host.startsWith('ff') ||
        host.startsWith('::ffff:')) {
      return '';
    }
    return candidate;
  }
  final parts = host.split('.');
  final allNumericLike = parts.every(
    (p) => RegExp(r'^(?:0x[0-9a-f]+|\d+)$').hasMatch(p),
  );
  if (allNumericLike) {
    if (parts.length != 4) return '';
    final octets = <int>[];
    for (final p in parts) {
      if (p.startsWith('0x') || (p.length > 1 && p.startsWith('0'))) return '';
      final v = int.tryParse(p);
      if (v == null || v < 0 || v > 255) return '';
      octets.add(v);
    }
    if (_isPrivateJamIpv4(octets[0], octets[1], octets[2], octets[3])) {
      return '';
    }
  }
  return candidate;
}

String? _cleanNullableJamUrl(dynamic raw, {bool rasterImageOnly = true}) {
  if (raw == null) return null;
  final cleaned = _cleanJamUrl(raw, rasterImageOnly: rasterImageOnly);
  return cleaned.isEmpty ? null : cleaned;
}

int _parseJamInt(dynamic v, int fallback) {
  if (v is num) {
    if (!v.isFinite) return fallback;
    return v is int ? v : v.toInt();
  }
  if (v is String) {
    final t = v.trim();
    final asInt = int.tryParse(t);
    if (asInt != null) return asInt;
    final asDouble = double.tryParse(t);
    if (asDouble != null && asDouble.isFinite) return asDouble.toInt();
  }
  return fallback;
}

bool _parseJamBool(dynamic v, bool fallback) {
  if (v is bool) return v;
  if (v is String) {
    final lower = v.trim().toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  if (v is num && v.isFinite) return v != 0;
  return fallback;
}

DateTime? _tryParseJamDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is num && raw.isFinite) {
    final ms = raw.toInt();
    if (ms > 0 && ms <= _maxSafeEpochMs) {
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
  }
  return DateTime.tryParse(raw.toString().trim());
}

DateTime _parseJamDate(dynamic raw) => _tryParseJamDate(raw) ?? DateTime.now();

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
    if (queue.isEmpty || currentIndex < 0 || currentIndex >= queue.length) {
      return null;
    }
    return queue[currentIndex];
  }

  /// Get upcoming songs
  List<JamQueueItem> get upcomingItems {
    if (queue.isEmpty || currentIndex < 0) return [];
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
  String get shareUrl => 'neom://jam/${Uri.encodeComponent(_cleanJamId(joinCode, maxChars: 64))}';

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
      'playbackPositionMs': playbackPositionMs < 0 ? 0 : playbackPositionMs,
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
    final rawParticipants = json['participants'];
    final participants = <JamParticipant>[];
    if (rawParticipants is Iterable) {
      for (final p in rawParticipants.take(500)) {
        if (p is Map) {
          participants.add(
            JamParticipant.fromJson(Map<String, dynamic>.from(p)),
          );
        }
      }
    }
    final rawQueue = json['queue'];
    final queue = <JamQueueItem>[];
    if (rawQueue is Iterable) {
      for (final q in rawQueue.take(1000)) {
        if (q is Map) {
          queue.add(JamQueueItem.fromJson(Map<String, dynamic>.from(q)));
        }
      }
    }
    return JamSession(
      id: _cleanJamId(json['id']),
      name: _cleanJamText(json['name'], maxChars: 256),
      description: _cleanJamText(json['description'], maxChars: 2048),
      imageUrl: _cleanJamUrl(json['imageUrl'], rasterImageOnly: true),
      type: JamSessionType.values.firstWhere(
        (e) => e.value == json['type']?.toString().trim(),
        orElse: () => JamSessionType.open,
      ),
      status: JamSessionStatus.values.firstWhere(
        (e) => e.value == json['status']?.toString().trim(),
        orElse: () => JamSessionStatus.creating,
      ),
      hostId: _cleanJamId(json['hostId']),
      hostName: _cleanJamText(json['hostName'], maxChars: 256),
      joinCode: _cleanJamId(json['joinCode'], maxChars: 64),
      participants: participants,
      queue: queue,
      currentIndex: _parseJamInt(json['currentIndex'], 0),
      playbackPositionMs:
          _parseJamInt(json['playbackPositionMs'], 0).clamp(0, _maxSafeEpochMs),
      isPlaying: _parseJamBool(json['isPlaying'], false),
      createdAt: _parseJamDate(json['createdAt']),
      startedAt: _tryParseJamDate(json['startedAt']),
      endedAt: _tryParseJamDate(json['endedAt']),
      maxParticipants: _parseJamInt(json['maxParticipants'], 50).clamp(1, 10000),
      allowRequests: _parseJamBool(json['allowRequests'], true),
      allowVoting: _parseJamBool(json['allowVoting'], true),
      superVotesPerUser: _parseJamInt(json['superVotesPerUser'], 3).clamp(0, 100),
      autoSkipThreshold: _parseJamInt(json['autoSkipThreshold'], -5),
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
      oderId: _cleanJamId(json['oderId']),
      displayName: _cleanJamText(json['displayName'], maxChars: 256),
      avatarUrl: _cleanNullableJamUrl(json['avatarUrl']),
      role: JamParticipantRole.values.firstWhere(
        (e) => e.value == json['role']?.toString().trim(),
        orElse: () => JamParticipantRole.listener,
      ),
      joinedAt: _parseJamDate(json['joinedAt']),
      isConnected: _parseJamBool(json['isConnected'], true),
      songsAdded: _parseJamInt(json['songsAdded'], 0).clamp(0, 1000000),
      superVotesRemaining:
          _parseJamInt(json['superVotesRemaining'], 3).clamp(0, 1000),
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
      'title': mediaItem.title,
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

  static List<String> _cleanIdList(dynamic raw) {
    if (raw is! Iterable) return const [];
    final out = <String>[];
    for (final item in raw.take(1000)) {
      final id = _cleanJamId(item);
      if (id.isNotEmpty) out.add(id);
    }
    return out;
  }

  factory JamQueueItem.fromJson(Map<String, dynamic> json) {
    return JamQueueItem(
      id: _cleanJamId(json['id']),
      mediaItem: MediaItem(
        id: _cleanJamMediaId(json['mediaItemId']),
        title: _cleanJamText(json['title']),
      ),
      addedByUserId: _cleanJamId(json['addedByUserId']),
      addedByName: _cleanJamText(json['addedByName'], maxChars: 256),
      addedAt: _parseJamDate(json['addedAt']),
      upvotes: _parseJamInt(json['upvotes'], 0).clamp(0, 10000000),
      downvotes: _parseJamInt(json['downvotes'], 0).clamp(0, 10000000),
      upvoterIds: _cleanIdList(json['upvoterIds']),
      downvoterIds: _cleanIdList(json['downvoterIds']),
      isPlayed: _parseJamBool(json['isPlayed'], false),
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
      id: _cleanJamId(json['id']),
      oderId: _cleanJamId(json['oderId']),
      senderName: _cleanJamText(json['senderName'], maxChars: 256),
      senderAvatarUrl: _cleanNullableJamUrl(json['senderAvatarUrl']),
      message: _cleanJamText(json['message'], maxChars: 2048),
      sentAt: _parseJamDate(json['sentAt']),
      type: JamChatMessageType.values.firstWhere(
        (e) => e.value == json['type']?.toString().trim(),
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
