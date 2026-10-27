import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/download_task.dart';

class ActiveTaskCard extends StatefulWidget {
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
  State<ActiveTaskCard> createState() => _ActiveTaskCardState();
}

class _ActiveTaskCardState extends State<ActiveTaskCard> {
  bool _showLogs = false;
  final ScrollController _logScrollController = ScrollController();

  @override
  void dispose() {
    _logScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_showLogs && _logScrollController.hasClients) {
      _logScrollController.animateTo(
        _logScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isPaused = task.isPaused;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPaused ? AppColors.warning.withValues(alpha: 0.5) : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Thumbnail + Title + Channel
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: task.thumbnailUrl != null
                      ? Image.network(
                          task.thumbnailUrl!,
                          width: 80,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 52,
                            color: AppColors.surfaceElevated,
                            child: const Icon(Icons.movie_outlined, size: 24, color: AppColors.textMuted),
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 52,
                          color: AppColors.surfaceElevated,
                          child: const Icon(Icons.movie_outlined, size: 24, color: AppColors.textMuted),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.chipBackground,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              task.extension.toUpperCase(),
                              style: AppStyles.monoSmall.copyWith(fontSize: 10, color: AppColors.accentBright),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task.uploader ?? 'Direct Stream',
                              style: AppStyles.caption,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stream Stage / Phase
          if (task.currentPhase != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isPaused ? AppColors.warning : AppColors.accentBright,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    task.currentPhase!,
                    style: AppStyles.monoSmall.copyWith(
                      color: isPaused ? AppColors.warning : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),

          // Linear Progress Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (task.progress.clamp(0.0, 100.0)) / 100.0,
                backgroundColor: AppColors.surfaceHighlight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPaused ? AppColors.warning : AppColors.accent,
                ),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Real-time Metrics: Percentage, Speed, ETA & Size
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '${task.progress.toStringAsFixed(1)}%',
                      style: AppStyles.monoAccent.copyWith(
                        color: isPaused ? AppColors.warning : AppColors.accentBright,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('•', style: AppStyles.monoSmall),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 13,
                      color: isPaused ? AppColors.textMuted : AppColors.accentBright,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      task.speed,
                      style: AppStyles.monoSmall.copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (task.totalBytes != null && task.totalBytes! > 0) ...[
                      Text(
                        Formatters.formatBytes(task.totalBytes!),
                        style: AppStyles.monoSmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text('•', style: AppStyles.monoSmall),
                      const SizedBox(width: 8),
                    ],
                    const Icon(Icons.timer_outlined, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('ETA: ${task.eta}', style: AppStyles.monoSmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Bottom Bar: Terminal Log Toggle & Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Toggle live logs stream
                InkWell(
                  onTap: () => setState(() => _showLogs = !_showLogs),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          _showLogs ? Icons.terminal_rounded : Icons.code_rounded,
                          size: 14,
                          color: _showLogs ? AppColors.accentBright : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showLogs ? 'Hide Console' : 'Live Console',
                          style: AppStyles.monoSmall.copyWith(
                            color: _showLogs ? AppColors.accentBright : AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Controls: Pause / Resume & Cancel
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(0, 32),
                      ),
                      icon: Icon(
                        isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        size: 15,
                        color: isPaused ? AppColors.accentBright : AppColors.textPrimary,
                      ),
                      label: Text(
                        isPaused ? 'Resume' : 'Pause',
                        style: AppStyles.monoSmall.copyWith(fontSize: 11),
                      ),
                      onPressed: isPaused ? widget.onResume : widget.onPause,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(0, 32),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 14, color: AppColors.error),
                      label: Text(
                        'Cancel',
                        style: AppStyles.monoSmall.copyWith(color: AppColors.error, fontSize: 11),
                      ),
                      onPressed: widget.onCancel,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Expandable Live Terminal Output Console
          if (_showLogs)
            Container(
              width: double.infinity,
              height: 140,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: task.logs.isEmpty
                  ? Center(
                      child: Text('Awaiting process logs...', style: AppStyles.monoSmall.copyWith(color: AppColors.textMuted)),
                    )
                  : ListView.builder(
                      controller: _logScrollController,
                      itemCount: task.logs.length,
                      itemBuilder: (context, i) {
                        return Text(
                          task.logs[i],
                          style: AppStyles.monoSmall.copyWith(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
