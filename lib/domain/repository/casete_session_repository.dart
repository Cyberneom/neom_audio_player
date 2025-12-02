import '../models/casete/casete_session.dart';

abstract class CaseteSessionRepository {

  Future<String> insert(CaseteSession session);
  Future<bool> remove(String sessionId);
  Future<Map<String, CaseteSession>> retrieveFromList(List<String> sessionIds);
  Future<CaseteSession> retrieveSession(String orderId);
  Future<Map<String, CaseteSession>> fetchAll({String? itemId, bool skipTest = true});

}
