import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:sint/sint.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/jam_session.dart';
import '../../domain/use_cases/jam_session_service.dart';
import '../../utils/enums/jam_session_type.dart';
import '../firestore/jam_session_firestore.dart';

/// Controller implementation for Jam Session (collaborative listening)
class JamSessionController extends SintController implements JamSessionService {
  final _session = Rxn<JamSession>();
  final _sessionStreamController = StreamController<JamSession?>.broadcast();
  final _chatStreamController = StreamController<JamChatMessage>.broadcast();
  final _isLoading = false.obs;
  final _syncDelayMs = 0.obs;

  final _uuid = const Uuid();
  final _random = Random();
  final _jamFirestore = JamSessionFirestore();
  StreamSubscription? _sessionStreamSub;
  StreamSubscription? _chatStreamSub;

  // Current user info (would come from auth service)
  String? _currentUserId;
  String? _currentUserName;

  /// Set current user info
  void setCurrentUser(String userId, String userName) {
    _currentUserId = userId;
    _currentUserName = userName;
  }

  @override
  Stream<JamSession?> get sessionStream => _sessionStreamController.stream;

  @override
  Stream<JamChatMessage> get chatStream => _chatStreamController.stream;

  @override
  JamSession? get currentSession => _session.value;

  @override
  bool get isInSession => _session.value != null;

  @override
  JamParticipantRole? get currentUserRole {
    if (_session.value == null || _currentUserId == null) return null;
    final participant = _session.value!.participants.firstWhereOrNull(
      (p) => p.oderId == _currentUserId,
    );
    return participant?.role;
  }

  @override
  List<JamParticipant> get participants => _session.value?.participants ?? [];

  @override
  int get syncDelayMs => _syncDelayMs.value;

  bool get isLoading => _isLoading.value;

  // ============ Session Lifecycle ============

  @override
  Future<JamSession> createSession({
    required String name,
    String? description,
    String? imageUrl,
    JamSessionType type = JamSessionType.open,
    int maxParticipants = 50,
    bool allowRequests = true,
    bool allowVoting = true,
  }) async {
    _isLoading.value = true;

    try {
      final joinCode = _generateJoinCode();

      final hostParticipant = JamParticipant(
        oderId: _currentUserId ?? 'unknown',
        displayName: _currentUserName ?? 'Host',
        role: JamParticipantRole.host,
        joinedAt: DateTime.now(),
      );

      final session = JamSession(
        id: _uuid.v4(),
        name: name,
        description: description ?? '',
        imageUrl: imageUrl ?? '',
        type: type,
        status: JamSessionStatus.active,
        hostId: _currentUserId ?? 'unknown',
        hostName: _currentUserName ?? 'Host',
        joinCode: joinCode,
        participants: [hostParticipant],
        createdAt: DateTime.now(),
        maxParticipants: maxParticipants,
        allowRequests: allowRequests,
        allowVoting: allowVoting,
      );

      // Persist to Firestore
      final sessionId = await _jamFirestore.createSession(session);
      final persistedSession = session.copyWith(id: sessionId.isNotEmpty ? sessionId : session.id);

      _session.value = persistedSession;
      _sessionStreamController.add(persistedSession);
      _startSessionListener(persistedSession.id);

      return persistedSession;
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Future<JamSession> joinSession(String joinCode) async {
    _isLoading.value = true;

    try {
      // In production, this would fetch from server
      final session = await _fetchSessionByCode(joinCode);

      if (session == null) {
        throw Exception('Session not found');
      }

      if (session.isFull) {
        throw Exception('Session is full');
      }

      final participant = JamParticipant(
        oderId: _currentUserId ?? 'unknown',
        displayName: _currentUserName ?? 'Guest',
        role: JamParticipantRole.listener,
        joinedAt: DateTime.now(),
      );

      final updatedSession = session.copyWith(
        participants: [...session.participants, participant],
      );

      _session.value = updatedSession;
      _sessionStreamController.add(updatedSession);

      await _syncSessionToServer(updatedSession);
      _startSessionListener(updatedSession.id);
      await syncPlayback();

      // Send join message
      await _sendSystemMessage('$_currentUserName joined the session');

      return updatedSession;
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Future<JamSession> joinSessionById(String sessionId) async {
    _isLoading.value = true;

    try {
      final session = await _fetchSessionById(sessionId);

      if (session == null) {
        throw Exception('Session not found');
      }

      return joinSession(session.joinCode);
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Future<void> leaveSession() async {
    if (_session.value == null) return;

    final isHost = currentUserRole == JamParticipantRole.host;

    if (isHost && _session.value!.participants.length > 1) {
      // Transfer host to next co-host or oldest participant
      final nextHost = _session.value!.participants.firstWhereOrNull(
            (p) => p.role == JamParticipantRole.coHost && p.oderId != _currentUserId,
          ) ??
          _session.value!.participants.firstWhereOrNull(
            (p) => p.oderId != _currentUserId,
          );

      if (nextHost != null) {
        await transferHost(nextHost.oderId);
      }
    }

    final updatedParticipants = _session.value!.participants
        .where((p) => p.oderId != _currentUserId)
        .toList();

    if (updatedParticipants.isEmpty) {
      await endSession();
    } else {
      final updatedSession = _session.value!.copyWith(
        participants: updatedParticipants,
      );

      await _syncSessionToServer(updatedSession);
      await _sendSystemMessage('$_currentUserName left the session');
    }

    _session.value = null;
    _sessionStreamController.add(null);
  }

  @override
  Future<void> endSession() async {
    if (_session.value == null) return;

    _validateHostPermission();

    final endedSession = _session.value!.copyWith(
      status: JamSessionStatus.ended,
      endedAt: DateTime.now(),
    );

    await _syncSessionToServer(endedSession);
    await _sendSystemMessage('Session ended by host');

    _session.value = null;
    _sessionStreamController.add(null);
  }

  // ============ Playback Control ============

  @override
  Future<void> play() async {
    _validatePlaybackPermission();

    final updatedSession = _session.value!.copyWith(
      isPlaying: true,
      startedAt: _session.value!.startedAt ?? DateTime.now(),
    );

    _session.value = updatedSession;
    _sessionStreamController.add(updatedSession);
    await _syncSessionToServer(updatedSession);
  }

  @override
  Future<void> pause() async {
    _validatePlaybackPermission();

    final updatedSession = _session.value!.copyWith(isPlaying: false);

    _session.value = updatedSession;
    _sessionStreamController.add(updatedSession);
    await _syncSessionToServer(updatedSession);
  }

  @override
  Future<void> skipNext() async {
    _validatePlaybackPermission();

    if (_session.value!.currentIndex >= _session.value!.queue.length - 1) {
      return;
    }

    final updatedSession = _session.value!.copyWith(
      currentIndex: _session.value!.currentIndex + 1,
      playbackPositionMs: 0,
    );

    _session.value = updatedSession;
    _sessionStreamController.add(updatedSession);
    await _syncSessionToServer(updatedSession);
  }

  @override
  Future<void> skipPrevious() async {
    _validatePlaybackPermission();

    if (_session.value!.currentIndex <= 0) return;

    final updatedSession = _session.value!.copyWith(
      currentIndex: _session.value!.currentIndex - 1,
      playbackPositionMs: 0,
    );

    _session.value = updatedSession;
    _sessionStreamController.add(updatedSession);
    await _syncSessionToServer(updatedSession);
  }

  @override
  Future<void> seekTo(Duration position) async {
    _validatePlaybackPermission();

    final updatedSession = _session.value!.copyWith(
      playbackPositionMs: position.inMilliseconds,
    );

    _session.value = updatedSession;
    _sessionStreamController.add(updatedSession);
    await _syncSessionToServer(updatedSession);
  }

  @override
  Future<void> jumpToQueueItem(int index) async {
    _validatePlaybackPermission();

    if (index < 0 || index >= _session.value!.queue.length) return;

    final updatedSession = _session.value!.copyWith(
      currentIndex: index,
      playbackPositionMs: 0,
    );

    _session.value = updatedSession;
    _sessionStreamController.add(updatedSession);
    await _syncSessionToServer(updatedSession);
  }

  // ============ Queue Management ============

  @override
  Future<void> addToQueue(MediaItem mediaItem) async {
    if (_session.value == null) return;

    if (!_session.value!.allowRequests && currentUserRole == JamParticipantRole.listener) {
      throw Exception('Requests are not allowed in this session');
    }

    final queueItem = JamQueueItem(
      id: _uuid.v4(),
      mediaItem: mediaItem,
      addedByUserId: _currentUserId ?? 'unknown',
      addedByName: _currentUserName ?? 'Unknown',
      addedAt: DateTime.now(),
    );

    final updatedSession = _session.value!.copyWith(
      queue: [..._session.value!.queue, queueItem],
    );

    _session.value = updatedSession;
    _sessionStreamController.add(updatedSession);
    await _syncSessionToServer(updatedSession);

    await _sendSystemMessage(
      '$_currentUserName added "${mediaItem.title}" to the queue',
    );
  }

  @override
  Future<void> addMultipleToQueue(List<MediaItem> mediaItems) async {
    for (final item in mediaItems) {
      await addToQueue(item);
    }
  }

  @override
  Future<void> removeFromQueue(String queueItemId) async {
    _validateQueueModifyPermission();

    final updatedQueue = _session.value!.queue
        .where((q) => q.id != queueItemId)
        .toList();

    final updatedSession = _session.value!.copyWith(queue: updatedQueue);

    _session.value = updatedSession;
    _sessionStreamController.add(updatedSession);
    await _syncSessionToServer(updatedSession);
  }

  @override
  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    _validateQueueModifyPermission();

    final queue = List<JamQueueItem>.from(_session.value!.queue);
    final item = queue.removeAt(oldIndex);
    queue.insert(newIndex, item);

    final updatedSession = _session.value!.copyWith(queue: queue);

    _session.value = updatedSession;
    _sessionStreamController.add(updatedSession);
    await _syncSessionToServer(updatedSession);
  }

  @override
  Future<void> clearQueue() async {
    _validateQueueModifyPermission();

    final currentItem = _session.value!.currentItem;
    final updatedQueue = currentItem != null ? [currentItem] : <JamQueueItem>[];

    final updatedSession = _session.value!.copyWith(
      queue: updatedQueue,
      currentIndex: 0,
    );

    _session.value = updatedSession;
    _sessionStreamController.add(updatedSession);
    await _syncSessionToServer(updatedSession);
  }

  // ============ Voting ============

  @override
  Future<void> upvote(String queueItemId) async {
    await _vote(queueItemId, JamVoteType.upvote);
  }

  @override
  Future<void> downvote(String queueItemId) async {
    await _vote(queueItemId, JamVoteType.downvote);
  }

  @override
  Future<void> superVote(String queueItemId) async {
    final participant = _session.value!.participants.firstWhereOrNull(
      (p) => p.oderId == _currentUserId,
    );

    if (participant == null || participant.superVotesRemaining <= 0) {
      throw Exception('No super votes remaining');
    }

    await _vote(queueItemId, JamVoteType.superVote);

    // Decrease super votes
    final updatedParticipants = _session.value!.participants.map((p) {
      if (p.oderId == _currentUserId) {
        return p.copyWith(superVotesRemaining: p.superVotesRemaining - 1);
      }
      return p;
    }).toList();

    final updatedSession = _session.value!.copyWith(
      participants: updatedParticipants,
    );

    _session.value = updatedSession;
    _sessionStreamController.add(updatedSession);
    await _syncSessionToServer(updatedSession);
  }

  @override
  Future<void> removeVote(String queueItemId) async {
    final queueIndex = _session.value!.queue.indexWhere((q) => q.id == queueItemId);
    if (queueIndex == -1) return;

    final item = _session.value!.queue[queueIndex];

    final updatedUpvoters = item.upvoterIds.where((id) => id != _currentUserId).toList();
    final updatedDownvoters = item.downvoterIds.where((id) => id != _currentUserId).toList();

    final updatedItem = item.copyWith(
      upvotes: updatedUpvoters.length,
      downvotes: updatedDownvoters.length,
      upvoterIds: updatedUpvoters,
      downvoterIds: updatedDownvoters,
    );

    final updatedQueue = List<JamQueueItem>.from(_session.value!.queue);
    updatedQueue[queueIndex] = updatedItem;

    final updatedSession = _session.value!.copyWith(queue: updatedQueue);

    _session.value = updatedSession;
    _sessionStreamController.add(updatedSession);
    await _syncSessionToServer(updatedSession);
  }

  Future<void> _vote(String queueItemId, JamVoteType voteType) async {
    if (_session.value == null || !_session.value!.allowVoting) {
      throw Exception('Voting is not allowed in this session');
    }

    final queueIndex = _session.value!.queue.indexWhere((q) => q.id == queueItemId);
    if (queueIndex == -1) return;

    final item = _session.value!.queue[queueIndex];

    // Remove any existing vote
    var upvoters = item.upvoterIds.where((id) => id != _currentUserId).toList();
    var downvoters = item.downvoterIds.where((id) => id != _currentUserId).toList();

    // Add new vote
    if (voteType == JamVoteType.upvote || voteType == JamVoteType.superVote) {
      upvoters = [...upvoters, _currentUserId!];
    } else if (voteType == JamVoteType.downvote) {
      downvoters = [...downvoters, _currentUserId!];
    }

    final votes = voteType == JamVoteType.superVote ? 3 : 1;
    final updatedItem = item.copyWith(
      upvotes: upvoters.length + (voteType == JamVoteType.superVote ? 2 : 0),
      downvotes: downvoters.length,
      upvoterIds: upvoters,
      downvoterIds: downvoters,
    );

    final updatedQueue = List<JamQueueItem>.from(_session.value!.queue);
    updatedQueue[queueIndex] = updatedItem;

    // Check for auto-skip
    if (updatedItem.score <= _session.value!.autoSkipThreshold) {
      updatedQueue.removeAt(queueIndex);
    }

    final updatedSession = _session.value!.copyWith(queue: updatedQueue);

    _session.value = updatedSession;
    _sessionStreamController.add(updatedSession);
    await _syncSessionToServer(updatedSession);
  }

  // ============ Participant Management ============

  @override
  Future<void> kickParticipant(String oderId) async {
    _validateHostPermission();

    final updatedParticipants = _session.value!.participants
        .where((p) => p.oderId != oderId)
        .toList();

    final updatedSession = _session.value!.copyWith(
      participants: updatedParticipants,
    );

    _session.value = updatedSession;
    _sessionStreamController.add(updatedSession);
    await _syncSessionToServer(updatedSession);

    await _sendSystemMessage('A participant was removed from the session');
  }

  @override
  Future<void> promoteToCoHost(String oderId) async {
    await _changeParticipantRole(oderId, JamParticipantRole.coHost);
  }

  @override
  Future<void> promoteToDJ(String oderId) async {
    await _changeParticipantRole(oderId, JamParticipantRole.dj);
  }

  @override
  Future<void> demoteToListener(String oderId) async {
    _validateHostPermission();
    await _changeParticipantRole(oderId, JamParticipantRole.listener);
  }

  @override
  Future<void> transferHost(String oderId) async {
    _validateHostPermission();

    final updatedParticipants = _session.value!.participants.map((p) {
      if (p.oderId == _currentUserId) {
        return p.copyWith(role: JamParticipantRole.coHost);
      }
      if (p.oderId == oderId) {
        return p.copyWith(role: JamParticipantRole.host);
      }
      return p;
    }).toList();

    final newHost = updatedParticipants.firstWhere((p) => p.oderId == oderId);

    final updatedSession = _session.value!.copyWith(
      hostId: oderId,
      hostName: newHost.displayName,
      participants: updatedParticipants,
    );

    _session.value = updatedSession;
    _sessionStreamController.add(updatedSession);
    await _syncSessionToServer(updatedSession);

    await _sendSystemMessage('${newHost.displayName} is now the host');
  }

  Future<void> _changeParticipantRole(String oderId, JamParticipantRole newRole) async {
    if (currentUserRole != JamParticipantRole.host &&
        currentUserRole != JamParticipantRole.coHost) {
      throw Exception('Not authorized');
    }

    final updatedParticipants = _session.value!.participants.map((p) {
      if (p.oderId == oderId) {
        return p.copyWith(role: newRole);
      }
      return p;
    }).toList();

    final updatedSession = _session.value!.copyWith(
      participants: updatedParticipants,
    );

    _session.value = updatedSession;
    _sessionStreamController.add(updatedSession);
    await _syncSessionToServer(updatedSession);
  }

  // ============ Chat ============

  @override
  Future<void> sendMessage(String message) async {
    final chatMessage = JamChatMessage(
      id: _uuid.v4(),
      oderId: _currentUserId ?? 'unknown',
      senderName: _currentUserName ?? 'Unknown',
      message: message,
      sentAt: DateTime.now(),
    );

    _chatStreamController.add(chatMessage);
    await _syncChatMessage(chatMessage);
  }

  @override
  Future<void> sendReaction(String emoji) async {
    final chatMessage = JamChatMessage(
      id: _uuid.v4(),
      oderId: _currentUserId ?? 'unknown',
      senderName: _currentUserName ?? 'Unknown',
      message: emoji,
      sentAt: DateTime.now(),
      type: JamChatMessageType.reaction,
    );

    _chatStreamController.add(chatMessage);
    await _syncChatMessage(chatMessage);
  }

  @override
  Future<List<JamChatMessage>> getRecentMessages({int limit = 50}) async {
    final sessionId = _session.value?.id;
    if (sessionId == null) return [];
    return _jamFirestore.getRecentMessages(sessionId, limit: limit);
  }

  Future<void> _sendSystemMessage(String message) async {
    final chatMessage = JamChatMessage(
      id: _uuid.v4(),
      oderId: 'system',
      senderName: 'System',
      message: message,
      sentAt: DateTime.now(),
      type: JamChatMessageType.system,
    );

    _chatStreamController.add(chatMessage);
  }

  // ============ Session Settings ============

  @override
  Future<void> updateSettings({
    String? name,
    String? description,
    String? imageUrl,
    JamSessionType? type,
    int? maxParticipants,
    bool? allowRequests,
    bool? allowVoting,
  }) async {
    _validateHostPermission();

    final updatedSession = _session.value!.copyWith(
      name: name,
      description: description,
      imageUrl: imageUrl,
      type: type,
      maxParticipants: maxParticipants,
      allowRequests: allowRequests,
      allowVoting: allowVoting,
    );

    _session.value = updatedSession;
    _sessionStreamController.add(updatedSession);
    await _syncSessionToServer(updatedSession);
  }

  @override
  Future<String> regenerateJoinCode() async {
    _validateHostPermission();

    final newCode = _generateJoinCode();
    final updatedSession = _session.value!.copyWith(joinCode: newCode);

    _session.value = updatedSession;
    _sessionStreamController.add(updatedSession);
    await _syncSessionToServer(updatedSession);

    return newCode;
  }

  // ============ Discovery ============

  @override
  Future<List<JamSession>> discoverSessions({
    int limit = 20,
    String? genre,
    bool? hasOpenSlots,
  }) async {
    final sessions = await _jamFirestore.getActiveSessions(limit: limit, genre: genre);
    if (hasOpenSlots == true) {
      return sessions.where((s) => !s.isFull).toList();
    }
    return sessions;
  }

  @override
  Future<List<JamSession>> getFriendsSessions() async {
    // Query all active sessions and filter by participants containing friends
    // For now, return all open sessions as a starting point
    return _jamFirestore.getActiveSessions(limit: 10);
  }

  @override
  Future<List<JamSession>> getSessionHistory({int limit = 20}) async {
    if (_currentUserId == null) return [];
    return _jamFirestore.getSessionsByHost(_currentUserId!, limit: limit);
  }

  // ============ Sync ============

  @override
  Future<void> syncPlayback() async {
    final session = _session.value;
    if (session == null) return;

    // Refresh session state from Firestore
    final latest = await _jamFirestore.getSession(session.id);
    if (latest != null) {
      _session.value = latest;
      _sessionStreamController.add(latest);

      // Calculate sync delay based on playback position difference
      final positionDiff = (latest.playbackPositionMs - session.playbackPositionMs).abs();
      _syncDelayMs.value = positionDiff;
    }
  }

  // ============ Private Helpers ============

  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[_random.nextInt(chars.length)]).join();
  }

  void _validateHostPermission() {
    if (currentUserRole != JamParticipantRole.host) {
      throw Exception('Only the host can perform this action');
    }
  }

  void _validatePlaybackPermission() {
    if (_session.value == null) {
      throw Exception('Not in a session');
    }
    if (!currentUserRole!.canControlPlayback) {
      throw Exception('Not authorized to control playback');
    }
  }

  void _validateQueueModifyPermission() {
    if (_session.value == null) {
      throw Exception('Not in a session');
    }
    if (!currentUserRole!.canRemoveSongs) {
      throw Exception('Not authorized to modify queue');
    }
  }

  // Server sync
  Future<void> _syncSessionToServer(JamSession session) async {
    await _jamFirestore.updateSession(session);
  }

  Future<void> _syncChatMessage(JamChatMessage message) async {
    final sessionId = _session.value?.id;
    if (sessionId == null) return;
    await _jamFirestore.addChatMessage(sessionId, message);
  }

  Future<JamSession?> _fetchSessionByCode(String code) async {
    return _jamFirestore.getSessionByCode(code);
  }

  Future<JamSession?> _fetchSessionById(String id) async {
    return _jamFirestore.getSession(id);
  }

  /// Start listening to real-time session updates
  void _startSessionListener(String sessionId) {
    _sessionStreamSub?.cancel();
    _sessionStreamSub = _jamFirestore.sessionStream(sessionId).listen((session) {
      if (session != null) {
        _session.value = session;
        _sessionStreamController.add(session);
      }
    });

    _chatStreamSub?.cancel();
    _chatStreamSub = _jamFirestore.chatStream(sessionId).listen((messages) {
      for (final msg in messages) {
        _chatStreamController.add(msg);
      }
    });
  }

  @override
  void onClose() {
    _sessionStreamSub?.cancel();
    _chatStreamSub?.cancel();
    _sessionStreamController.close();
    _chatStreamController.close();
    super.onClose();
  }
}
