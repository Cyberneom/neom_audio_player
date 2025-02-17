import 'package:audio_service/audio_service.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/enums/app_media_source.dart';
import '../audio_player_utilities.dart';

class MediaItemMapper  {

  static Map toJSON(MediaItem mediaItem) {
    return {
      'id': mediaItem.id,
      'album': mediaItem.album.toString(),
      'album_id': mediaItem.extras?['album_id'],
      'artist': mediaItem.artist.toString(),
      'duration': mediaItem.duration?.inSeconds.toString(),
      'genre': mediaItem.genre.toString(),
      'has_lyrics': mediaItem.extras!['has_lyrics'],
      'image': mediaItem.artUri.toString(),
      'language': mediaItem.extras?['language'].toString(),
      'release_date': mediaItem.extras?['release_date'],
      'subtitle': mediaItem.extras?['subtitle'],
      'title': mediaItem.title,
      'url': mediaItem.extras!['url'].toString(),
      'lowUrl': mediaItem.extras!['lowUrl']?.toString(),
      'highUrl': mediaItem.extras!['highUrl']?.toString(),
      'year': mediaItem.extras?['year'].toString(),
      '320kbps': mediaItem.extras?['320kbps'],
      'quality': mediaItem.extras?['quality'],
      'perma_url': mediaItem.extras?['perma_url'],
      'expire_at': mediaItem.extras?['expire_at'],
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
        'year': song['year'],
        'language': song['language'],
        '320kbps': song['320kbps'],
        'quality': song['quality'],
        'has_lyrics': song['has_lyrics'],
        'release_date': song['release_date'],
        'album_id': song['album_id'],
        'subtitle': song['subtitle'],
        'perma_url': song['perma_url'],
        'expire_at': song['expire_at'],
        'addedByAutoplay': addedByAutoplay,
        'autoplay': autoplay,
        'playlistBox': playlistBox,
      },
    );
  }

  ///NOT IN USE - 0125
  // static MediaItem downMapToMediaItem(Map song) {
  //   return MediaItem(
  //     id: song['id'].toString(),
  //     album: song['album'].toString(),
  //     artist: song['artist'].toString(),
  //     duration: Duration(
  //       seconds: int.parse(
  //         (song['duration'] == null ||
  //                 song['duration'] == 'null' ||
  //                 song['duration'] == '')
  //             ? '180'
  //             : song['duration'].toString(),
  //       ),
  //     ),
  //     title: song['title'].toString(),
  //     artUri: Uri.file(song['image'].toString()),
  //     genre: song['genre'].toString(),
  //     extras: {
  //       'url': song['path'].toString(),
  //       'year': song['year'],
  //       'language': song['genre'],
  //       'release_date': song['release_date'],
  //       'album_id': song['album_id'],
  //       'subtitle': song['subtitle'],
  //       'quality': song['quality'],
  //     },
  //   );
  // }

  ///DEPRECATED
  // static MediaItem songItemToMediaItem({
  //   required AppMediaItem appMediaItem,
  //   bool addedByAutoplay = false,
  //   bool autoplay = true,
  //   String? playlistBox,
  // }) {
  //   return MediaItem(
  //     id: appMediaItem.id,
  //     album: appMediaItem.album,
  //     artist: '${appMediaItem.artist} ${appMediaItem.externalArtists?.join(', ')}',
  //     duration: Duration(seconds: appMediaItem.duration),
  //     title: appMediaItem.name,
  //     artUri: Uri.parse(appMediaItem.imgUrl),
  //     genre: appMediaItem.genres?.first,
  //     extras: {
  //       'url': appMediaItem.url,
  //       'allUrl': appMediaItem.allUrls,
  //       'year': appMediaItem.publishedYear,
  //       'language': appMediaItem.language,
  //       '320kbps': appMediaItem.is320Kbps,
  //       'quality': appMediaItem.quality,
  //       'has_lyrics': appMediaItem.lyrics.isNotEmpty,
  //       'release_date': appMediaItem.releaseDate,
  //       'album_id': appMediaItem.albumId,
  //       'subtitle': appMediaItem.name,
  //       'perma_url': appMediaItem.permaUrl,
  //       'expire_at': appMediaItem.expireAt,
  //       'addedByAutoplay': addedByAutoplay,
  //       'autoplay': autoplay,
  //       'playlistBox': playlistBox,
  //     },
  //   );
  // }

  static MediaItem appMediaItemToMediaItem({required AppMediaItem appMediaItem,
    bool addedByAutoplay = false, bool autoplay = true, String? playlistBox,
  }) {
    return MediaItem(
      id: appMediaItem.id,
      album: appMediaItem.album,
      artist: appMediaItem.artist,
      duration: Duration(seconds: appMediaItem.duration),
      title: appMediaItem.name,
      artUri: Uri.parse(appMediaItem.imgUrl),
      genre: appMediaItem.genres?.isNotEmpty ?? false ? appMediaItem.genres?.first : null,
      extras: {
        'url': appMediaItem.url,
        'allUrl': [],
        'year': appMediaItem.publishedYear,
        'language': appMediaItem.language,
        '320kbps': appMediaItem.is320Kbps,
        'quality': 0,
        'has_lyrics': appMediaItem.lyrics.isNotEmpty,
        'release_date': appMediaItem.releaseDate,
        'album_id': appMediaItem.albumId,
        'subtitle': appMediaItem.name,
        'perma_url': appMediaItem.permaUrl,
        'addedByAutoplay': addedByAutoplay,
        'autoplay': autoplay,
        'playlistBox': playlistBox,
        'source': appMediaItem.mediaSource.name,
        'description': appMediaItem.description,
        'lyrics': appMediaItem.lyrics,
        'artistId': appMediaItem.artistId,
      },
    );
  }


}
