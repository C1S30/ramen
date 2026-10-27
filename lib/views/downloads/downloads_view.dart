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

    final activeTasks = currentTabTasks.where((t) => t.isActive || t.isPaused).toList();
    final completedTasks = currentTabTasks.where((t) => t.isCompleted || t.isFailed).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          'DOWNLOADS',
          style: AppStyles.monoHeadline.copyWith(
            fontSize: 18,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (completedTasks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cleaning_services_rounded, size: 20),
              tooltip: 'Clear completed tasks',
              color: AppColors.textSecondary,
              onPressed: () => downloadCtrl.clearCompleted(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Multi-Tab Strip for Simultaneous Downloads
          _buildMultiTabBar(context, downloadCtrl, tabs, activeTabIndex),
          const Divider(height: 1),

          // Tab Content
          Expanded(
            child: (activeTasks.isEmpty && completedTasks.isEmpty)
                ? _buildEmptyState(context, downloadCtrl.currentTab.title)
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    children: [
                      // Active Simultaneous Downloads
                      if (activeTasks.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentBright,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ACTIVE STREAMS (${activeTasks.length})',
                                  style: AppStyles.caption.copyWith(letterSpacing: 0.8),
                                ),
                              ],
                            ),
                            Text(
                              'Aria2c + FFmpeg Socket',
                              style: AppStyles.monoSmall.copyWith(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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

                      // Completed Downloads Section
                      if (completedTasks.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              'FINISHED TASKS (${completedTasks.length})',
                              style: AppStyles.caption.copyWith(letterSpacing: 0.8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...completedTasks.map(
                          (task) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CompletedTaskCard(
                              task: task,
                              onOpen: () => downloadCtrl.openFile(task),
                              onShare: () => downloadCtrl.shareFile(task),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accentMuted : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.accentBright : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.accentBright,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            tab.title as String,
                            style: AppStyles.monoSmall.copyWith(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                          if (isClosable) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => downloadCtrl.closeTab(tab.id as String),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: AppColors.textMuted,
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

          // Add New Tab Button for simultaneous downloads
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, size: 20),
              tooltip: 'Open new download tab',
              color: AppColors.accentBright,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
              onPressed: () => downloadCtrl.createTab(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String tabTitle) {
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
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.downloading_rounded,
                size: 36,
                color: AppColors.accentBright,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Downloads in $tabTitle',
              style: AppStyles.titleMedium.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Paste a URL on the home search page to start simultaneous stream downloads.',
              textAlign: TextAlign.center,
              style: AppStyles.caption,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceElevated,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.accentBright),
              label: Text('NEW DOWNLOAD', style: AppStyles.monoSmall),
              onPressed: () {
                onNewDownloadRequested?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}
