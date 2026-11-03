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
  }

  bool _isLoading = false;
  String? _activeSearchId;
  String? _activeSearchQuery;
  bool _hasUnreadSearchResult = false;
  String? _errorMessage;
  MediaResource? _currentResource;
  MediaResource? _parentPlaylistResource;
  Set<String> _savedPlaylistSelection = {};
  FormatItem? _selectedFormat;
  FormatItem? _selectedVideoFormat;
  FormatItem? _selectedAudioFormat;
  bool _includeVideo = true;
  bool _includeAudio = true;
  YtDlpOptions _options = const YtDlpOptions();
  final Set<String> _selectedPlaylistEntries = {};
  String _playlistVideoQuality = 'best'; // 'best', '2160', '1440', '1080', '720', '480', '360'
  String _playlistVideoContainer = 'mp4'; // 'mp4', 'mkv', 'webm'
  bool _useNativePlaylistProcess = false;
  CommandTemplate _activeTemplate = CommandTemplate.defaultPresets.first;
  final List<String> _userCustomFlags = [];

  bool get isLoading => _isLoading;
  String? get activeSearchId => _activeSearchId;
  String? get activeSearchQuery => _activeSearchQuery;
  bool get hasUnreadSearchResult => _hasUnreadSearchResult;
  String? get errorMessage => _errorMessage;
  MediaResource? get currentResource => _currentResource;
  MediaResource? get parentPlaylistResource => _parentPlaylistResource;
  bool get canReturnToPlaylist => _parentPlaylistResource != null;
  FormatItem? get selectedFormat => _selectedFormat;
  FormatItem? get selectedVideoFormat => _selectedVideoFormat;
  FormatItem? get selectedAudioFormat => _selectedAudioFormat;
  bool get includeVideo => _includeVideo;
  bool get includeAudio => _includeAudio;
  YtDlpOptions get options => _options;
  bool get isAudioOnly => _options.isAudioOnly;
  Set<String> get selectedPlaylistEntries => _selectedPlaylistEntries;
  String get playlistVideoQuality => _playlistVideoQuality;
  String get playlistVideoContainer => _playlistVideoContainer;
  bool get useNativePlaylistProcess => _useNativePlaylistProcess;
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

  void setPlaylistVideoQuality(String quality) {
    _playlistVideoQuality = quality;
    notifyListeners();
  }

  void setPlaylistVideoContainer(String container) {
    _playlistVideoContainer = container;
    notifyListeners();
  }

  void setPlaylistAudioFormat(String audioFormat) {
    _options = _options.copyWith(audioFormat: audioFormat);
    notifyListeners();
  }

  void setPlaylistAudioQuality(String audioQuality) {
    _options = _options.copyWith(audioQuality: audioQuality);
    notifyListeners();
  }

  void setUseNativePlaylistProcess(bool value) {
    _useNativePlaylistProcess = value;
    notifyListeners();
  }

  void toggleLiveFromStart(bool value) {
    _options = _options.copyWith(liveFromStart: value);
    if (_currentResource != null && _currentResource!.isLive) {
      _autoSelectDefaultFormat();
    }
    notifyListeners();
  }

  void toggleHlsUseMpegts(bool value) {
    _options = _options.copyWith(hlsUseMpegts: value);
    notifyListeners();
  }

  void setWaitForVideo(int? seconds) {
    _options = _options.copyWith(
      waitForVideoSeconds: seconds,
      clearWaitForVideo: seconds == null,
    );
    notifyListeners();
  }

  /// Builds the yt-dlp format selector string for playlist batch downloads
  String get playlistFormatSelector {
    if (_options.isAudioOnly) {
      return 'bestaudio/best';
    }
    if (_playlistVideoQuality == 'best') {
      return 'bestvideo+bestaudio/best';
    }
    final h = _playlistVideoQuality;
    return 'bestvideo[height<=$h]+bestaudio/best[height<=$h]/best';
  }

  /// Builds the `--playlist-items` index specification (1-based) for selected entries
  String? get selectedPlaylistItemsSpec {
    if (_currentResource == null || !_currentResource!.isPlaylist) return null;
    final entries = _currentResource!.playlistEntries;
    if (entries.isEmpty || _selectedPlaylistEntries.length == entries.length) {
      return null; // All items selected
    }
    final indices = <int>[];
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (_selectedPlaylistEntries.contains(entry.id)) {
        indices.add(entry.playlistIndex ?? (i + 1));
      }
    }
    if (indices.isEmpty) return null;
    return indices.join(',');
  }

  void _syncSelectedFormat() {
    if (_options.isAudioOnly || (!_includeVideo && _includeAudio)) {
      final audio = _selectedAudioFormat;
      if (audio != null) {
        _selectedFormat = audio;
      } else {
        _selectedFormat = FormatItem(
          formatId: 'bestaudio/best',
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
      final isLiveEdge =
          (_currentResource?.isLive ?? false) && !_options.liveFromStart;

      // On a live YouTube stream at the live edge (without --live-from-start),
      // combining two separate live DASH/HLS streams (video+audio) causes FFmpeg
      // to exit with code 183 (AVERROR_INVALIDDATA). Use single multiplexed HLS
      // stream if available, or let yt-dlp mux only when compatible.
      if (video != null &&
          audio != null &&
          video.formatId != audio.formatId &&
          !video.isMerged &&
          !video.isHls &&
          !isLiveEdge) {
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
          protocol: video.protocol,
          filesize: combinedSize > 0 ? combinedSize : null,
          tbr: (video.tbr ?? 0) + (audio.tbr ?? 0),
          formatNote: '${video.displayQuality} + ${audio.displayQuality}',
          isMerged: true,
        );
      } else if (video != null) {
        _selectedFormat = video;
      } else if (audio != null) {
        _selectedFormat = audio;
      } else {
        _selectedFormat = FormatItem(
          formatId: 'best',
          ext: 'mp4',
          isMerged: true,
        );
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
        _currentResource!.playlistEntries
            .where((e) => e.isPlayableEntry)
            .map((e) => e.id),
      );
    } else {
      _selectedPlaylistEntries.clear();
    }
    notifyListeners();
  }

  /// Inspects a single video entry from within a playlist while preserving the parent playlist
  Future<MediaResource?> inspectPlaylistEntry(MediaResource entry) async {
    if (_currentResource != null && _currentResource!.isPlaylist) {
      _parentPlaylistResource = _currentResource;
      _savedPlaylistSelection = Set<String>.from(_selectedPlaylistEntries);
    }
    return inspectUrl(entry.url, true);
  }

  /// Restores the parent playlist view after inspecting a single playlist entry
  void returnToPlaylist() {
    if (_parentPlaylistResource == null) return;
    _currentResource = _parentPlaylistResource;
    _parentPlaylistResource = null;
    _selectedPlaylistEntries
      ..clear()
      ..addAll(_savedPlaylistSelection);
    _savedPlaylistSelection.clear();
    _selectedFormat = null;
    _selectedVideoFormat = null;
    _selectedAudioFormat = null;
    urlInputController.text = _currentResource!.url;
    notifyListeners();
  }

  void markSearchResultRead() {
    if (_hasUnreadSearchResult) {
      _hasUnreadSearchResult = false;
      notifyListeners();
    }
  }

  Future<void> cancelSearch() async {
    final idToCancel = _activeSearchId;
    _activeSearchId = null;
    _activeSearchQuery = null;
    _isLoading = false;
    notifyListeners();
    if (idToCancel != null) {
      await _nativeBridge.cancelSearch(idToCancel);
    }
  }

  Future<MediaResource?> inspectUrl([
    String? targetUrl,
    bool preserveParentPlaylist = false,
  ]) async {
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

    // Cancel any previous in-flight search before starting a new one
    if (_activeSearchId != null) {
      final prevId = _activeSearchId!;
      _activeSearchId = null;
      unawaited(_nativeBridge.cancelSearch(prevId));
    }

    final searchId = 'search_${DateTime.now().millisecondsSinceEpoch}';
    _activeSearchId = searchId;
    _activeSearchQuery = query;
    _hasUnreadSearchResult = false;
    _isLoading = true;
    _errorMessage = null;
    if (!preserveParentPlaylist) {
      _parentPlaylistResource = null;
      _savedPlaylistSelection.clear();
    }
    _currentResource = null;
    _selectedFormat = null;
    _selectedVideoFormat = null;
    _selectedAudioFormat = null;
    _selectedPlaylistEntries.clear();
    notifyListeners();

    try {
      final resource = await _nativeBridge.getFormats(
        query,
        extraArgs: _options.buildSearchArgs(),
        searchId: searchId,
      );
      if (_activeSearchId != searchId) {
        return null;
      }
      _currentResource = resource;
      _hasUnreadSearchResult = true;
      if (resource.isPlaylist) {
        _selectedPlaylistEntries.addAll(
          resource.playlistEntries
              .where((e) => e.isPlayableEntry)
              .map((e) => e.id),
        );
      } else {
        _autoSelectDefaultFormat();
      }
      return resource;
    } catch (e) {
      if (_activeSearchId != searchId) {
        return null;
      }
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (!msg.toLowerCase().contains('cancelled') &&
          !msg.toLowerCase().contains('canceled')) {
        _errorMessage = msg;
      }
      return null;
    } finally {
      if (_activeSearchId == searchId) {
        _activeSearchId = null;
        _activeSearchQuery = null;
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _autoSelectDefaultFormat() {
    if (_currentResource == null) return;

    if (_currentResource!.formats.isEmpty) {
      // Upcoming live streams or streams without pre-negotiated format tables
      _selectedVideoFormat = FormatItem(
        formatId: 'bestvideo+bestaudio/best',
        ext: 'mp4',
        resolution: _currentResource!.isUpcoming ? 'Upcoming Stream' : 'Best Quality',
        isMerged: true,
      );
      _selectedAudioFormat = FormatItem(
        formatId: 'bestaudio/best',
        ext: _options.audioFormat,
        formatNote: 'Best Audio Stream',
        isAudioOnly: true,
      );
      _syncSelectedFormat();
      return;
    }

    final isLiveEdge = _currentResource!.isLive && !_options.liveFromStart;
    final hasHlsFormats = _currentResource!.formats.any(
      (f) => f.isHls || (!f.isAudioOnly && f.isMerged),
    );

    final audioFormats = _currentResource!.formats
        .where((f) => f.isAudioOnly && !(isLiveEdge && hasHlsFormats && f.isDash))
        .toList();
    if (audioFormats.isNotEmpty) {
      audioFormats.sort(
        (a, b) => ((b.abr ?? b.tbr) ?? 0).compareTo((a.abr ?? a.tbr) ?? 0),
      );
      _selectedAudioFormat = audioFormats.first;
    } else {
      _selectedAudioFormat = null;
    }

    final videoFormats = _currentResource!.formats
        .where(
          (f) => !f.isAudioOnly && !(isLiveEdge && hasHlsFormats && f.isDash),
        )
        .toList();
    if (videoFormats.isNotEmpty) {
      videoFormats.sort((a, b) {
        // For live streams without --live-from-start, prioritize HLS (m3u8) / merged
        // formats over raw DASH video-only segments so FFmpeg doesn't fail with code 183
        if (isLiveEdge) {
          final aHls = (a.isHls || a.isMerged) ? 1 : 0;
          final bHls = (b.isHls || b.isMerged) ? 1 : 0;
          if (aHls != bHls) return bHls.compareTo(aHls);
        }
        final hCmp = (b.height ?? 0).compareTo(a.height ?? 0);
        if (hCmp != 0) return hCmp;
        return (b.tbr ?? 0).compareTo(a.tbr ?? 0);
      });
      _selectedVideoFormat = videoFormats.first;
    } else {
      _selectedVideoFormat = null;
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
    if (_currentResource!.isPlaylist) {
      final effectiveOptions = _options.copyWith(
        yesPlaylist: true,
        playlistItems: selectedPlaylistItemsSpec,
        clearPlaylistItems: selectedPlaylistItemsSpec == null,
        remuxContainer: _options.isAudioOnly ? null : _playlistVideoContainer,
      );
      return effectiveOptions.toCommandLine(
        _currentResource!.url,
        playlistFormatSelector,
      );
    }

    final chosenFormatId = _selectedFormat?.formatId ??
        (_options.isAudioOnly ? 'bestaudio/best' : 'best');
    final isAudio = _options.isAudioOnly || (!_includeVideo && _includeAudio);
    final isLive = _currentResource!.isLiveOrUpcoming;
    final effectiveOptions = _options.copyWith(isAudioOnly: isAudio);
    return effectiveOptions.toCommandLine(
      _currentResource!.url,
      chosenFormatId,
      isLiveStream: isLive,
    );
  }

  /// Starts downloading either a single media stream/live broadcast or all selected playlist items
  Future<List<DownloadTask>> startDownloadTasks({String? targetTabId}) async {
    if (_currentResource == null) return const [];

    if (_currentResource!.isPlaylist) {
      return _startPlaylistDownload(targetTabId: targetTabId);
    }

    final single = await startDownload(targetTabId: targetTabId);
    return single != null ? [single] : const [];
  }

  Future<List<DownloadTask>> _startPlaylistDownload({
    String? targetTabId,
  }) async {
    final resource = _currentResource!;
    final selectedEntries = resource.playlistEntries
        .where((e) => _selectedPlaylistEntries.contains(e.id))
        .toList();

    if (selectedEntries.isEmpty) return const [];

    final isAudio = _options.isAudioOnly;
    final ext = isAudio ? _options.audioFormat : _playlistVideoContainer;
    final formatSelector = playlistFormatSelector;

    // Mode 1: Single native yt-dlp playlist process (--yes-playlist --playlist-items ...)
    if (_useNativePlaylistProcess && !resource.isSearchResult) {
      final itemsSpec = selectedPlaylistItemsSpec;
      final effectiveOptions = _options.copyWith(
        isAudioOnly: isAudio,
        yesPlaylist: true,
        playlistItems: itemsSpec,
        clearPlaylistItems: itemsSpec == null,
        remuxContainer: isAudio ? null : _playlistVideoContainer,
      );

      final task = DownloadTask(
        id: 'task_pl_${resource.id}_${DateTime.now().millisecondsSinceEpoch}',
        url: resource.url,
        title: '${resource.title} (${selectedEntries.length} items)',
        uploader: resource.uploader,
        thumbnailUrl: resource.thumbnail,
        selectedFormatId: formatSelector,
        extension: ext,
        commandFlags: effectiveOptions.buildArgs(formatId: formatSelector),
        tabId: targetTabId,
        isPlaylistBatch: true,
      );

      await _taskQueue.enqueueTask(task);
      return [task];
    }

    // Mode 2 (Default): Enqueue individual tasks per selected playlist/search item
    final effectiveOptions = _options.copyWith(
      isAudioOnly: isAudio,
      remuxContainer: isAudio ? null : _playlistVideoContainer,
    );
    final createdTasks = <DownloadTask>[];
    final baseTs = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < selectedEntries.length; i++) {
      final item = selectedEntries[i];
      final itemIsLive = item.isLiveOrUpcoming;
      final task = DownloadTask(
        id: 'task_${item.id}_${baseTs}_$i',
        url: item.url,
        title: item.title,
        uploader: item.uploader ?? resource.uploader,
        thumbnailUrl: item.thumbnail ?? resource.thumbnail,
        durationSeconds: item.durationSeconds,
        selectedFormatId: formatSelector,
        extension: ext,
        commandFlags: effectiveOptions.buildArgs(
          formatId: formatSelector,
          isLiveStream: itemIsLive,
        ),
        tabId: targetTabId,
        isLiveStream: itemIsLive,
      );
      createdTasks.add(task);
      await _taskQueue.enqueueTask(task);
    }

    return createdTasks;
  }

  Future<DownloadTask?> startDownload({String? targetTabId}) async {
    if (_currentResource == null) return null;
    if (_currentResource!.isPlaylist) {
      final tasks = await _startPlaylistDownload(targetTabId: targetTabId);
      return tasks.isNotEmpty ? tasks.first : null;
    }

    final chosen = _selectedFormat ??
        FormatItem(
          formatId: _options.isAudioOnly ? 'bestaudio/best' : 'best',
          ext: _options.isAudioOnly ? _options.audioFormat : 'mp4',
        );

    final isAudio = _options.isAudioOnly || (!_includeVideo && _includeAudio);
    final isLive = _currentResource!.isLiveOrUpcoming;

    final ext = isAudio
        ? _options.audioFormat
        : (_options.hlsUseMpegts && isLive
              ? 'ts'
              : (chosen.ext.isNotEmpty ? chosen.ext : 'mp4'));

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
      commandFlags: effectiveOptions.buildArgs(
        formatId: chosen.formatId,
        isLiveStream: isLive,
      ),
      tabId: targetTabId,
      isLiveStream: isLive,
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
    _parentPlaylistResource = null;
    _savedPlaylistSelection.clear();
    _selectedFormat = null;
    _selectedVideoFormat = null;
    _selectedAudioFormat = null;
    _errorMessage = null;
    _hasUnreadSearchResult = false;
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
