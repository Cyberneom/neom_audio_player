import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';

import 'web_color_extractor.dart';

/// Builds an artwork image with a deterministic gradient fallback for web.
///
/// On web `file:` URIs do not load and `platformNetworkImage` is the only
/// reliable provider; this helper centralises that pattern and adds a
/// palette-aware placeholder so missing artwork still feels intentional.
///
/// Pass [cacheKey] (typically `mediaItem.id`) so the placeholder gradient
/// matches the dominant color cached by [WebColorExtractor]. Optionally
/// trigger an extraction by calling [WebColorExtractor.extract] from the
/// caller after the image first resolves.
class WebImageResolver {
  WebImageResolver._();

  static Widget build({
    required String? imageUrl,
    required String cacheKey,
    required double width,
    required double height,
    double borderRadius = 6,
    BoxFit fit = BoxFit.cover,
    IconData placeholderIcon = Icons.music_note_rounded,
  }) {
    final placeholder = _gradientPlaceholder(
      cacheKey: cacheKey,
      width: width,
      height: height,
      borderRadius: borderRadius,
      icon: placeholderIcon,
    );

    if (imageUrl == null || imageUrl.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: platformNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: fit,
          errorWidget: placeholder,
        ),
      ),
    );
  }

  static Widget _gradientPlaceholder({
    required String cacheKey,
    required double width,
    required double height,
    required double borderRadius,
    required IconData icon,
  }) {
    final base = WebColorExtractor.cachedOrFallback(cacheKey);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base.withValues(alpha: 0.55),
            AppColor.appBlack,
          ],
        ),
      ),
      child: Icon(
        icon,
        color: Colors.white54,
        size: width * 0.45,
      ),
    );
  }
}
