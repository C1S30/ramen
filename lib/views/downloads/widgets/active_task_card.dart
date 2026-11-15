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
    final isIndeterminateLive =
        task.isLiveStream && task.progress <= 0 && !isPaused;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPaused ? AppColors.borderLight : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: task.thumbnailUrl != null
                    ? Image.network(
                        task.thumbnailUrl!,
                        width: 64,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 64,
                          height: 44,
                          color: AppColors.surfaceElevated,
                          child: const Icon(
                            Icons.movie_outlined,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : Container(
                        width: 64,
                        height: 44,
                        color: AppColors.surfaceElevated,
                        child: const Icon(
                          Icons.movie_outlined,
                          size: 18,
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
                            color: task.isLiveStream
                                ? AppColors.accent
                                : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Text(
                            task.isLiveStream
                                ? '● LIVE'
                                : (task.isPlaylistBatch
                                      ? 'BATCH'
                                      : task.extension.toUpperCase()),
                            style: AppStyles.monoSmall.copyWith(
                              fontSize: 9.5,
                              color: task.isLiveStream
                                  ? AppColors.onAccent
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.uploader ?? 'DIRECT STREAM',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.monoSmall.copyWith(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isIndeterminateLive
                    ? 'REC'
                    : '${task.progress.clamp(0.0, 100.0).toStringAsFixed(1)}%',
                style: AppStyles.monoDisplay.copyWith(
                  fontSize: 18,
                  color: isPaused
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: isIndeterminateLive
                  ? null
                  : (task.progress.clamp(0.0, 100.0)) / 100.0,
              backgroundColor: AppColors.surfaceHighlight,
              valueColor: AlwaysStoppedAnimation<Color>(
                isPaused ? AppColors.textSecondary : AppColors.accent,
              ),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Text(
                task.speed.isNotEmpty ? task.speed : '0.0 KB/s',
                style: AppStyles.monoSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text('•', style: AppStyles.monoSmall),
              const SizedBox(width: 8),
              Text(
                'ETA ${task.eta}',
                style: AppStyles.monoSmall.copyWith(fontSize: 10.5),
              ),
              if (task.totalBytes != null && task.totalBytes! > 0) ...[
                const SizedBox(width: 8),
                Text('•', style: AppStyles.monoSmall),
                const SizedBox(width: 8),
                Text(
                  Formatters.formatBytes(task.totalBytes!),
                  style: AppStyles.monoSmall.copyWith(fontSize: 10.5),
                ),
              ],
              const Spacer(),
              InkWell(
                onTap: () => setState(() => _showLogs = !_showLogs),
                borderRadius: BorderRadius.circular(5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  child: Text(
                    _showLogs ? 'HIDE LOGS' : 'CLI LOGS',
                    style: AppStyles.monoSmall.copyWith(
                      fontSize: 9.5,
                      color: _showLogs
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: isPaused ? AppColors.accent : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: isPaused ? widget.onResume : widget.onPause,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isPaused
                            ? AppColors.accent
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          size: 13,
                          color: isPaused
                              ? AppColors.onAccent
                              : AppColors.textPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPaused ? 'RESUME' : 'PAUSE',
                          style: AppStyles.monoSmall.copyWith(
                            fontSize: 10,
                            color: isPaused
                                ? AppColors.onAccent
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: widget.onCancel,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.close_rounded,
                          size: 13,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'CANCEL',
                          style: AppStyles.monoSmall.copyWith(
                            color: AppColors.error,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_showLogs) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 110,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: task.logs.isEmpty
                  ? Center(
                      child: Text(
                        'AWAITING YT-DLP STDOUT...',
                        style: AppStyles.monoSmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
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
                            fontSize: 9.5,
                            color: AppColors.textSecondary,
                            height: 1.3,
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
