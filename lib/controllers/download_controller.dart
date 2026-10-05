import 'dart:async';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/di/injection.dart';
import '../../models/download_task.dart';
import '../../services/task_queue_service.dart';

class DownloadController extends ChangeNotifier {
  final TaskQueueService _taskQueue = getIt<TaskQueueService>();
  StreamSubscription? _taskSubscription;

  List<DownloadTask> _allTasks = [];

  DownloadController() {
    _allTasks = _taskQueue.tasks;
    _taskSubscription = _taskQueue.tasksStream.listen((tasks) {
      _allTasks = tasks;
      notifyListeners();
    });
  }

  List<DownloadTask> get allTasks => _allTasks;

  List<DownloadTask> get activeTasks =>
      _allTasks.where((t) => t.isActive || t.isPaused).toList();

  List<DownloadTask> get completedTasks =>
      _allTasks.where((t) => t.isCompleted || t.isFailed).toList();

  int get activeCount => _allTasks.where((t) => t.isActive).length;

  Future<void> pauseTask(String taskId) async {
    await _taskQueue.pauseTask(taskId);
  }

  Future<void> resumeTask(String taskId) async {
    await _taskQueue.resumeTask(taskId);
  }

  Future<void> cancelTask(String taskId) async {
    await _taskQueue.cancelTask(taskId);
  }

  Future<void> deleteTask(String taskId) async {
    await _taskQueue.deleteTask(taskId);
  }

  Future<void> clearCompleted() async {
    await _taskQueue.clearCompleted();
  }

  Future<void> openFile(DownloadTask task) async {
    if (task.localFilePath != null && task.localFilePath!.isNotEmpty) {
      await OpenFilex.open(task.localFilePath!);
    }
  }

  Future<void> shareFile(DownloadTask task) async {
    if (task.localFilePath != null && task.localFilePath!.isNotEmpty) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(task.localFilePath!)],
          subject: 'Shared from Ramen: ${task.title}',
        ),
      );
    }
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    super.dispose();
  }
}
