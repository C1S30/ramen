import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../controllers/download_controller.dart';
import 'widgets/active_task_card.dart';
import 'widgets/completed_task_card.dart';

class DownloadsView extends StatefulWidget {
  const DownloadsView({super.key});

  @override
  State<DownloadsView> createState() => _DownloadsViewState();
}

class _DownloadsViewState extends State<DownloadsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloadCtrl = context.watch<DownloadController>();
    final activeTasks = downloadCtrl.activeTasks;
    final completedTasks = downloadCtrl.completedTasks;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'DOWNLOADS',
          style: AppStyles.titleMedium.copyWith(letterSpacing: 1.2),
        ),
        actions: [
          if (completedTasks.isNotEmpty)
            TextButton(
              onPressed: () {
                downloadCtrl.clearCompleted();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cleared completed downloads'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Text(
                'Clear History',
                style: AppStyles.monoSmall.copyWith(color: AppColors.textMuted),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          indicatorWeight: 2.5,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: AppStyles.monoLabel,
          unselectedLabelStyle: AppStyles.monoSmall,
          tabs: [
            Tab(text: 'ACTIVE (${activeTasks.length})'),
            Tab(text: 'COMPLETED (${completedTasks.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active Tasks Tab
          activeTasks.isEmpty
              ? _buildEmptyState(
                  icon: Icons.downloading_rounded,
                  title: 'No Active Downloads',
                  subtitle:
                      'Searched formats or queued tasks will show real-time progress and speed here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: activeTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final task = activeTasks[index];
                    return ActiveTaskCard(
                      task: task,
                      onPause: () => downloadCtrl.pauseTask(task.id),
                      onResume: () => downloadCtrl.resumeTask(task.id),
                      onCancel: () => downloadCtrl.cancelTask(task.id),
                    );
                  },
                ),

          // Completed Tasks Tab
          completedTasks.isEmpty
              ? _buildEmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'No Completed Files Yet',
                  subtitle:
                      'Downloaded videos and extracted audio files will be archived here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: completedTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final task = completedTasks[index];
                    return CompletedTaskCard(
                      task: task,
                      onOpen: () => downloadCtrl.openFile(task),
                      onShare: () => downloadCtrl.shareFile(task),
                      onDelete: () => downloadCtrl.deleteTask(task.id),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 36, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppStyles.titleMedium),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppStyles.bodyMedium.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
