import 'package:flutter/material.dart';
import '../../core/di/injection.dart';
import '../../core/utils/url_validator.dart';
import '../../models/command_template.dart';
import '../../models/download_task.dart';
import '../../models/media_resource.dart';
import '../../services/native_bridge_service.dart';
import '../../services/task_queue_service.dart';
import '../../services/template_engine_service.dart';

class SearchFormatController extends ChangeNotifier {
  final NativeBridgeService _nativeBridge = getIt<NativeBridgeService>();
  final TemplateEngineService _templateEngine = getIt<TemplateEngineService>();
  final TaskQueueService _taskQueue = getIt<TaskQueueService>();

  final TextEditingController urlInputController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  MediaResource? _currentResource;
  FormatItem? _selectedFormat;
  bool _isAudioOnly = false;
  List<String> _userCustomFlags = [];
  CommandTemplate _activeTemplate = CommandTemplate.defaultPresets.first;

  // Playlist selection tracking
  final Set<String> _selectedPlaylistEntries = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  MediaResource? get currentResource => _currentResource;
  FormatItem? get selectedFormat => _selectedFormat;
  bool get isAudioOnly => _isAudioOnly;
  List<String> get userCustomFlags => _userCustomFlags;
  CommandTemplate get activeTemplate => _activeTemplate;
  Set<String> get selectedPlaylistEntries => _selectedPlaylistEntries;

  void setActiveTemplate(CommandTemplate template) {
    _activeTemplate = template;
    notifyListeners();
  }

  void setCustomFlags(List<String> flags) {
    _userCustomFlags = List.from(flags);
    notifyListeners();
  }

  void addCustomFlag(String flag) {
    final trimmed = flag.trim();
    if (trimmed.isNotEmpty && !_userCustomFlags.contains(trimmed)) {
      _userCustomFlags.add(trimmed);
      notifyListeners();
    }
  }

  void removeCustomFlag(String flag) {
    _userCustomFlags.remove(flag);
    notifyListeners();
  }

  void setAudioOnly(bool value) {
    _isAudioOnly = value;
    if (_currentResource != null) {
      _autoSelectDefaultFormat();
    }
    notifyListeners();
  }

  void selectFormat(FormatItem format) {
    _selectedFormat = format;
    notifyListeners();
  }

  void togglePlaylistItem(String id) {
    if (_selectedPlaylistEntries.contains(id)) {
      _selectedPlaylistEntries.remove(id);
    } else {
      _selectedPlaylistEntries.add(id);
    }
    notifyListeners();
  }

  void selectAllPlaylistItems(bool selectAll) {
    if (_currentResource == null || !_currentResource!.isPlaylist) return;
    if (selectAll) {
      _selectedPlaylistEntries.addAll(
        _currentResource!.playlistEntries.map((e) => e.id),
      );
    } else {
      _selectedPlaylistEntries.clear();
    }
    notifyListeners();
  }

  /// Runs the Find Formats command
  Future<void> inspectUrl([String? targetUrl]) async {
    final query = (targetUrl ?? urlInputController.text).trim();
    if (query.isEmpty) {
      _errorMessage = 'Please provide a valid YouTube or media URL';
      notifyListeners();
      return;
    }

    if (!UrlValidator.isValidMediaUrl(query)) {
      _errorMessage = 'Invalid URL format. Please paste a full media link.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _currentResource = null;
    _selectedFormat = null;
    _selectedPlaylistEntries.clear();
    notifyListeners();

    try {
      final resource = await _nativeBridge.getFormats(
        query,
        extraArgs: _userCustomFlags,
      );

      _currentResource = resource;
      if (resource.isPlaylist) {
        _selectedPlaylistEntries.addAll(resource.playlistEntries.map((e) => e.id));
      } else {
        _autoSelectDefaultFormat();
      }
    } catch (e) {
      _errorMessage = 'Failed to extract formats: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _autoSelectDefaultFormat() {
    if (_currentResource == null || _currentResource!.formats.isEmpty) return;

    if (_isAudioOnly) {
      final audioFormats =
          _currentResource!.formats.where((f) => f.isAudioOnly).toList();
      if (audioFormats.isNotEmpty) {
        audioFormats.sort((a, b) => (b.tbr ?? 0).compareTo(a.tbr ?? 0));
        _selectedFormat = audioFormats.first;
      }
    } else {
      final videoFormats =
          _currentResource!.formats.where((f) => !f.isAudioOnly).toList();
      if (videoFormats.isNotEmpty) {
        videoFormats.sort((a, b) => (b.height ?? 0).compareTo(a.height ?? 0));
        _selectedFormat = videoFormats.first;
      }
    }
  }

  /// Builds preview CLI command string
  String get previewCommandLine {
    if (_currentResource == null) return '';
    final args = _templateEngine.buildDownloadArgs(
      template: _activeTemplate,
      selectedFormat: _selectedFormat ??
          FormatItem(formatId: 'best', ext: _isAudioOnly ? 'm4a' : 'mp4'),
      isAudioOnly: _isAudioOnly,
      userCustomFlags: _userCustomFlags,
    );
    return _templateEngine.formatCommandLine(_currentResource!.url, args);
  }

  /// Enqueues the selected format(s) for download
  Future<int> startDownload() async {
    if (_currentResource == null) return 0;

    int queuedCount = 0;

    if (_currentResource!.isPlaylist) {
      final itemsToDownload = _currentResource!.playlistEntries
          .where((e) => _selectedPlaylistEntries.contains(e.id))
          .toList();

      for (final item in itemsToDownload) {
        final task = DownloadTask(
          id: 'task_${item.id}_${DateTime.now().millisecondsSinceEpoch}',
          url: item.url,
          title: item.title,
          uploader: item.uploader,
          thumbnailUrl: item.thumbnail,
          durationSeconds: item.durationSeconds,
          selectedFormatId: 'best',
          extension: _isAudioOnly ? 'm4a' : 'mp4',
          commandFlags: _templateEngine.buildDownloadArgs(
            template: _activeTemplate,
            selectedFormat: FormatItem(formatId: 'best', ext: 'mp4'),
            isAudioOnly: _isAudioOnly,
            userCustomFlags: _userCustomFlags,
          ),
        );
        await _taskQueue.enqueueTask(task);
        queuedCount++;
      }
    } else {
      final chosen = _selectedFormat ??
          FormatItem(formatId: 'best', ext: _isAudioOnly ? 'm4a' : 'mp4');

      final task = DownloadTask(
        id: 'task_${_currentResource!.id}_${DateTime.now().millisecondsSinceEpoch}',
        url: _currentResource!.url,
        title: _currentResource!.title,
        uploader: _currentResource!.uploader,
        thumbnailUrl: _currentResource!.thumbnail,
        durationSeconds: _currentResource!.durationSeconds,
        selectedFormatId: chosen.formatId,
        extension: _isAudioOnly ? 'm4a' : (chosen.ext.isNotEmpty ? chosen.ext : 'mp4'),
        totalBytes: chosen.filesize,
        commandFlags: _templateEngine.buildDownloadArgs(
          template: _activeTemplate,
          selectedFormat: chosen,
          isAudioOnly: _isAudioOnly,
          userCustomFlags: _userCustomFlags,
        ),
      );
      await _taskQueue.enqueueTask(task);
      queuedCount++;
    }

    return queuedCount;
  }

  void reset() {
    urlInputController.clear();
    _currentResource = null;
    _selectedFormat = null;
    _errorMessage = null;
    _selectedPlaylistEntries.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    urlInputController.dispose();
    super.dispose();
  }
}
