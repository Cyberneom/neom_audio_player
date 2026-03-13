import 'package:flutter/material.dart';
import 'package:neom_commons/ui/widgets/images/handled_cached_network_image.dart';

import '../../../utils/platform_io_helper.dart' as platform_io;

/// Builds a network image using HandledCachedNetworkImage which
/// automatically uses native HTML <img> on web (bypasses CanvasKit CORS)
/// and CachedNetworkImage on mobile.
Widget _buildNetworkImage(String imageUrl, String placeholderImage) {
  if (imageUrl.isEmpty) {
    return Image(fit: BoxFit.cover, image: AssetImage(placeholderImage));
  }
  return HandledCachedNetworkImage(
    imageUrl,
    fit: BoxFit.cover,
    enableFullScreen: false,
    placeholder: Image(fit: BoxFit.cover, image: AssetImage(placeholderImage)),
  );
}

class Collage extends StatelessWidget {
  final bool showGrid;
  final List<String> imageList;
  final String placeholderImage;
  final double borderRadius;
  const Collage({
    super.key,
    this.borderRadius = 7.0,
    required this.showGrid,
    required this.imageList,
    required this.placeholderImage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      color: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          borderRadius,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: SizedBox.square(
        dimension: 50,
        child: showGrid
            ? GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: imageList.length < 4 ? 1 : 2,
                children: imageList
                    .map(
                      (image) => _buildNetworkImage(
                        image.replaceAll('http:', 'https:'),
                        placeholderImage,
                      ),
                    )
                    .toList(),
              )
            : _buildNetworkImage(
                imageList[0].replaceAll('http:', 'https:'),
                placeholderImage,
              ),
      ),
    );
  }
}

class OfflineCollage extends StatelessWidget {
  final List imageList;
  final String placeholderImage;
  final bool showGrid;
  const OfflineCollage({
    super.key,
    required this.showGrid,
    required this.imageList,
    required this.placeholderImage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          7.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox.square(
        dimension: 50,
        child: showGrid
            ? GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: imageList.length < 4 ? 1 : 2,
                children: imageList.map((image) {
                  return image == null
                      ? Image(
                          fit: BoxFit.cover,
                          image: AssetImage(placeholderImage),
                        )
                      : Image(
                          fit: BoxFit.cover,
                          image: platform_io.createFileImage(
                                image['image'].toString(),
                              ) ??
                              AssetImage(placeholderImage),
                          errorBuilder: (context, _, _) => Image(
                            fit: BoxFit.cover,
                            image: AssetImage(placeholderImage),
                          ),
                        );
                }).toList(),
              )
            : imageList[0] == null
                ? Image(
                    fit: BoxFit.cover,
                    image: AssetImage(placeholderImage),
                  )
                : Image(
                    fit: BoxFit.cover,
                    image: platform_io.createFileImage(
                          imageList[0]['image'].toString(),
                        ) ??
                        AssetImage(placeholderImage),
                    errorBuilder: (context, _, _) => Image(
                      fit: BoxFit.cover,
                      image: AssetImage(placeholderImage),
                    ),
                  ),
      ),
    );
  }
}
