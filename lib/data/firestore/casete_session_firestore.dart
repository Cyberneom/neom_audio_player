import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neom_commons/core/data/firestore/constants/app_firestore_collection_constants.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';

import '../../domain/entities/casete_session.dart';

class CaseteSessionFirestore {

  final caseteSessionsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.caseteSessions);
  final authorsCaseteSessionsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.authorsCaseteSessions);

  @override
  Future<String> insert(CaseteSession session, {bool isAuthor = false}) async {
    AppUtilities.logger.d("Inserting session ${session.id}");

    try {

      CollectionReference sessionReference = isAuthor ? authorsCaseteSessionsReference : caseteSessionsReference;

      if(session.id.isNotEmpty) {
        await sessionReference.doc(session.id).set(session.toJSON());
      } else {
        DocumentReference documentReference = await sessionReference.add(session.toJSON());
        session.id = documentReference.id;
      }
      AppUtilities.logger.d("CaseteSession for ${session.itemName} was added with id ${session.id}");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return session.id;

  }


  @override
  Future<bool> remove(CaseteSession session) async {
    AppUtilities.logger.d("Removing product ${session.id}");

    try {
      await caseteSessionsReference.doc(session.id).delete();
      AppUtilities.logger.d("session ${session.id} was removed");
      return true;

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<CaseteSession> retrieveSession(String orderId) async {
    AppUtilities.logger.d("Retrieving session for id $orderId");
    CaseteSession session = CaseteSession();

    try {

      DocumentSnapshot documentSnapshot = await caseteSessionsReference.doc(orderId).get();

      if (documentSnapshot.exists) {
        AppUtilities.logger.d("Snapshot is not empty");
          session = CaseteSession.fromJSON(documentSnapshot.data());
          session.id = documentSnapshot.id;
          AppUtilities.logger.d(session.toString());
        AppUtilities.logger.d("session ${session.id} was retrieved");
      } else {
        AppUtilities.logger.w("session ${session.id} was not found");
      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return session;
  }


  @override
  Future<Map<String, CaseteSession>> retrieveFromList(List<String> sessionIds) async {
    AppUtilities.logger.d("Getting sessions from list");

    Map<String, CaseteSession> sessions = {};

    try {
      QuerySnapshot querySnapshot = await caseteSessionsReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppUtilities.logger.d("QuerySnapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          if(sessionIds.contains(documentSnapshot.id)){
            CaseteSession session = CaseteSession.fromJSON(documentSnapshot.data());
            session.id = documentSnapshot.id;
            AppUtilities.logger.d("session ${session.id} was retrieved with details");
            sessions[session.id] = session;
          }
        }
      }

      AppUtilities.logger.d("${sessions.length} sessions were retrieved");
    } catch (e) {
      AppUtilities.logger.e(e);
    }
    return sessions;
  }

}
