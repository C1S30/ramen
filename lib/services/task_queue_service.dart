import 'dart:async';
import '../core/utils/formatters.dart';
import '../models/app_settings.dart';
import '../models/download_task.dart';
import 'native_bridge_service.dart';
import 'storage_service.dart';

class TaskQueueService {
  final StorageService _storageService;
  final NativeBridgeService _nativeBridgeService;

  final List<DownloadTask> _tasks = [];
  final Set<String> _pausedTaskIds = {};
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
    final loaded = _storageService.getAllTasks().where(
      (t) => t.status != DownloadStatus.cancelled,
    );
    for (final t in loaded) {
      if (t.status == DownloadStatus.paused) {
        _pausedTaskIds.add(t.id);
      }
      _tasks.add(t);
    }
    _notify();
  }

  void _listenToProgress() {
    _progressSubscription =
        _nativeBridgeService.downloadStream.listen((data) async {
      final taskId = data['taskId'] as String?;
      if (taskId == null) return;

      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex == -1) return;

      final task = _tasks[taskIndex];
      final statusStr = data['status'] as String?;

      // Ignore late process-termination events for a task that was paused by the user
      if (_pausedTaskIds.contains(taskId) ||
          task.status == DownloadStatus.paused) {
        return;
      }

      final filePath = data['filePath']?.toString();
      if (filePath != null && filePath.trim().isNotEmpty) {
        task.localFilePath = filePath.trim();
      }

      final fileSize = (data['fileSize'] as num?)?.toInt();
      if (fileSize != null && fileSize > 0) {
        task.totalBytes = fileSize;
      }

      final log = data['log']?.toString();
      if (log != null && log.isNotEmpty) {
        task.appendLog(log);
      }

      if (statusStr == 'COMPLETED') {
        task.status = DownloadStatus.completed;
        task.completedAt = DateTime.now();
        task.progress = 100.0;
        task.speed = '0.0 KB/s';
        task.eta = 'Done';

        if (task.localFilePath == null || task.localFilePath!.isEmpty) {
          final settings = _storageService.getSettings();
          final effectiveDir = settings.downloadDirectory.trim().isNotEmpty
              ? settings.downloadDirectory.trim()
              : 'Download/Ramen';
          final resolved = await _nativeBridgeService.resolveTaskFile(
            title: task.title,
            outDir: effectiveDir,
            ext: task.extension,
          );
          if (resolved != null && resolved.isNotEmpty) {
            task.localFilePath = resolved;
          }
        }

        await _storageService.saveTask(task);
        _taskCompletedController.add(task);
        _notify();
        _processQueue();
      } else if (statusStr == 'FAILED') {
        task.status = DownloadStatus.failed;
        task.errorLog = Formatters.cleanErrorMessage(data['error']?.toString());
        await _storageService.saveTask(task);
        _notify();
        _processQueue();
      } else if (statusStr == 'CANCELLED') {
        final removeIndex = _tasks.indexWhere((t) => t.id == taskId);
        if (removeIndex != -1) {
          _tasks.removeAt(removeIndex);
        }
        await _storageService.deleteTask(taskId);
        _notify();
        _processQueue();
      } else if (statusStr == 'DOWNLOADING') {
        final incomingProgress = (data['progress'] as num?)?.toDouble();
        if (incomingProgress != null && incomingProgress > 0) {
          task.progress = incomingProgress;
        }
        final incomingSpeed = data['speed']?.toString();
        if (incomingSpeed != null && incomingSpeed.isNotEmpty) {
          task.speed = incomingSpeed;
        }
        final incomingEta = data['eta']?.toString();
        if (incomingEta != null && incomingEta.isNotEmpty) {
          task.eta = incomingEta;
        }
        task.status = DownloadStatus.downloading;
        _notify();
      }
    });
  }

  Future<void> enqueueTask(DownloadTask task) async {
    _pausedTaskIds.remove(task.id);
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
      _pausedTaskIds.add(taskId);
      task.status = DownloadStatus.paused;
      task.speed = 'PAUSED';
      task.eta = '--:--';
      await _storageService.saveTask(task);
      _notify();
      await _nativeBridgeService.cancelDownload(taskId);
      _processQueue();
    }
  }

  Future<void> resumeTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    if (task.status == DownloadStatus.paused ||
        task.status == DownloadStatus.failed) {
      _pausedTaskIds.remove(taskId);
      task.status = DownloadStatus.queued;
      task.errorLog = null;
      task.speed = 'Resuming...';
      task.eta = '--:--';
      await _storageService.saveTask(task);
      _notify();
      _processQueue();
    }
  }

  Future<void> cancelTask(String taskId) async {
    _pausedTaskIds.remove(taskId);
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    final wasActive = task.isActive;
    _tasks.removeAt(taskIndex);
    await _storageService.deleteTask(taskId);
    _notify();

    if (wasActive) {
      await _nativeBridgeService.cancelDownload(taskId);
    }
    _processQueue();
  }

  Future<void> deleteTask(String taskId) async {
    await cancelTask(taskId);
  }

  Future<void> clearCompleted() async {
    _tasks.removeWhere((t) => t.status == DownloadStatus.completed);
    await _storageService.clearCompletedTasks();
    _notify();
  }

  void _processQueue() {
    final AppSettings settings = _storageService.getSettings();
    final activeCount = _tasks
        .where((t) => t.isActive && t.status == DownloadStatus.downloading)
        .length;

    if (activeCount >= settings.maxConcurrentDownloads) {
      return;
    }

    final pending =
        _tasks.where((t) => t.status == DownloadStatus.queued).toList();
    if (pending.isEmpty) return;

    final toStart = pending.first;
    _pausedTaskIds.remove(toStart.id);
    toStart.status = DownloadStatus.downloading;
    _storageService.saveTask(toStart);
    _notify();

    final effectiveArgs = List<String>.from(toStart.commandFlags);
    if (!toStart.isLiveStream &&
        !effectiveArgs.contains('-c') &&
        !effectiveArgs.contains('--continue')) {
      effectiveArgs.add('--continue');
    }
    if (settings.useAria2c &&
        !toStart.isLiveStream &&
        !effectiveArgs.contains('--downloader') &&
        !effectiveArgs.contains('--external-downloader')) {
      final threads = settings.aria2Threads;
      effectiveArgs.addAll([
        '-N',
        '$threads',
        '--downloader',
        'aria2c',
        '--downloader-args',
        'aria2c:-c -j $threads -x $threads -s $threads -k 1M',
      ]);
    }

    final effectiveDir = settings.downloadDirectory.trim().isNotEmpty
        ? settings.downloadDirectory.trim()
        : 'Download/Ramen';

    _nativeBridgeService.startDownload(
      taskId: toStart.id,
      url: toStart.url,
      title: toStart.title,
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
