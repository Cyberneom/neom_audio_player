import 'package:audio_service/audio_service.dart';
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/playable_item.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/app_media_source.dart';

class MediaItemMapper  {

  static Map toJSON(MediaItem item) {
    return {
      'id': item.id,
      'name': item.title,
      'description': item.extras?['description'],
      'ownerName': item.artist.toString(),
      'ownerId': item.extras?['ownerId'],
      'album': item.album.toString(),
      'duration': item.duration?.inSeconds.toString(),

      'categories': [item.genre.toString()],
      'hasLyrics': item.extras!['hasLyrics'],
      'language': item.extras?['language'].toString(),

      'imgUrl': item.artUri?.path,

      'publishedYear': int.tryParse((item.extras?['publishedYear'] ?? '0').toString()),
      'releaseDate': int.tryParse((item.extras?['createdTime'] ?? '0').toString()),

      'url': item.extras!['url'].toString(),
      'permaUrl': item.extras!['permaUrl']?.toString(),
      'quality': item.extras?['quality'],
      'is320kbps': item.extras?['is320kbps'],
    };
  }

  static MediaItem fromJSON(
    Map song, {
    bool addedByAutoplay = false,
    bool autoplay = true,
    String? playlistBox,
  }) {
    final idVal = song['id']?.toString() ?? '';
    final titleVal = song['title']?.toString().trim() ?? '';
    final albumVal = song['album']?.toString().trim() ?? '';
    final artistVal = (song['ownerName'] ?? song['artist'])?.toString().trim() ?? '';
    final durationVal = song['duration']?.toString().trim() ?? '';

    return MediaItem(
      id: idVal,
      album: (albumVal.isEmpty || albumVal == 'null') ? '' : albumVal,
      artist: (artistVal.isEmpty || artistVal == 'null') ? '' : artistVal,
      duration: Duration(
        seconds: int.parse(
          (durationVal.isEmpty || durationVal == 'null') ? '180' : durationVal,
        ),
      ),
      title: (titleVal.isEmpty || titleVal == 'null') ? 'Lanzamiento' : titleVal,
      artUri: Uri.parse(song['image']?.toString() ?? ''),
      genre: song['language']?.toString() ?? '',
      extras: {
        'ownerId': song['ownerId'] ?? '',
        'url': song['url'],
        'slug': song['slug'] ?? '',
        'publishedYear': song['publishedYear'],
        'language': song['language'],
        'is320Kbps': song['is320Kbps'],
        'quality': song['quality'],
        'lyrics': song['lyrics'],
        'createdTime': song['createdTime'],
        'metaId': song['metaId'],
        'description': song['description'],
        'addedByAutoplay': addedByAutoplay,
        'autoplay': autoplay,
        'playlistBox': playlistBox,
        'source': song['source'],
      },
    );
  }

  static MediaItem fromAppMediaItem({required AppMediaItem item,
    bool addedByAutoplay = false, bool autoplay = true, String? playlistBox,
  }) {
    final nameVal = item.name.trim();
    final artistVal = item.ownerName.trim();
    final albumVal = item.album.trim();

    return MediaItem(
      id: item.id,
      album: (albumVal.isEmpty || albumVal == 'null') ? '' : albumVal,
      artist: (artistVal.isEmpty || artistVal == 'null') ? '' : artistVal,
      duration: Duration(seconds: item.duration),
      title: (nameVal.isEmpty || nameVal == 'null') ? 'Lanzamiento' : nameVal,
      artUri: Uri.parse(item.imgUrl),
      genre: item.categories?.isNotEmpty ?? false ? item.categories?.first : null,
      extras: {
        'ownerId': item.ownerId,
        'url': item.url,
        'slug': item.slug,
        'publishedYear': item.publishedYear,
        'language': item.language,
        'is320Kbps': item.is320Kbps,
        'lyrics': item.lyrics,
        'createdTime': item.releaseDate,
        'metaId': item.albumId,
        'subtitle': item.name,
        'addedByAutoplay': addedByAutoplay,
        'autoplay': autoplay,
        'playlistBox': playlistBox,
        'source': item.mediaSource.name,
        'description': item.description,
      },
    );
  }

  static AppMediaItem toAppMediaItem(MediaItem item) {
    final titleVal = item.title.trim();
    final artistVal = item.artist?.trim() ?? '';
    final albumVal = item.album?.trim() ?? '';

    final nameVal = TextUtilities.getMediaName((titleVal.isEmpty || titleVal == 'null') ? 'Lanzamiento' : titleVal);

    return AppMediaItem(
      id: item.id,
      album: (albumVal.isEmpty || albumVal == 'null') ? '' : albumVal,
      albumId: item.extras?['metaId']?.toString() ?? '',
      ownerName: (artistVal.isEmpty || artistVal == 'null') ? TextUtilities.getArtistName(titleVal) : artistVal,
      duration: item.duration?.inSeconds ?? 0,
      name: (nameVal.isEmpty || nameVal == 'null') ? 'Lanzamiento' : nameVal,
      imgUrl: item.artUri?.toString() ?? '',
      categories: item.genre != null ? [item.genre!] : [],
      url: item.extras?['url']?.toString() ?? '',
      description: item.extras?['description']?.toString() ?? '',
      lyrics: item.extras?['lyrics']?.toString() ?? '',
      ownerId: item.extras?['ownerId']?.toString() ?? '',
      mediaSource: CoreUtilities.isInternal(item.extras?['url']?.toString() ?? '') ? AppMediaSource.internal : AppMediaSource.external,
    );
  }

  static MediaItem fromAppReleaseItem({required AppReleaseItem item,
    bool addedByAutoplay = false, bool autoplay = true, String? playlistBox,
  }) {
    final nameVal = item.name.trim();
    final artistVal = item.ownerName.trim();
    final albumVal = item.metaName?.trim() ?? '';

    return MediaItem(
      id: item.id,
      album: (albumVal.isEmpty || albumVal == 'null') ? '' : albumVal,
      artist: (artistVal.isEmpty || artistVal == 'null') ? '' : artistVal,
      duration: Duration(seconds: item.duration),
      title: (nameVal.isEmpty || nameVal == 'null') ? 'Lanzamiento' : nameVal,
      artUri: Uri.parse(item.imgUrl),
      genre: item.categories.isNotEmpty ? item.categories.first : null,
      extras: {
        'url': item.previewUrl,
        'allUrl': [],
        'publishedYear': item.publishedYear,
        'language': item.language,
        'is320Kbps': true,
        'quality': 0,
        'lyrics': item.lyrics ?? '',
        'createdTime': item.createdTime,
        'metaId': item.metaId,
        'description': item.description,
        'addedByAutoplay': addedByAutoplay,
        'autoplay': autoplay,
        'playlistBox': playlistBox,
        'source': AppMediaSource.internal,
        'ownerEmail': item.ownerEmail,
      },
    );
  }

  /// Unified method: accepts any PlayableItem (AppReleaseItem or AppMediaItem).
  /// Delegates to the specific mapper based on runtime type.
  static MediaItem fromPlayableItem({required PlayableItem item,
    bool addedByAutoplay = false, bool autoplay = true, String? playlistBox,
  }) {
    if (item is AppReleaseItem) {
      return fromAppReleaseItem(item: item, addedByAutoplay: addedByAutoplay,
          autoplay: autoplay, playlistBox: playlistBox);
    } else if (item is AppMediaItem) {
      return fromAppMediaItem(item: item, addedByAutoplay: addedByAutoplay,
          autoplay: autoplay, playlistBox: playlistBox);
    }
    // Fallback using interface fields
    return MediaItem(
      id: item.id,
      artist: item.ownerName,
      duration: Duration(seconds: item.duration),
      title: item.name,
      artUri: Uri.parse(item.imgUrl),
      genre: (item.categories?.isNotEmpty ?? false) ? item.categories!.first : null,
      extras: {
        'url': item.streamUrl,
        'publishedYear': item.publishedYear,
        'language': item.language,
        'description': item.description,
        'addedByAutoplay': addedByAutoplay,
        'autoplay': autoplay,
        'playlistBox': playlistBox,
        'source': item.isInternal ? AppMediaSource.internal.name : AppMediaSource.external.name,
      },
    );
  }

}
