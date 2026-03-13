import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';

class WebUpgradeBanner extends StatefulWidget {
  final String message;
  final VoidCallback? onUpgrade;
  final VoidCallback? onDismiss;

  const WebUpgradeBanner({
    Key? key,
    required this.message,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.getMain().withOpacity(0.3),
            Colors.purple.withOpacity(0.2),
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
                const Text(
                  'CASETE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.message,
                  style: TextStyle(color: Colors.grey[300], fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.onUpgrade,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Upgrade',
                  style: TextStyle(
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
