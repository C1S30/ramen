import 'dart:async';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/di/injection.dart';
import '../../models/download_tab.dart';
import '../../models/download_task.dart';
import '../../services/task_queue_service.dart';

class DownloadController extends ChangeNotifier {
  final TaskQueueService _taskQueue = getIt<TaskQueueService>();
  StreamSubscription? _taskSubscription;

  List<DownloadTask> _allTasks = [];
  final List<DownloadTab> _tabs = [
    const DownloadTab(id: 'tab_all', title: 'All Downloads', isClosable: false),
    const DownloadTab(id: 'tab_1', title: 'Stream 1', isClosable: true),
  ];
  int _activeTabIndex = 0;
  int _tabCounter = 1;

  DownloadController() {
    _allTasks = _taskQueue.tasks;
    _taskSubscription = _taskQueue.tasksStream.listen((tasks) {
      _allTasks = tasks;
      _syncTabsWithTasks();
      notifyListeners();
    });
  }

  List<DownloadTask> get allTasks => _allTasks;
  List<DownloadTab> get tabs => List.unmodifiable(_tabs);
  int get activeTabIndex => _activeTabIndex;

  DownloadTab get currentTab {
    if (_activeTabIndex >= 0 && _activeTabIndex < _tabs.length) {
      return _tabs[_activeTabIndex];
    }
    return _tabs.first;
  }

  List<DownloadTask> get activeTasks =>
      _allTasks.where((t) => t.isActive || t.isPaused).toList();

  List<DownloadTask> get completedTasks =>
      _allTasks.where((t) => t.isCompleted || t.isFailed).toList();

  int get activeCount => _allTasks.where((t) => t.isActive).length;

  List<DownloadTask> get tasksForCurrentTab {
    final tab = currentTab;
    if (tab.id == 'tab_all') {
      return _allTasks;
    }
    if (tab.assignedTaskId != null) {
      return _allTasks.where((t) => t.id == tab.assignedTaskId).toList();
    }
    return _allTasks.where((t) => t.tabId == tab.id).toList();
  }

  void selectTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _activeTabIndex = index;
      notifyListeners();
    }
  }

  DownloadTab createTab({String? title, String? assignedTaskId}) {
    _tabCounter++;
    final newId = 'tab_$_tabCounter';
    final newTitle = title ?? 'Stream $_tabCounter';
    final tab = DownloadTab(
      id: newId,
      title: newTitle,
      assignedTaskId: assignedTaskId,
      isClosable: true,
    );
    _tabs.add(tab);
    _activeTabIndex = _tabs.length - 1;
    notifyListeners();
    return tab;
  }

  void closeTab(String tabId) {
    final index = _tabs.indexWhere((t) => t.id == tabId);
    if (index != -1 && _tabs[index].isClosable) {
      _tabs.removeAt(index);
      if (_activeTabIndex >= _tabs.length) {
        _activeTabIndex = _tabs.length - 1;
      }
      notifyListeners();
    }
  }

  void _syncTabsWithTasks() {
    for (int i = 0; i < _tabs.length; i++) {
      final tab = _tabs[i];
      if (tab.assignedTaskId != null) {
        final task = _allTasks.where((t) => t.id == tab.assignedTaskId).firstOrNull;
        if (task != null && task.title.isNotEmpty && tab.title.startsWith('Stream')) {
          final cleanTitle = task.title.length > 15
              ? '${task.title.substring(0, 15)}...'
              : task.title;
          _tabs[i] = tab.copyWith(title: cleanTitle);
        }
      }
    }
  }

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
    final tabIndex = _tabs.indexWhere((t) => t.assignedTaskId == taskId);
    if (tabIndex != -1 && _tabs[tabIndex].isClosable) {
      closeTab(_tabs[tabIndex].id);
    }
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
