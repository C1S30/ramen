import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/download_task.dart';

class CompletedTaskCard extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const CompletedTaskCard({
    super.key,
    required this.task,
    required this.onOpen,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isFailed = task.isFailed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFailed
              ? AppColors.error.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    Row(
                      children: [
                        // Extension Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isFailed
                                ? AppColors.error.withValues(alpha: 0.2)
                                : AppColors.chipBackground,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isFailed ? 'FAILED' : task.extension.toUpperCase(),
                            style: AppStyles.monoSmall.copyWith(
                              fontSize: 10,
                              color: isFailed
                                  ? AppColors.error
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (task.totalBytes != null)
                          Text(
                            Formatters.formatBytes(task.totalBytes),
                            style: AppStyles.monoSmall,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isFailed && task.errorLog != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                task.errorLog!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppStyles.monoSmall.copyWith(
                  color: AppColors.error,
                  fontSize: 10,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Finished ${task.completedAt != null ? "${task.completedAt!.hour.toString().padLeft(2, '0')}:${task.completedAt!.minute.toString().padLeft(2, '0')}" : ""}',
                style: AppStyles.caption,
              ),
              Row(
                children: [
                  if (!isFailed) ...[
                    IconButton(
                      icon: const Icon(Icons.play_circle_outline_rounded,
                          size: 20, color: AppColors.textPrimary),
                      tooltip: 'Open in Media Player',
                      onPressed: onOpen,
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined,
                          size: 18, color: AppColors.textPrimary),
                      tooltip: 'Share File',
                      onPressed: onShare,
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.textMuted),
                    tooltip: 'Delete Task',
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
