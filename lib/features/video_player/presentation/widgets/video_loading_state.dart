import 'package:acendra/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class VideoLoadingState extends StatelessWidget {
  const VideoLoadingState({super.key, this.label = 'Buffering…'});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.dark.primary),
            if (label != null && label!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                label!,
                style: TextStyle(
                  color: AppColors.dark.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
