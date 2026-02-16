import 'package:audio_service/audio_service.dart';

import '../models/jam_session.dart';
import '../../utils/enums/jam_session_type.dart';

/// Abstract service for Jam Session (collaborative listening) management
abstract class JamSessionService {
  /// Stream of current session updates
  Stream<JamSession?> get sessionStream;

  /// Stream of chat messages
  Stream<JamChatMessage> get chatStream;

  /// Current session (null if not in a session)
  JamSession? get currentSession;

  /// Whether user is currently in a session
  bool get isInSession;

  /// Current user's role in the session
  JamParticipantRole? get currentUserRole;

  // ============ Session Lifecycle ============

  /// Create a new Jam session
  Future<JamSession> createSession({
    required String name,
    String? description,
    String? imageUrl,
    JamSessionType type = JamSessionType.open,
    int maxParticipants = 50,
    bool allowRequests = true,
    bool allowVoting = true,
  });

  /// Join an existing session by code
  Future<JamSession> joinSession(String joinCode);

  /// Join an existing session by ID
  Future<JamSession> joinSessionById(String sessionId);

  /// Leave the current session
  Future<void> leaveSession();

  /// End the session (host only)
  Future<void> endSession();

  // ============ Playback Control ============

  /// Play/Resume playback (host/co-host only)
  Future<void> play();

  /// Pause playback (host/co-host only)
  Future<void> pause();

  /// Skip to next song (host/co-host only)
  Future<void> skipNext();

  /// Skip to previous song (host/co-host only)
  Future<void> skipPrevious();

  /// Seek to position (host/co-host only)
  Future<void> seekTo(Duration position);

  /// Jump to specific queue item (host/co-host only)
  Future<void> jumpToQueueItem(int index);

  // ============ Queue Management ============

  /// Add a song to the queue
  Future<void> addToQueue(MediaItem mediaItem);

  /// Add multiple songs to the queue
  Future<void> addMultipleToQueue(List<MediaItem> mediaItems);

  /// Remove a song from the queue (host/co-host only)
  Future<void> removeFromQueue(String queueItemId);

  /// Reorder queue item (host/co-host only)
  Future<void> reorderQueue(int oldIndex, int newIndex);

  /// Clear upcoming queue (host/co-host only)
  Future<void> clearQueue();

  // ============ Voting ============

  /// Upvote a song in the queue
  Future<void> upvote(String queueItemId);

  /// Downvote a song in the queue
  Future<void> downvote(String queueItemId);

  /// Use super vote on a song
  Future<void> superVote(String queueItemId);

  /// Remove vote from a song
  Future<void> removeVote(String queueItemId);

  // ============ Participant Management ============

  /// Get all participants
  List<JamParticipant> get participants;

  /// Kick a participant (host only)
  Future<void> kickParticipant(String oderId);

  /// Promote participant to co-host (host only)
  Future<void> promoteToCoHost(String oderId);

  /// Promote participant to DJ (host/co-host only)
  Future<void> promoteToDJ(String oderId);

  /// Demote participant to listener (host only)
  Future<void> demoteToListener(String oderId);

  /// Transfer host role (host only)
  Future<void> transferHost(String oderId);

  // ============ Chat ============

  /// Send a chat message
  Future<void> sendMessage(String message);

  /// Send a reaction (emoji)
  Future<void> sendReaction(String emoji);

  /// Get recent chat messages
  Future<List<JamChatMessage>> getRecentMessages({int limit = 50});

  // ============ Session Settings ============

  /// Update session settings (host only)
  Future<void> updateSettings({
    String? name,
    String? description,
    String? imageUrl,
    JamSessionType? type,
    int? maxParticipants,
    bool? allowRequests,
    bool? allowVoting,
  });

  /// Generate new join code (host only)
  Future<String> regenerateJoinCode();

  // ============ Discovery ============

  /// Get public/open sessions nearby or popular
  Future<List<JamSession>> discoverSessions({
    int limit = 20,
    String? genre,
    bool? hasOpenSlots,
  });

  /// Get sessions from friends
  Future<List<JamSession>> getFriendsSessions();

  /// Get user's session history
  Future<List<JamSession>> getSessionHistory({int limit = 20});

  // ============ Sync ============

  /// Force sync playback position with host
  Future<void> syncPlayback();

  /// Get current sync delay in milliseconds
  int get syncDelayMs;
}

/// Configuration for creating a Jam session
class JamSessionConfig {
  final String name;
  final String? description;
  final String? imageUrl;
  final JamSessionType type;
  final int maxParticipants;
  final bool allowRequests;
  final bool allowVoting;
  final int superVotesPerUser;
  final int autoSkipThreshold;
  final bool enableChat;
  final bool enableReactions;
  final List<String>? initialPlaylistIds;
  final List<MediaItem>? initialQueue;

  const JamSessionConfig({
    required this.name,
    this.description,
    this.imageUrl,
    this.type = JamSessionType.open,
    this.maxParticipants = 50,
    this.allowRequests = true,
    this.allowVoting = true,
    this.superVotesPerUser = 3,
    this.autoSkipThreshold = -5,
    this.enableChat = true,
    this.enableReactions = true,
    this.initialPlaylistIds,
    this.initialQueue,
  });
}

/// Events that can occur in a Jam session
enum JamSessionEvent {
  /// Session created
  created,

  /// User joined
  userJoined,

  /// User left
  userLeft,

  /// Playback started
  playbackStarted,

  /// Playback paused
  playbackPaused,

  /// Song changed
  songChanged,

  /// Song added to queue
  songAdded,

  /// Song removed from queue
  songRemoved,

  /// Vote received
  voteReceived,

  /// Chat message received
  messageReceived,

  /// Settings changed
  settingsChanged,

  /// Session ended
  sessionEnded,

  /// User promoted
  userPromoted,

  /// User demoted
  userDemoted,

  /// User kicked
  userKicked,

  /// Sync required
  syncRequired,
}
