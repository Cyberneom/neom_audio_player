import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/constants/app_firestore_collection_constants.dart';

import '../../domain/models/jam_session.dart';
import '../../utils/enums/jam_session_type.dart';

/// Firestore CRUD operations for Jam Sessions
class JamSessionFirestore {

  final _collection = FirebaseFirestore.instance
      .collection(AppFirestoreCollectionConstants.jamSessions);

  /// Create a new session
  Future<String> createSession(JamSession session) async {
    AppConfig.logger.d('Creating jam session: ${session.name}');
    try {
      if (session.id.isNotEmpty) {
        await _collection.doc(session.id).set(session.toJson());
        return session.id;
      } else {
        final doc = await _collection.add(session.toJson());
        return doc.id;
      }
    } catch (e) {
      AppConfig.logger.e('Error creating jam session: $e');
      return '';
    }
  }

  /// Get session by ID
  Future<JamSession?> getSession(String sessionId) async {
    try {
      final doc = await _collection.doc(sessionId).get();
      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['id'] = doc.id;
        return JamSession.fromJson(data);
      }
    } catch (e) {
      AppConfig.logger.e('Error getting session: $e');
    }
    return null;
  }

  /// Get session by join code
  Future<JamSession?> getSessionByCode(String code) async {
    try {
      final query = await _collection
          .where('joinCode', isEqualTo: code)
          .where('status', isEqualTo: JamSessionStatus.active.value)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return JamSession.fromJson(data);
      }
    } catch (e) {
      AppConfig.logger.e('Error getting session by code: $e');
    }
    return null;
  }

  /// Update session
  Future<void> updateSession(JamSession session) async {
    try {
      await _collection.doc(session.id).update(session.toJson());
    } catch (e) {
      AppConfig.logger.e('Error updating session: $e');
    }
  }

  /// Delete session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _collection.doc(sessionId).delete();
    } catch (e) {
      AppConfig.logger.e('Error deleting session: $e');
    }
  }

  /// Get active sessions (for discovery)
  Future<List<JamSession>> getActiveSessions({
    int limit = 20,
    String? genre,
  }) async {
    try {
      Query query = _collection
          .where('status', isEqualTo: JamSessionStatus.active.value)
          .where('type', isEqualTo: JamSessionType.open.value)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return JamSession.fromJson(data);
      }).toList();
    } catch (e) {
      AppConfig.logger.e('Error getting active sessions: $e');
      return [];
    }
  }

  /// Get sessions by host
  Future<List<JamSession>> getSessionsByHost(String hostId, {int limit = 20}) async {
    try {
      final snapshot = await _collection
          .where('hostId', isEqualTo: hostId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return JamSession.fromJson(data);
      }).toList();
    } catch (e) {
      AppConfig.logger.e('Error getting sessions by host: $e');
      return [];
    }
  }

  /// Real-time session stream
  Stream<JamSession?> sessionStream(String sessionId) {
    return _collection.doc(sessionId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['id'] = doc.id;
        return JamSession.fromJson(data);
      }
      return null;
    });
  }

  /// Add chat message to subcollection
  Future<void> addChatMessage(String sessionId, JamChatMessage message) async {
    try {
      await _collection
          .doc(sessionId)
          .collection('chat')
          .add(message.toJson());
    } catch (e) {
      AppConfig.logger.e('Error adding chat message: $e');
    }
  }

  /// Stream chat messages
  Stream<List<JamChatMessage>> chatStream(String sessionId) {
    return _collection
        .doc(sessionId)
        .collection('chat')
        .orderBy('sentAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return JamChatMessage.fromJson(data);
      }).toList();
    });
  }

  /// Get recent chat messages (non-realtime)
  Future<List<JamChatMessage>> getRecentMessages(String sessionId, {int limit = 50}) async {
    try {
      final snapshot = await _collection
          .doc(sessionId)
          .collection('chat')
          .orderBy('sentAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return JamChatMessage.fromJson(data);
      }).toList().reversed.toList();
    } catch (e) {
      AppConfig.logger.e('Error getting recent messages: $e');
      return [];
    }
  }
}
