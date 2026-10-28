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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFailed
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: task.thumbnailUrl != null
                    ? Image.network(
                        task.thumbnailUrl!,
                        width: 50,
                        height: 34,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 50,
                          height: 34,
                          color: AppColors.surfaceElevated,
                          child: const Icon(Icons.movie_outlined, size: 16, color: AppColors.textMuted),
                        ),
                      )
                    : Container(
                        width: 50,
                        height: 34,
                        color: AppColors.surfaceElevated,
                        child: const Icon(Icons.movie_outlined, size: 16, color: AppColors.textMuted),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.bodyLarge.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          isFailed ? 'FAILED' : task.extension.toUpperCase(),
                          style: AppStyles.monoSmall.copyWith(
                            fontSize: 10,
                            color: isFailed ? AppColors.error : AppColors.accentBright,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (task.totalBytes != null && task.totalBytes! > 0) ...[
                          const SizedBox(width: 6),
                          Text('•', style: AppStyles.monoSmall.copyWith(fontSize: 10)),
                          const SizedBox(width: 6),
                          Text(
                            Formatters.formatBytes(task.totalBytes),
                            style: AppStyles.monoSmall.copyWith(fontSize: 11),
                          ),
                        ],
                        if (task.completedAt != null) ...[
                          const SizedBox(width: 6),
                          Text('•', style: AppStyles.monoSmall.copyWith(fontSize: 10)),
                          const SizedBox(width: 6),
                          Text(
                            '${task.completedAt!.hour.toString().padLeft(2, '0')}:${task.completedAt!.minute.toString().padLeft(2, '0')}',
                            style: AppStyles.caption.copyWith(fontSize: 10),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Compact Action Icons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isFailed) ...[
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20, color: AppColors.textPrimary),
                      tooltip: 'Play',
                      onPressed: onOpen,
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.share_outlined, size: 16, color: AppColors.textSecondary),
                      tooltip: 'Share',
                      onPressed: onShare,
                    ),
                    const SizedBox(width: 6),
                  ],
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                    tooltip: 'Delete',
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
          if (isFailed && task.errorLog != null) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                task.errorLog!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppStyles.monoSmall.copyWith(
                  color: AppColors.error,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
