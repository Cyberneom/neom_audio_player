import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/paywall_sheet.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/subscription_level.dart';
import 'package:sint/sint.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';

class WebUpgradeBanner extends StatefulWidget {
  final String message;
  final String? buttonText;
  final VoidCallback? onUpgrade;
  final VoidCallback? onDismiss;

  const WebUpgradeBanner({
    Key? key,
    required this.message,
    this.buttonText,
    this.onUpgrade,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<WebUpgradeBanner> createState() => _WebUpgradeBannerState();
}

class _WebUpgradeBannerState extends State<WebUpgradeBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final isGigmeout = AppConfig.instance.appInUse == AppInUse.g;
    if (isGigmeout && Sint.isRegistered<UserService>()) {
      final userService = Sint.find<UserService>();
      if (userService.subscriptionLevel.value > SubscriptionLevel.freemium.value ||
          userService.user.subscriptionId.isNotEmpty) {
        return const SizedBox.shrink();
      }
    }

    final badgeTitle = isGigmeout
        ? 'Gig Music · \$80 MXN/mes'
        : AudioPlayerTranslationConstants.caseteBadge.tr;
    final bannerMessage = isGigmeout
        ? 'Escucha continua sin interrupción de tiempo e impulsa regalías directas CASETE (50% neto) a los artistas que escuchas.'
        : widget.message;
    final ctaLabel = isGigmeout
        ? 'Activar Gig Music'
        : (widget.buttonText ?? AppTranslationConstants.upgrade.tr);
    final handleUpgrade = widget.onUpgrade ??
        () {
          if (isGigmeout) {
            PaywallSheet.showGigMusic(context);
          } else {
            Sint.toNamed(AppRouteConstants.subscriptionPlans);
          }
        };

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.getMain().withValues(alpha: 0.3),
            Colors.purple.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_rounded, color: AppColor.getMain(), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badgeTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bannerMessage,
                  style: TextStyle(color: Colors.grey[300], fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: handleUpgrade,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ctaLabel,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() => _dismissed = true);
                widget.onDismiss?.call();
              },
              child: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
