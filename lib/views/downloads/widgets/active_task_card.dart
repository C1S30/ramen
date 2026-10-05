import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../models/download_task.dart';

class ActiveTaskCard extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;

  const ActiveTaskCard({
    super.key,
    required this.task,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isPaused = task.isPaused;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Thumbnail + Title + Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: task.thumbnailUrl != null
                    ? Image.network(
                        task.thumbnailUrl!,
                        width: 72,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 72,
                          height: 48,
                          color: AppColors.surfaceElevated,
                          child: const Icon(Icons.movie, size: 20),
                        ),
                      )
                    : Container(
                        width: 72,
                        height: 48,
                        color: AppColors.surfaceElevated,
                        child: const Icon(Icons.movie, size: 20),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.bodyLarge.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.uploader ?? 'Ramen Downloader',
                      style: AppStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar (Sleek 3px Crimson Fill)
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: task.progress / 100.0,
              backgroundColor: AppColors.surfaceHighlight,
              valueColor: AlwaysStoppedAnimation<Color>(
                isPaused ? AppColors.warning : AppColors.accent,
              ),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 10),

          // Real-time Metrics: Percentage, Speed, ETA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${task.progress.toStringAsFixed(1)}%',
                    style: AppStyles.monoAccent.copyWith(
                      color: isPaused
                          ? AppColors.warning
                          : AppColors.accentBright,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('•', style: AppStyles.monoSmall),
                  const SizedBox(width: 8),
                  Text(
                    task.speed,
                    style: AppStyles.monoSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('ETA: ${task.eta}', style: AppStyles.monoSmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Controls (Pause/Resume & Cancel)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Pause / Resume Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: Icon(
                  isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  size: 16,
                  color: isPaused ? AppColors.accentBright : AppColors.textPrimary,
                ),
                label: Text(
                  isPaused ? 'Resume' : 'Pause',
                  style: AppStyles.monoSmall,
                ),
                onPressed: isPaused ? onResume : onPause,
              ),
              const SizedBox(width: 10),

              // Cancel Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.close_rounded,
                    size: 16, color: AppColors.error),
                label: Text(
                  'Cancel',
                  style: AppStyles.monoSmall.copyWith(color: AppColors.error),
                ),
                onPressed: onCancel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
