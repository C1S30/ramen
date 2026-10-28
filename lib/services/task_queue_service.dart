import 'dart:async';
import '../models/app_settings.dart';
import '../models/download_task.dart';
import 'native_bridge_service.dart';
import 'storage_service.dart';

class TaskQueueService {
  final StorageService _storageService;
  final NativeBridgeService _nativeBridgeService;

  final List<DownloadTask> _tasks = [];
  StreamSubscription? _progressSubscription;
  final StreamController<List<DownloadTask>> _tasksController =
      StreamController<List<DownloadTask>>.broadcast();
  final StreamController<DownloadTask> _taskCompletedController =
      StreamController<DownloadTask>.broadcast();

  TaskQueueService({
    required StorageService storageService,
    required NativeBridgeService nativeBridgeService,
  })  : _storageService = storageService,
        _nativeBridgeService = nativeBridgeService {
    _loadInitialTasks();
    _listenToProgress();
  }

  Stream<List<DownloadTask>> get tasksStream => _tasksController.stream;
  Stream<DownloadTask> get onTaskCompleted => _taskCompletedController.stream;
  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  void _loadInitialTasks() {
    _tasks.clear();
    _tasks.addAll(_storageService.getAllTasks());
    _notify();
  }

  void _listenToProgress() {
    _progressSubscription =
        _nativeBridgeService.downloadStream.listen((data) {
      final taskId = data['taskId'] as String?;
      if (taskId == null) return;

      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex == -1) return;

      final task = _tasks[taskIndex];
      final statusStr = data['status'] as String?;
      final progress = (data['progress'] as num?)?.toDouble() ?? task.progress;
      final speed = data['speed']?.toString() ?? task.speed;
      final eta = data['eta']?.toString() ?? task.eta;

      final log = data['log']?.toString();
      if (log != null && log.isNotEmpty) {
        task.appendLog(log);
      }

      task.progress = progress;
      task.speed = speed;
      task.eta = eta;

      if (statusStr == 'COMPLETED') {
        task.status = DownloadStatus.completed;
        task.completedAt = DateTime.now();
        task.progress = 100.0;
        task.speed = '0.0 KB/s';
        task.eta = 'Done';
        _storageService.saveTask(task);
        _taskCompletedController.add(task);
        _processQueue(); // Start next queued task
      } else if (statusStr == 'FAILED') {
        task.status = DownloadStatus.failed;
        task.errorLog = data['error']?.toString();
        _storageService.saveTask(task);
        _processQueue();
      } else if (statusStr == 'CANCELLED') {
        task.status = DownloadStatus.cancelled;
        task.speed = 'Cancelled';
        _storageService.saveTask(task);
        _processQueue();
      } else if (statusStr == 'DOWNLOADING') {
        task.status = DownloadStatus.downloading;
      }

      _notify();
    });
  }

  Future<void> enqueueTask(DownloadTask task) async {
    _tasks.insert(0, task);
    await _storageService.saveTask(task);
    _notify();
    _processQueue();
  }

  Future<void> pauseTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    if (task.isActive) {
      await _nativeBridgeService.cancelDownload(taskId);
      task.status = DownloadStatus.paused;
      task.speed = 'Paused';
      await _storageService.saveTask(task);
      _notify();
      _processQueue();
    }
  }

  Future<void> resumeTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    if (task.status == DownloadStatus.paused ||
        task.status == DownloadStatus.failed) {
      task.status = DownloadStatus.queued;
      task.errorLog = null;
      await _storageService.saveTask(task);
      _notify();
      _processQueue();
    }
  }

  Future<void> cancelTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    if (task.isActive) {
      await _nativeBridgeService.cancelDownload(taskId);
    }
    task.status = DownloadStatus.cancelled;
    await _storageService.saveTask(task);
    _notify();
    _processQueue();
  }

  Future<void> deleteTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    if (task.isActive) {
      await _nativeBridgeService.cancelDownload(taskId);
    }
    _tasks.removeAt(taskIndex);
    await _storageService.deleteTask(taskId);
    _notify();
    _processQueue();
  }

  Future<void> clearCompleted() async {
    _tasks.removeWhere((t) => t.status == DownloadStatus.completed);
    await _storageService.clearCompletedTasks();
    _notify();
  }

  void _processQueue() {
    final AppSettings settings = _storageService.getSettings();
    final activeCount = _tasks.where((t) => t.isActive && t.status == DownloadStatus.downloading).length;

    if (activeCount >= settings.maxConcurrentDownloads) {
      return;
    }

    final pending = _tasks.where((t) => t.status == DownloadStatus.queued).toList();
    if (pending.isEmpty) return;

    final toStart = pending.first;
    toStart.status = DownloadStatus.downloading;
    _storageService.saveTask(toStart);
    _notify();

    final effectiveArgs = List<String>.from(toStart.commandFlags);
    if (settings.useAria2c &&
        !effectiveArgs.contains('--downloader') &&
        !effectiveArgs.contains('--external-downloader')) {
      final threads = settings.aria2Threads;
      effectiveArgs.addAll([
        '-N', '$threads',
        '--downloader', 'aria2c',
        '--downloader-args', 'aria2c:-c -j $threads -x $threads -s $threads -k 1M',
      ]);
    }

    final effectiveDir = settings.downloadDirectory.trim().isNotEmpty
        ? settings.downloadDirectory.trim()
        : 'Download/Ramen';

    _nativeBridgeService.startDownload(
      taskId: toStart.id,
      url: toStart.url,
      outDir: effectiveDir,
      args: effectiveArgs,
    );
  }

  void _notify() {
    _tasksController.add(List.unmodifiable(_tasks));
  }

  void dispose() {
    _progressSubscription?.cancel();
    _tasksController.close();
    _taskCompletedController.close();
  }
}
