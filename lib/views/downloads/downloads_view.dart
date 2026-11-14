import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../controllers/download_controller.dart';
import 'widgets/active_task_card.dart';
import 'widgets/completed_task_card.dart';

class DownloadsView extends StatelessWidget {
  final VoidCallback? onNewDownloadRequested;

  const DownloadsView({super.key, this.onNewDownloadRequested});

  @override
  Widget build(BuildContext context) {
    final downloadCtrl = context.watch<DownloadController>();
    final tabs = downloadCtrl.tabs;
    final activeTabIndex = downloadCtrl.activeTabIndex;
    final currentTabTasks = downloadCtrl.tasksForCurrentTab;

    final activeTasks = currentTabTasks
        .where((t) => t.isActive || t.isPaused)
        .toList();
    final completedTasks = currentTabTasks
        .where((t) => t.isCompleted || t.isFailed)
        .toList();
    final failedCount = completedTasks.where((t) => t.isFailed).length;
    final doneCount = completedTasks.where((t) => t.isCompleted).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 22,
        centerTitle: false,
        title: Row(
          children: [
            Text(
              'TASK QUEUE',
              style: AppStyles.monoHeadline.copyWith(
                fontSize: 15,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            _buildStatPill('ACTIVE ${activeTasks.length}'),
            const SizedBox(width: 6),
            _buildStatPill('DONE $doneCount'),
            if (failedCount > 0) ...[
              const SizedBox(width: 6),
              _buildStatPill('ERR $failedCount', isError: true),
            ],
          ],
        ),
        actions: [
          if (completedTasks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, size: 20),
              tooltip: 'Clear completed tasks',
              color: AppColors.textSecondary,
              onPressed: downloadCtrl.clearCompleted,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          _buildMultiTabBar(context, downloadCtrl, tabs, activeTabIndex),
          const Divider(height: 1),
          Expanded(
            child: (activeTasks.isEmpty && completedTasks.isEmpty)
                ? _buildEmptyState(context)
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    children: [
                      if (activeTasks.isNotEmpty) ...[
                        Text(
                          'ACTIVE TRANSFERS // ${activeTasks.length}',
                          style: AppStyles.caption.copyWith(letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 10),
                        ...activeTasks.map(
                          (task) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ActiveTaskCard(
                              task: task,
                              onPause: () => downloadCtrl.pauseTask(task.id),
                              onResume: () => downloadCtrl.resumeTask(task.id),
                              onCancel: () => downloadCtrl.cancelTask(task.id),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (completedTasks.isNotEmpty) ...[
                        Text(
                          'ARCHIVE // ${completedTasks.length}',
                          style: AppStyles.caption.copyWith(letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 10),
                        ...completedTasks.map(
                          (task) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: CompletedTaskCard(
                              task: task,
                              onOpen: () => downloadCtrl.openFile(task),
                              onShare: () => downloadCtrl.shareFile(task),
                              onRetry: () => downloadCtrl.resumeTask(task.id),
                              onDelete: () => downloadCtrl.deleteTask(task.id),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, {bool isError = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.error.withValues(alpha: 0.14)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isError
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.borderLight,
        ),
      ),
      child: Text(
        label,
        style: AppStyles.monoSmall.copyWith(
          fontSize: 9.5,
          color: isError ? AppColors.error : AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMultiTabBar(
    BuildContext context,
    DownloadController downloadCtrl,
    List<dynamic> tabs,
    int activeTabIndex,
  ) {
    return Container(
      color: AppColors.surface,
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isSelected = activeTabIndex == index;
                final isClosable = tab.isClosable as bool;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => downloadCtrl.selectTab(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (tab.title as String).toUpperCase(),
                            style: AppStyles.monoSmall.copyWith(
                              color: isSelected
                                  ? AppColors.onAccent
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                            ),
                          ),
                          if (isClosable) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () =>
                                  downloadCtrl.closeTab(tab.id as String),
                              child: Icon(
                                Icons.close_rounded,
                                size: 13,
                                color: isSelected
                                    ? AppColors.onAccent
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, size: 18),
              tooltip: 'New session tab',
              color: AppColors.textPrimary,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.borderLight),
                ),
              ),
              onPressed: downloadCtrl.createTab,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Icon(
                Icons.south_rounded,
                size: 32,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'QUEUE // EMPTY',
              style: AppStyles.monoHeadline.copyWith(
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Extract a video, audio track, playlist, or live stream from the home tab.',
              textAlign: TextAlign.center,
              style: AppStyles.monoSmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              icon: const Icon(
                Icons.north_east_rounded,
                size: 16,
                color: AppColors.onAccent,
              ),
              label: Text(
                'EXTRACT MEDIA',
                style: AppStyles.monoLabel.copyWith(
                  color: AppColors.onAccent,
                  fontSize: 11.5,
                  letterSpacing: 1.0,
                ),
              ),
              onPressed: onNewDownloadRequested,
            ),
          ],
        ),
      ),
    );
  }
}
