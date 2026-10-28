import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/di/injection.dart';
import '../../core/utils/url_validator.dart';
import '../../models/command_template.dart';
import '../../models/download_task.dart';
import '../../models/media_resource.dart';
import '../../models/ytdlp_options.dart';
import '../../services/native_bridge_service.dart';
import '../../services/storage_service.dart';
import '../../services/task_queue_service.dart';

class SearchFormatController extends ChangeNotifier {
  final NativeBridgeService _nativeBridge = getIt<NativeBridgeService>();
  final TaskQueueService _taskQueue = getIt<TaskQueueService>();
  StreamSubscription? _taskCompletedSubscription;

  final TextEditingController urlInputController = TextEditingController();

  SearchFormatController() {
    final settings = getIt<StorageService>().getSettings();
    _options = settings.toYtDlpOptions();
    _taskCompletedSubscription = _taskQueue.onTaskCompleted.listen((_) {
      clearPreview();
    });
  }

  bool _isLoading = false;
  String? _errorMessage;
  MediaResource? _currentResource;
  FormatItem? _selectedFormat;
  FormatItem? _selectedVideoFormat;
  FormatItem? _selectedAudioFormat;
  bool _includeVideo = true;
  bool _includeAudio = true;
  YtDlpOptions _options = const YtDlpOptions();
  final Set<String> _selectedPlaylistEntries = {};
  CommandTemplate _activeTemplate = CommandTemplate.defaultPresets.first;
  final List<String> _userCustomFlags = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  MediaResource? get currentResource => _currentResource;
  FormatItem? get selectedFormat => _selectedFormat;
  FormatItem? get selectedVideoFormat => _selectedVideoFormat;
  FormatItem? get selectedAudioFormat => _selectedAudioFormat;
  bool get includeVideo => _includeVideo;
  bool get includeAudio => _includeAudio;
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
    if (value) {
      _includeVideo = false;
      _includeAudio = true;
    } else {
      _includeVideo = true;
      _includeAudio = true;
    }
    if (_currentResource != null) {
      _autoSelectDefaultFormat();
    }
    notifyListeners();
  }

  void setStreamSelectionMode({
    required bool includeVideo,
    required bool includeAudio,
  }) {
    if (!includeVideo && !includeAudio) return;
    _includeVideo = includeVideo;
    _includeAudio = includeAudio;
    _syncSelectedFormat();
    notifyListeners();
  }

  void selectFormat(FormatItem format) {
    if (format.isAudioOnly) {
      if (_selectedAudioFormat?.formatId == format.formatId &&
          _includeAudio &&
          _includeVideo) {
        _includeAudio = false;
      } else {
        _selectedAudioFormat = format;
        _includeAudio = true;
      }
    } else {
      if (_selectedVideoFormat?.formatId == format.formatId &&
          _includeVideo &&
          _includeAudio) {
        _includeVideo = false;
      } else {
        _selectedVideoFormat = format;
        _includeVideo = true;
      }
    }
    _syncSelectedFormat();
    notifyListeners();
  }

  void selectVideoFormat(FormatItem? format) {
    _selectedVideoFormat = format;
    if (format != null) _includeVideo = true;
    _syncSelectedFormat();
    notifyListeners();
  }

  void selectAudioFormat(FormatItem? format) {
    _selectedAudioFormat = format;
    if (format != null) _includeAudio = true;
    _syncSelectedFormat();
    notifyListeners();
  }

  void toggleIncludeVideo(bool value) {
    _includeVideo = value;
    if (!_includeVideo && !_includeAudio) {
      _includeAudio = true;
    }
    _syncSelectedFormat();
    notifyListeners();
  }

  void toggleIncludeAudio(bool value) {
    _includeAudio = value;
    if (!_includeAudio && !_includeVideo) {
      _includeVideo = true;
    }
    _syncSelectedFormat();
    notifyListeners();
  }

  void _syncSelectedFormat() {
    if (_options.isAudioOnly || (!_includeVideo && _includeAudio)) {
      final audio = _selectedAudioFormat;
      if (audio != null) {
        _selectedFormat = audio;
      } else {
        _selectedFormat = FormatItem(
          formatId: 'bestaudio',
          ext: _options.audioFormat,
          isAudioOnly: true,
        );
      }
    } else if (_includeVideo && !_includeAudio) {
      final video = _selectedVideoFormat;
      if (video != null) {
        _selectedFormat = video;
      } else {
        _selectedFormat = FormatItem(
          formatId: 'bestvideo',
          ext: 'mp4',
          isVideoOnly: true,
        );
      }
    } else {
      final video = _selectedVideoFormat;
      final audio = _selectedAudioFormat;

      if (video != null && audio != null) {
        final combinedSize = (video.filesize ?? 0) + (audio.filesize ?? 0);
        _selectedFormat = FormatItem(
          formatId: '${video.formatId}+${audio.formatId}',
          ext: video.ext.isNotEmpty ? video.ext : 'mp4',
          resolution: video.resolution,
          height: video.height,
          width: video.width,
          fps: video.fps,
          vcodec: video.vcodec,
          acodec: audio.acodec,
          filesize: combinedSize > 0 ? combinedSize : null,
          tbr: (video.tbr ?? 0) + (audio.tbr ?? 0),
          formatNote: '${video.displayQuality} + ${audio.displayQuality}',
          isMerged: true,
        );
      } else if (video != null) {
        _selectedFormat = video;
      } else if (audio != null) {
        _selectedFormat = audio;
      }
    }
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
    _selectedVideoFormat = null;
    _selectedAudioFormat = null;
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

    final audioFormats =
        _currentResource!.formats.where((f) => f.isAudioOnly).toList();
    if (audioFormats.isNotEmpty) {
      audioFormats.sort((a, b) => (b.tbr ?? 0).compareTo(a.tbr ?? 0));
      _selectedAudioFormat = audioFormats.first;
    }

    final videoFormats =
        _currentResource!.formats.where((f) => !f.isAudioOnly).toList();
    if (videoFormats.isNotEmpty) {
      videoFormats.sort((a, b) => (b.height ?? 0).compareTo(a.height ?? 0));
      _selectedVideoFormat = videoFormats.first;
    }

    if (_options.isAudioOnly) {
      _includeVideo = false;
      _includeAudio = true;
    } else {
      _includeVideo = true;
      _includeAudio = true;
    }

    _syncSelectedFormat();
  }

  String get previewCommandLine {
    if (_currentResource == null) return '';
    final chosenFormatId = _selectedFormat?.formatId ??
        (_options.isAudioOnly ? 'bestaudio' : 'best');
    final isAudio = _options.isAudioOnly || (!_includeVideo && _includeAudio);
    final effectiveOptions = _options.copyWith(isAudioOnly: isAudio);
    return effectiveOptions.toCommandLine(
      _currentResource!.url,
      chosenFormatId,
    );
  }

  Future<DownloadTask?> startDownload({String? targetTabId}) async {
    if (_currentResource == null) return null;

    final chosen = _selectedFormat ??
        FormatItem(
          formatId: _options.isAudioOnly ? 'bestaudio' : 'best',
          ext: _options.isAudioOnly ? _options.audioFormat : 'mp4',
        );

    final isAudio = _options.isAudioOnly || (!_includeVideo && _includeAudio);

    final ext = isAudio
        ? _options.audioFormat
        : (chosen.ext.isNotEmpty ? chosen.ext : 'mp4');

    final effectiveOptions = _options.copyWith(isAudioOnly: isAudio);

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
      commandFlags: effectiveOptions.buildArgs(formatId: chosen.formatId),
      tabId: targetTabId,
    );

    await _taskQueue.enqueueTask(task);
    return task;
  }

  void reset() {
    clearPreview();
  }

  void clearPreview() {
    urlInputController.clear();
    _currentResource = null;
    _selectedFormat = null;
    _selectedVideoFormat = null;
    _selectedAudioFormat = null;
    _errorMessage = null;
    _selectedPlaylistEntries.clear();
    final settings = getIt<StorageService>().getSettings();
    _options = settings.toYtDlpOptions();
    notifyListeners();
  }

  @override
  void dispose() {
    _taskCompletedSubscription?.cancel();
    urlInputController.dispose();
    super.dispose();
  }
}
