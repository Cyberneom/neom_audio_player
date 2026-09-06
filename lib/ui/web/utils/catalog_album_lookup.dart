import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neom_core/data/firestore/constants/app_firestore_collection_constants.dart';
import 'package:neom_core/data/firestore/public_catalog_read_policy.dart';
import 'package:neom_core/domain/model/app_release_item.dart';

/// Album lookup follows the same public projection boundary as the catalogue.
Future<List<AppReleaseItem>> loadCatalogAlbumItems({
  required String albumId,
  required String albumName,
  FirebaseFirestore? firestore,
}) async {
  final id = albumId.trim();
  final name = albumName.trim();
  if (id.isEmpty && name.isEmpty) return [];

  final collection = PublicCatalogReadPolicy.collection(
    firestore ?? FirebaseFirestore.instance,
    AppFirestoreCollectionConstants.appReleaseItems,
  );
  final query = PublicCatalogReadPolicy.query(collection).where(
    id.isNotEmpty ? 'metaId' : 'metaName',
    isEqualTo: id.isNotEmpty ? id : name,
  );
  final snapshot = await query.get();
  return snapshot.docs
      .where((doc) => PublicCatalogReadPolicy.accepts(doc.data()))
      .map((doc) {
        final item = AppReleaseItem.fromJSON(doc.data())..id = doc.id;
        return PublicCatalogReadPolicy.enabled
            ? item.toPublicProjection()
            : item;
      })
      .toList();
}
