import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/download_task.dart';

class CompletedTaskCard extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback? onRetry;
  final VoidCallback onDelete;

  const CompletedTaskCard({
    super.key,
    required this.task,
    required this.onOpen,
    required this.onShare,
    this.onRetry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isFailed = task.isFailed;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFailed
              ? AppColors.error.withValues(alpha: 0.45)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: task.thumbnailUrl != null
                    ? Image.network(
                        task.thumbnailUrl!,
                        width: 54,
                        height: 38,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 54,
                          height: 38,
                          color: AppColors.surfaceElevated,
                          child: const Icon(
                            Icons.movie_outlined,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : Container(
                        width: 54,
                        height: 38,
                        color: AppColors.surfaceElevated,
                        child: const Icon(
                          Icons.movie_outlined,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.monoLabel.copyWith(fontSize: 12.5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: isFailed
                                ? AppColors.error.withValues(alpha: 0.15)
                                : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isFailed
                                  ? AppColors.error.withValues(alpha: 0.4)
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Text(
                            isFailed
                                ? Formatters.errorCodeLabel(task.errorLog)
                                : task.extension.toUpperCase(),
                            style: AppStyles.monoSmall.copyWith(
                              fontSize: 9.5,
                              color: isFailed
                                  ? AppColors.error
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (task.totalBytes != null && task.totalBytes! > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            Formatters.formatBytes(task.totalBytes),
                            style: AppStyles.monoSmall.copyWith(fontSize: 10.5),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFailed && onRetry != null) ...[
                    _buildActionPill(
                      icon: Icons.refresh_rounded,
                      label: 'RETRY',
                      isPrimary: true,
                      onTap: onRetry!,
                    ),
                    const SizedBox(width: 6),
                  ] else if (!isFailed) ...[
                    _buildActionPill(
                      icon: Icons.play_arrow_rounded,
                      label: 'PLAY',
                      isPrimary: true,
                      onTap: onOpen,
                    ),
                    const SizedBox(width: 6),
                    _buildActionPill(
                      icon: Icons.share_outlined,
                      label: 'SHARE',
                      isPrimary: false,
                      onTap: onShare,
                    ),
                    const SizedBox(width: 4),
                  ],
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    tooltip: 'Remove',
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
          if (isFailed && task.errorLog != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                Formatters.cleanErrorMessage(task.errorLog),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppStyles.monoSmall.copyWith(
                  color: AppColors.error,
                  fontSize: 10.5,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isPrimary ? AppColors.accent : AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isPrimary ? AppColors.accent : AppColors.borderLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isPrimary ? AppColors.onAccent : AppColors.textPrimary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppStyles.monoSmall.copyWith(
                  fontSize: 9.5,
                  color: isPrimary ? AppColors.onAccent : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
