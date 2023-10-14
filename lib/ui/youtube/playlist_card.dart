
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_music_player/domain/entities/playlist_item.dart';
import 'package:neom_music_player/ui/YouTube/youtube_playlist.dart';
import 'package:neom_music_player/ui/YouTube/youtube_search.dart';
import 'package:neom_music_player/utils/enums/playlist_type.dart';

class PlaylistCard extends StatelessWidget {

  final PlaylistItem playlistItem;

  const PlaylistCard({
    super.key,
    required this.playlistItem,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool rotated = MediaQuery.of(context).size.height < screenWidth;
    double boxSize = !rotated
        ? MediaQuery.of(context).size.width / 2
        : MediaQuery.of(context).size.height / 2.5;

    playlistItem.subtitle = playlistItem.type != PlaylistType.video
        ? '${playlistItem.count} Tracks | ${playlistItem.description}'
        : '${playlistItem.count} | ${playlistItem.description}';

    return GestureDetector(
      child: SizedBox(
        width: playlistItem.type != PlaylistType.playlist
            ? (boxSize - 30) * (16 / 9) : boxSize - 30,
        child: Card(
          color: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              10.0,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0,),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CachedNetworkImage(
                          fit: BoxFit.cover,
                          errorWidget:
                              (context, _, __) =>
                              Image(fit: BoxFit.cover,
                                image: playlistItem.type != PlaylistType.playlist
                                    ? const AssetImage(AppAssets.musicPlayerYTCover)
                                    : const AssetImage(AppAssets.musicPlayerCover,),
                              ),
                          imageUrl: playlistItem.imgUrl,
                          placeholder: (context, url) =>
                              Image(fit: BoxFit.cover,
                                image: playlistItem.type != PlaylistType.playlist
                                    ? const AssetImage(AppAssets.musicPlayerYTCover,)
                                    : const AssetImage(AppAssets.musicPlayerCover,),
                              ),
                        ),
                      ),
                    ),
                    if (playlistItem.type == PlaylistType.chart)
                      Align(alignment: Alignment.centerRight,
                        child: Container(
                          color: Colors.black.withOpacity(0.75),
                          width: (boxSize - 30) * (16 / 9) / 2.5,
                          margin: const EdgeInsets.all(4.0,),
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                            children: [
                              Text(playlistItem.count.toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const IconButton(
                                onPressed: null,
                                color: Colors.white,
                                disabledColor: Colors.white,
                                icon: Icon(Icons.playlist_play_rounded,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                ),
                child: Column(
                  children: [
                    Text(playlistItem.title,
                      textAlign: TextAlign.center,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(playlistItem.subtitle,
                      textAlign: TextAlign.center,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .color,
                      ),
                    ),
                    const SizedBox(height: 5.0,),
                  ],
                ),
              ),
            ],
          ),

        ),
      ),
      onTap: () {
        playlistItem.type == PlaylistType.video
            ? Navigator.push(context,
          PageRouteBuilder(opaque: false,
            pageBuilder: (_, __, ___) =>
                YouTubeSearchPage(query: playlistItem.title,),
          ),
        ) : Navigator.push(context,
          PageRouteBuilder(opaque: false,
            pageBuilder: (_, __, ___) =>
                YouTubePlaylist(playlistId: playlistItem.id,),
          ),
        );
      },
    );
  }
}
