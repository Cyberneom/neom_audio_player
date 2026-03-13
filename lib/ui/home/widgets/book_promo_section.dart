import 'package:flutter/material.dart';
import 'package:neom_commons/ui/widgets/images/handled_cached_network_image.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import '../audio_player_home_controller.dart';

/// Horizontal section showing book releases as cross-promo inside the audio player.
class BookPromoSection extends StatelessWidget {

  const BookPromoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Sint.find<AudioPlayerHomeController>();
    final boxSize = MediaQuery.of(context).size.height > MediaQuery.of(context).size.width
        ? MediaQuery.of(context).size.width / 2
        : MediaQuery.of(context).size.height / 2.5;

    return Obx(() {
      if (controller.bookReleases.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
            child: Text(
              'Lee tambien',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: boxSize * 0.75,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: controller.bookReleases.length,
              itemBuilder: (context, index) {
                final book = controller.bookReleases[index];
                return _BookPromoCard(book: book, size: boxSize * 0.7);
              },
            ),
          ),
        ],
      );
    });
  }
}

class _BookPromoCard extends StatelessWidget {
  final AppReleaseItem book;
  final double size;

  const _BookPromoCard({required this.book, required this.size});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Sint.toNamed(
        AppRouteConstants.itemPath(book.id),
        arguments: [book.id],
      ),
      child: Container(
        width: size * 0.65,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
              elevation: 8,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                height: size * 0.85,
                width: size * 0.6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: HandledCachedNetworkImage(book.imgUrl),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              book.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              book.ownerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
