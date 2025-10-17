import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/constants/app_firestore_collection_constants.dart';

import '../../domain/models/casete/casete_session.dart';

class CaseteSessionFirestore {

  final caseteSessionsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.caseteSessions);
  final authorsCaseteSessionsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.authorsCaseteSessions);

  Future<String> insert(CaseteSession session, {bool isAuthor = false}) async {
    AppConfig.logger.d("Inserting session ${session.id}");

    try {
      CollectionReference sessionReference = isAuthor ? authorsCaseteSessionsReference : caseteSessionsReference;

      if(session.id.isNotEmpty) {
        await sessionReference.doc(session.id).set(session.toJSON());
      } else {
        DocumentReference documentReference = await sessionReference.add(session.toJSON());
        session.id = documentReference.id;
      }
      AppConfig.logger.d("CaseteSession for ${session.itemName} was added with id ${session.id}");
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return session.id;

  }

  Future<bool> remove(CaseteSession session) async {
    AppConfig.logger.d("Removing product ${session.id}");

    try {
      await caseteSessionsReference.doc(session.id).delete();
      AppConfig.logger.d("session ${session.id} was removed");
      return true;

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }

  Future<CaseteSession> retrieveSession(String orderId) async {
    AppConfig.logger.d("Retrieving session for id $orderId");
    CaseteSession session = CaseteSession();

    try {

      DocumentSnapshot documentSnapshot = await caseteSessionsReference.doc(orderId).get();

      if (documentSnapshot.exists) {
        AppConfig.logger.d("Snapshot is not empty");
          session = CaseteSession.fromJSON(documentSnapshot.data());
          session.id = documentSnapshot.id;
          AppConfig.logger.d(session.toString());
        AppConfig.logger.d("session ${session.id} was retrieved");
      } else {
        AppConfig.logger.w("session ${session.id} was not found");
      }

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return session;
  }

  Future<Map<String, CaseteSession>> retrieveFromList(List<String> sessionIds) async {
    AppConfig.logger.d("Getting sessions from list");

    Map<String, CaseteSession> sessions = {};

    try {
      QuerySnapshot querySnapshot = await caseteSessionsReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.d("QuerySnapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          if(sessionIds.contains(documentSnapshot.id)){
            CaseteSession session = CaseteSession.fromJSON(documentSnapshot.data());
            session.id = documentSnapshot.id;
            AppConfig.logger.d("session ${session.id} was retrieved with details");
            sessions[session.id] = session;
          }
        }
      }

      AppConfig.logger.d("${sessions.length} sessions were retrieved");
    } catch (e) {
      AppConfig.logger.e(e);
    }
    return sessions;
  }

}
