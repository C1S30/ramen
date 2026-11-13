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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaused
              ? AppColors.warning.withValues(alpha: 0.6)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Thumbnail + Title & Uploader + Controls
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                            size: 18,
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
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      // maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: AppStyles.bodyLarge.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          task.uploader ?? 'Direct Stream',
                          style: AppStyles.caption.copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '•',
                          style: AppStyles.monoSmall.copyWith(fontSize: 10),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          task.extension.toUpperCase(),
                          style: AppStyles.monoSmall.copyWith(
                            fontSize: 10,
                            color: AppColors.accentBright,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (task.isLiveStream) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '● LIVE',
                              style: AppStyles.monoSmall.copyWith(
                                color: AppColors.onAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ] else if (task.isPlaylistBatch) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentMuted,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.accent),
                            ),
                            child: Text(
                              'PLAYLIST',
                              style: AppStyles.monoSmall.copyWith(
                                color: AppColors.accentBright,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Compact Actions (Pause / Resume & Cancel)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: isPaused ? widget.onResume : widget.onPause,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            size: 13,
                            color: isPaused
                                ? AppColors.accentBright
                                : AppColors.textPrimary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isPaused ? 'Resume' : 'Pause',
                            style: AppStyles.monoSmall.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: widget.onCancel,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppStyles.monoSmall.copyWith(
                          color: AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Minimalist Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: LinearProgressIndicator(
              value: (task.isLiveStream && task.progress <= 0 && !isPaused)
                  ? null
                  : (task.progress.clamp(0.0, 100.0)) / 100.0,
              backgroundColor: AppColors.surfaceHighlight,
              valueColor: AlwaysStoppedAnimation<Color>(
                isPaused ? AppColors.textSecondary : AppColors.accent,
              ),
              minHeight: 2.5,
            ),
          ),
          const SizedBox(height: 8),

          // Row 3: Minimalist Metrics Line + Console Link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    task.isLiveStream && task.progress <= 0
                        ? 'LIVE STREAM'
                        : '${task.progress.toStringAsFixed(1)}%',
                    style: AppStyles.monoAccent.copyWith(
                      color: isPaused
                          ? AppColors.warning
                          : AppColors.accentBright,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('•', style: AppStyles.monoSmall.copyWith(fontSize: 10)),
                  const SizedBox(width: 6),
                  Text(
                    task.speed,
                    style: AppStyles.monoSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('•', style: AppStyles.monoSmall.copyWith(fontSize: 10)),
                  const SizedBox(width: 6),
                  Text(
                    'ETA: ${task.eta}',
                    style: AppStyles.monoSmall.copyWith(fontSize: 11),
                  ),
                  if (task.totalBytes != null && task.totalBytes! > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '•',
                      style: AppStyles.monoSmall.copyWith(fontSize: 10),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      Formatters.formatBytes(task.totalBytes!),
                      style: AppStyles.monoSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
              InkWell(
                onTap: () => setState(() => _showLogs = !_showLogs),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _showLogs ? Icons.terminal_rounded : Icons.code_rounded,
                        size: 13,
                        color: _showLogs
                            ? AppColors.accentBright
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showLogs ? 'Hide logs' : 'Show logs',
                        style: AppStyles.monoSmall.copyWith(
                          fontSize: 10,
                          color: _showLogs
                              ? AppColors.accentBright
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Optional Live Console
          if (_showLogs) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: task.logs.isEmpty
                  ? Center(
                      child: Text(
                        'Awaiting process logs...',
                        style: AppStyles.monoSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _logScrollController,
                      itemCount: task.logs.length,
                      itemBuilder: (context, i) {
                        return Text(
                          task.logs[i],
                          style: AppStyles.monoSmall.copyWith(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                            height: 1.25,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
