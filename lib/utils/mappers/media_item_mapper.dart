import 'package:audio_service/audio_service.dart';
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/app_media_source.dart';

class MediaItemMapper  {

  static Map toJSON(MediaItem item) {
    return {
      'id': item.id,
      'album': item.album.toString(),
      'metaId': item.extras?['metaId'],
      'artist': item.artist.toString(),
      'duration': item.duration?.inSeconds.toString(),
      'genre': item.genre.toString(),
      'hasLyrics': item.extras!['hasLyrics'],
      'image': item.artUri.toString(),
      'language': item.extras?['language'].toString(),
      'createdTime': item.extras?['createdTime'],
      'subtitle': item.extras?['subtitle'],
      'title': item.title,
      'url': item.extras!['url'].toString(),
      'lowUrl': item.extras!['lowUrl']?.toString(),
      'highUrl': item.extras!['highUrl']?.toString(),
      'publishedYear': item.extras?['publishedYear'].toString(),
      '320kbps': item.extras?['320kbps'],
      'quality': item.extras?['quality'],
      'expire_at': item.extras?['expire_at'],
    };
  }

  static MediaItem fromJSON(
    Map song, {
    bool addedByAutoplay = false,
    bool autoplay = true,
    String? playlistBox,
  }) {
    return MediaItem(
      id: song['id'].toString(),
      album: song['album'].toString(),
      artist: song['artist'].toString(),
      duration: Duration(
        seconds: int.parse(
          (song['duration'] == null ||
              song['duration'] == 'null' ||
              song['duration'] == '')
              ? '180' : song['duration'].toString(),
        ),
      ),
      title: song['title'].toString(),
      artUri: Uri.parse(song['image'].toString()),
      genre: song['language'].toString(),
      extras: {
        'url': song['url'],
        'lowUrl': song['lowUrl'],
        'highUrl': song['highUrl'],
        'publishedYear': song['publishedYear'],
        'language': song['language'],
        '320kbps': song['320kbps'],
        'quality': song['quality'],
        'hasLyrics': song['hasLyrics'],
        'createdTime': song['createdTime'],
        'metaId': song['metaId'],
        'subtitle': song['subtitle'],
        'expire_at': song['expire_at'],
        'addedByAutoplay': addedByAutoplay,
        'autoplay': autoplay,
        'playlistBox': playlistBox,
      },
    );
  }

  static MediaItem fromAppMediaItem({required AppMediaItem item,
    bool addedByAutoplay = false, bool autoplay = true, String? playlistBox,
  }) {
    return MediaItem(
      id: item.id,
      album: item.album,
      artist: item.ownerName,
      duration: Duration(seconds: item.duration),
      title: item.name,
      artUri: Uri.parse(item.imgUrl),
      genre: item.categories?.isNotEmpty ?? false ? item.categories?.first : null,
      extras: {
        'url': item.url,
        'allUrl': [],
        'publishedYear': item.publishedYear,
        'language': item.language,
        '320kbps': item.is320Kbps,
        'quality': 0,
        'hasLyrics': item.lyrics.isNotEmpty,
        'createdTime': item.releaseDate,
        'metaId': item.albumId,
        'subtitle': item.name,
        'addedByAutoplay': addedByAutoplay,
        'autoplay': autoplay,
        'playlistBox': playlistBox,
        'source': item.mediaSource.name,
        'description': item.description,
        'lyrics': item.lyrics,
        'ownerEmail': item.ownerId,
      },
    );
  }

  static AppMediaItem toAppMediaItem(MediaItem item) {
    return AppMediaItem(
      id: item.id,
      album: item.album ?? '',
      ownerName: item.artist ?? TextUtilities.getArtistName(item.title),
      duration: item.duration?.inSeconds ?? 0,
      name: TextUtilities.getMediaName(item.title),
      imgUrl: item.artUri?.toString() ?? '',
      categories: item.genre != null ? [item.genre!] : [],
      url: item.extras?['url'].toString() ?? '',
      description: item.extras?['description'].toString() ?? '',
      lyrics: item.extras?['lyrics'].toString() ?? '',
      ownerId: item.extras?['ownerEmail'].toString() ?? '',
      mediaSource: CoreUtilities.isInternal(item.extras?['url'].toString() ?? '') ? AppMediaSource.internal : AppMediaSource.external,
    );
  }

  static MediaItem fromAppReleaseItem({required AppReleaseItem item,
    bool addedByAutoplay = false, bool autoplay = true, String? playlistBox,
  }) {
    return MediaItem(
      id: item.id,
      album: item.metaName,
      artist: item.ownerName,
      duration: Duration(seconds: item.duration),
      title: item.name,
      artUri: Uri.parse(item.imgUrl),
      genre: item.categories.isNotEmpty ? item.categories.first : null,
      extras: {
        'url': item.previewUrl,
        'allUrl': [],
        'publishedYear': item.publishedYear,
        'language': item.language,
        '320kbps': true,
        'quality': 0,
        'hasLyrics': item.lyrics?.isNotEmpty,
        'createdTime': item.createdTime,
        'metaId': item.metaId,
        'subtitle': item.name,
        'addedByAutoplay': addedByAutoplay,
        'autoplay': autoplay,
        'playlistBox': playlistBox,
        'source': AppMediaSource.internal,
        'description': item.description,
        'lyrics': item.lyrics,
        'ownerEmail': item.ownerEmail,
      },
    );
  }

}
