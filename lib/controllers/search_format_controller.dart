import 'package:flutter/material.dart';
import '../../core/di/injection.dart';
import '../../core/utils/url_validator.dart';
import '../../models/command_template.dart';
import '../../models/download_task.dart';
import '../../models/media_resource.dart';
import '../../models/ytdlp_options.dart';
import '../../services/native_bridge_service.dart';
import '../../services/task_queue_service.dart';

class SearchFormatController extends ChangeNotifier {
  final NativeBridgeService _nativeBridge = getIt<NativeBridgeService>();
  final TaskQueueService _taskQueue = getIt<TaskQueueService>();

  final TextEditingController urlInputController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  MediaResource? _currentResource;
  FormatItem? _selectedFormat;
  YtDlpOptions _options = const YtDlpOptions();
  final Set<String> _selectedPlaylistEntries = {};
  CommandTemplate _activeTemplate = CommandTemplate.defaultPresets.first;
  final List<String> _userCustomFlags = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  MediaResource? get currentResource => _currentResource;
  FormatItem? get selectedFormat => _selectedFormat;
  YtDlpOptions get options => _options;
  bool get isAudioOnly => _options.isAudioOnly;
  Set<String> get selectedPlaylistEntries => _selectedPlaylistEntries;
  CommandTemplate get activeTemplate => _activeTemplate;
  List<String> get userCustomFlags => _userCustomFlags;

  void setUrl(String url) {
    urlInputController.text = url;
    notifyListeners();
  }

  void clearUrl() {
    urlInputController.clear();
    notifyListeners();
  }

  void setActiveTemplate(CommandTemplate template) {
    _activeTemplate = template;
    notifyListeners();
  }

  void addCustomFlag(String flag) {
    final clean = flag.trim();
    if (clean.isNotEmpty && !_userCustomFlags.contains(clean)) {
      _userCustomFlags.add(clean);
      final merged = '${_options.rawCustomArgs} $clean'.trim();
      _options = _options.copyWith(rawCustomArgs: merged);
      notifyListeners();
    }
  }

  void removeCustomFlag(String flag) {
    _userCustomFlags.remove(flag);
    notifyListeners();
  }

  void updateOptions(YtDlpOptions newOptions) {
    _options = newOptions;
    if (_currentResource != null) {
      _autoSelectDefaultFormat();
    }
    notifyListeners();
  }

  void setAudioOnly(bool value) {
    _options = _options.copyWith(isAudioOnly: value);
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

  Future<MediaResource?> inspectUrl([String? targetUrl]) async {
    if (targetUrl != null && targetUrl.trim().isNotEmpty) {
      urlInputController.text = targetUrl.trim();
    }
    final query = urlInputController.text.trim();
    if (query.isEmpty) {
      _errorMessage = 'Please enter a search query or paste a media link';
      notifyListeners();
      return null;
    }

    if (!UrlValidator.isValidInput(query)) {
      _errorMessage = 'Invalid input. Please enter search terms or a media URL.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    _currentResource = null;
    _selectedFormat = null;
    _selectedPlaylistEntries.clear();
    notifyListeners();

    try {
      final resource = await _nativeBridge.getFormats(query);
      _currentResource = resource;
      if (resource.isPlaylist) {
        _selectedPlaylistEntries.addAll(resource.playlistEntries.map((e) => e.id));
      } else {
        _autoSelectDefaultFormat();
      }
      return resource;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _autoSelectDefaultFormat() {
    if (_currentResource == null || _currentResource!.formats.isEmpty) return;

    if (_options.isAudioOnly) {
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

  String get previewCommandLine {
    if (_currentResource == null) return '';
    final chosenFormatId = _selectedFormat?.formatId ?? (_options.isAudioOnly ? 'bestaudio' : 'best');
    return _options.toCommandLine(_currentResource!.url, chosenFormatId);
  }

  Future<DownloadTask?> startDownload({String? targetTabId}) async {
    if (_currentResource == null) return null;

    final chosen = _selectedFormat ??
        FormatItem(
          formatId: _options.isAudioOnly ? 'bestaudio' : 'best',
          ext: _options.isAudioOnly ? _options.audioFormat : 'mp4',
        );

    final ext = _options.isAudioOnly
        ? _options.audioFormat
        : (chosen.ext.isNotEmpty ? chosen.ext : 'mp4');

    final task = DownloadTask(
      id: 'task_${_currentResource!.id}_${DateTime.now().millisecondsSinceEpoch}',
      url: _currentResource!.url,
      title: _currentResource!.title,
      uploader: _currentResource!.uploader,
      thumbnailUrl: _currentResource!.thumbnail,
      durationSeconds: _currentResource!.durationSeconds,
      selectedFormatId: chosen.formatId,
      extension: ext,
      totalBytes: chosen.filesize,
      commandFlags: _options.buildArgs(formatId: chosen.formatId),
      tabId: targetTabId,
    );

    await _taskQueue.enqueueTask(task);
    return task;
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
