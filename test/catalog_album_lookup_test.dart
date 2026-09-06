// Test doubles capture the Firestore query contract without a Firebase app.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/ui/web/utils/catalog_album_lookup.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';

class _Firestore extends Fake implements FirebaseFirestore {
  final paths = <String>[];
  final _Collection result;
  _Firestore({bool fail = false}) : result = _Collection(fail: fail);
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    paths.add(path);
    return result;
  }
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final filters = <String, Object?>{};
  final bool fail;
  _Collection({this.fail = false});
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #where) {
      filters[invocation.positionalArguments.single as String] =
          invocation.namedArguments[#isEqualTo];
      return this;
    }
    if (invocation.memberName == #get) {
      if (fail) {
        return Future<QuerySnapshot<Map<String, dynamic>>>.error(
          StateError('Permission denied'),
        );
      }
      return Future<QuerySnapshot<Map<String, dynamic>>>.value(_Snapshot());
    }
    return super.noSuchMethod(invocation);
  }
}

class _Snapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => [
    _Doc('public-song', 'public', 1),
    _Doc('private-song', 'private', 1),
    _Doc('unsupported-schema', 'public', 2),
  ];
}

class _Doc extends Fake implements QueryDocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final String visibility;
  final int version;
  _Doc(this.id, this.visibility, this.version);
  @override
  Map<String, dynamic> data() => {
    'visibility': visibility,
    'schemaVersion': version,
    'name': id,
    'mediaType': 'song',
    'status': 'publish',
    'type': 'single',
    'previewUrl': 'https://audio.example/song.mp3',
    'ownerName': 'Artist',
  };
}

void main() {
  final previousApp = AppConfig.instance.appInUse;
  final previousGuest = AppConfig.instance.isGuestMode;
  setUp(() {
    AppConfig.instance.appInUse = AppInUse.g;
    AppConfig.instance.isGuestMode = true;
  });
  tearDown(() {
    AppConfig.instance.appInUse = previousApp;
    AppConfig.instance.isGuestMode = previousGuest;
  });

  test('guest album lookup queries only public, versioned releases', () async {
    final firestore = _Firestore();
    final items = await loadCatalogAlbumItems(
      albumId: 'album-id',
      albumName: 'Album',
      firestore: firestore,
    );
    expect(firestore.paths, ['publicAppReleaseItems']);
    expect(firestore.result.filters, {
      'visibility': 'public',
      'schemaVersion': 1,
      'metaId': 'album-id',
    });
    expect(items.map((item) => item.id), ['public-song']);
  });

  test(
    'name fallback remains scoped and never falls back to legacy after denial',
    () async {
      final firestore = _Firestore(fail: true);
      await expectLater(
        loadCatalogAlbumItems(
          albumId: '',
          albumName: 'Album',
          firestore: firestore,
        ),
        throwsStateError,
      );
      expect(firestore.paths, ['publicAppReleaseItems']);
      expect(firestore.result.filters['metaName'], 'Album');
    },
  );

  test(
    'missing album metadata does not initialize Firebase or query the catalogue',
    () async {
      expect(await loadCatalogAlbumItems(albumId: ' ', albumName: ''), isEmpty);
    },
  );
}
