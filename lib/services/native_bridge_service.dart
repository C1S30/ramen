import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/media_resource.dart';

class NativeBridgeService {
  static const MethodChannel _engineChannel = MethodChannel(
    'com.ramen.downloader/engine',
  );
  static const EventChannel _streamChannel = EventChannel(
    'com.ramen.downloader/download_stream',
  );

  final StreamController<Map<String, dynamic>> _streamController =
      StreamController<Map<String, dynamic>>.broadcast();

  StreamSubscription? _nativeSubscription;
  bool _isInitialized = false;

  // Active desktop download processes (taskId -> Process)
  final Map<String, Process> _activeDesktopProcesses = {};

  // Active desktop search processes (searchId -> Process)
  final Map<String, Process> _activeDesktopSearchProcesses = {};
  final Set<String> _cancelledSearchIds = {};

  NativeBridgeService() {
    _bindStream();
  }

  void _bindStream() {
    try {
      _nativeSubscription = _streamChannel.receiveBroadcastStream().listen(
        (dynamic rawData) {
          if (rawData is Map) {
            final mapped = Map<String, dynamic>.from(rawData);
            _streamController.add(mapped);
          }
        },
        onError: (dynamic error) {
          debugPrint('Download stream error: $error');
        },
      );
    } catch (e) {
      debugPrint('EventChannel setup warning: $e');
    }
  }

  Stream<Map<String, dynamic>> get downloadStream => _streamController.stream;

  /// Resolves raw user input (URL or search keywords) into a valid yt-dlp target
  String resolveTarget(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;

    // Check for ytsearch or other search prefixes
    if (RegExp(r'^[a-z]+search\d*:', caseSensitive: false).hasMatch(trimmed)) {
      return trimmed;
    }

    // Direct HTTP/HTTPS URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final igMatch = RegExp(
        r'instagram\.com/(?:reels?|p|tv)/([A-Za-z0-9_-]+)',
        caseSensitive: false,
      ).firstMatch(trimmed);
      if (igMatch != null && !trimmed.contains('/share/')) {
        final shortcode = igMatch.group(1)!;
        final kind = trimmed.toLowerCase().contains('/p/') ? 'p' : 'reel';
        return 'https://www.instagram.com/$kind/$shortcode/';
      }
      return trimmed;
    }

    // Common video domains without protocol
    if (trimmed.startsWith('www.youtube.com/') ||
        trimmed.startsWith('youtube.com/') ||
        trimmed.startsWith('youtu.be/') ||
        trimmed.startsWith('m.youtube.com/')) {
      return 'https://$trimmed';
    }

    // Generic domain without protocol (e.g. vimeo.com/...)
    if (trimmed.contains('.') && !trimmed.contains(' ')) {
      return 'https://$trimmed';
    }

    // Default to YouTube Search for keyword queries
    return 'ytsearch10:$trimmed';
  }

  /// Initializes the embedded yt-dlp, FFmpeg, and aria2c binaries
  Future<bool> initEngine() async {
    if (_isInitialized) return true;
    try {
      if (Platform.isAndroid) {
        final result = await _engineChannel.invokeMethod<bool>('initEngine');
        _isInitialized = result ?? false;
        return _isInitialized;
      }
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Platform initEngine failed: $e');
      return false;
    }
  }

  /// Fetches versions of yt-dlp, FFmpeg, and aria2c
  Future<Map<String, String>> getEngineVersions() async {
    if (Platform.isAndroid) {
      try {
        final res = await _engineChannel.invokeMapMethod<String, String>(
          'getEngineVersions',
        );
        if (res != null) return res;
      } catch (e) {
        debugPrint('Android getEngineVersions error: $e');
      }
      return {'ytdlp': 'N/A', 'ffmpeg': 'N/A', 'aria2c': 'N/A', 'node': 'N/A'};
    }

    // Desktop platform: query installed CLI binaries
    String ytDlpVer = 'Not installed';
    String ffmpegVer = 'Not installed';
    String aria2cVer = 'Not installed';
    String nodeVer = 'Not installed';

    try {
      final ytRes = await Process.run('yt-dlp', [
        '--version',
      ], runInShell: true);
      if (ytRes.exitCode == 0 && ytRes.stdout.toString().trim().isNotEmpty) {
        ytDlpVer = ytRes.stdout.toString().trim();
      }
    } catch (_) {}

    try {
      final ffRes = await Process.run('ffmpeg', ['-version'], runInShell: true);
      if (ffRes.exitCode == 0) {
        final firstLine = ffRes.stdout.toString().split('\n').first.trim();
        ffmpegVer = firstLine.isNotEmpty ? firstLine : 'Available';
      }
    } catch (_) {}

    try {
      final ariaRes = await Process.run('aria2c', [
        '--version',
      ], runInShell: true);
      if (ariaRes.exitCode == 0) {
        final firstLine = ariaRes.stdout.toString().split('\n').first.trim();
        aria2cVer = firstLine.isNotEmpty ? firstLine : 'Available';
      }
    } catch (_) {}

    try {
      final nodeRes = await Process.run('node', [
        '--version',
      ], runInShell: true);
      if (nodeRes.exitCode == 0 &&
          nodeRes.stdout.toString().trim().isNotEmpty) {
        nodeVer = nodeRes.stdout.toString().trim();
      }
    } catch (_) {}

    return {
      'ytdlp': ytDlpVer,
      'ffmpeg': ffmpegVer,
      'aria2c': aria2cVer,
      'node': nodeVer,
    };
  }

  /// Triggers update of the yt-dlp binary on the chosen release channel ('nightly' or 'stable')
  Future<String> updateEngine({String channel = 'nightly'}) async {
    if (Platform.isAndroid) {
      try {
        final newVersion = await _engineChannel.invokeMethod<String>(
          'updateEngine',
          {'channel': channel},
        );
        return newVersion ?? 'Updated to latest $channel';
      } catch (e) {
        throw Exception('Update failed: $e');
      }
    }

    try {
      final updateArgs = channel == 'nightly'
          ? ['--update-to', 'nightly']
          : ['-U'];
      final res = await Process.run('yt-dlp', updateArgs, runInShell: true);
      final out = res.stdout.toString().trim();
      final err = res.stderr.toString().trim();
      return out.isNotEmpty
          ? out
          : (err.isNotEmpty ? err : 'yt-dlp update ($channel) executed');
    } catch (e) {
      throw Exception('Update failed: $e');
    }
  }

  /// Silently refreshes WebView cookies + User-Agent in the background (Android)
  Future<bool> refreshSilentCookies([
    String url = 'https://www.youtube.com',
  ]) async {
    if (Platform.isAndroid) {
      try {
        final res = await _engineChannel.invokeMethod<bool>(
          'refreshSilentCookies',
          {'url': url},
        );
        return res ?? false;
      } catch (_) {}
    }
    return false;
  }

  /// Saves Netscape cookies.txt content to app storage and returns its file path
  Future<String> saveUserCookies(String content) async {
    if (Platform.isAndroid) {
      try {
        final path = await _engineChannel.invokeMethod<String>(
          'saveUserCookies',
          {'content': content},
        );
        return path ?? '';
      } catch (e) {
        debugPrint('saveUserCookies error: $e');
      }
    }
    try {
      final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}ramen_user_cookies.txt',
      );
      if (content.trim().isEmpty) {
        if (file.existsSync()) file.deleteSync();
        return '';
      }
      final normalized = content.trim().startsWith('# Netscape HTTP Cookie File')
          ? content.trim()
          : '# Netscape HTTP Cookie File\n${content.trim()}\n';
      await file.writeAsString(normalized);
      return file.path;
    } catch (_) {
      return '';
    }
  }

  /// Reads saved user cookies.txt content if any
  Future<String> getUserCookies() async {
    if (Platform.isAndroid) {
      try {
        return await _engineChannel.invokeMethod<String>('getUserCookies') ?? '';
      } catch (_) {
        return '';
      }
    }
    try {
      final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}ramen_user_cookies.txt',
      );
      if (file.existsSync()) return await file.readAsString();
    } catch (_) {}
    return '';
  }

  /// Retrieves any URL shared to the app via Android ACTION_SEND intent
  Future<String?> getSharedUrl() async {
    try {
      if (Platform.isAndroid) {
        return await _engineChannel.invokeMethod<String>('getSharedUrl');
      }
    } catch (e) {
      debugPrint('Shared url check: $e');
    }
    return null;
  }

  /// Syncs background processing and notification settings to the native Android service
  Future<void> setBackgroundConfig({
    required bool enableBackgroundProcessing,
    required bool backgroundNotifications,
  }) async {
    if (Platform.isAndroid) {
      try {
        await _engineChannel.invokeMethod('setBackgroundConfig', {
          'enableBackgroundProcessing': enableBackgroundProcessing,
          'backgroundNotifications': backgroundNotifications,
        });
      } catch (e) {
        debugPrint('Failed to sync background config: $e');
      }
    }
  }

  /// Checks whether Android battery optimizations are ignored for reliable background tasks
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (Platform.isAndroid) {
      try {
        final res = await _engineChannel.invokeMethod<bool>(
          'isIgnoringBatteryOptimizations',
        );
        return res ?? true;
      } catch (_) {}
    }
    return true;
  }

  /// Opens the Android system dialog requesting unrestricted battery usage
  Future<void> requestIgnoreBatteryOptimizations() async {
    if (Platform.isAndroid) {
      try {
        await _engineChannel.invokeMethod('requestIgnoreBatteryOptimizations');
      } catch (e) {
        debugPrint('Battery optimization request error: $e');
      }
    }
  }

  /// Cancels an active format/search inspection by searchId
  Future<void> cancelSearch(String searchId) async {
    _cancelledSearchIds.add(searchId);
    if (Platform.isAndroid) {
      try {
        await _engineChannel.invokeMethod('cancelSearch', {
          'searchId': searchId,
        });
      } catch (e) {
        debugPrint('Cancel search error: $e');
      }
      return;
    }

    final proc = _activeDesktopSearchProcesses.remove(searchId);
    if (proc != null) {
      if (Platform.isWindows) {
        try {
          await Process.run('taskkill', ['/F', '/T', '/PID', '${proc.pid}']);
        } catch (_) {
          proc.kill(ProcessSignal.sigkill);
        }
      } else {
        proc.kill(ProcessSignal.sigterm);
      }
    }
  }

  /// Inspects formats using yt-dlp ('URL -F' template only)
  Future<MediaResource> getFormats(
    String urlOrQuery, {
    List<String> extraArgs = const [],
    String? searchId,
  }) async {
    final target = resolveTarget(urlOrQuery);
    if (target.isEmpty) {
      throw Exception('Target URL or search query cannot be empty');
    }

    final effectiveSearchId =
        searchId ?? 'search_${DateTime.now().millisecondsSinceEpoch}';
    _cancelledSearchIds.remove(effectiveSearchId);

    if (Platform.isAndroid) {
      if (!_isInitialized) {
        await initEngine();
      }
      final rawOut = await _engineChannel.invokeMethod<String>('getFormats', {
        'url': target,
        'searchId': effectiveSearchId,
        'extraArgs': extraArgs,
      });

      if (_cancelledSearchIds.remove(effectiveSearchId)) {
        throw Exception('Search cancelled');
      }

      if (rawOut != null && rawOut.trim().isNotEmpty) {
        return MediaResource.parseOutput(rawOut, target);
      } else {
        throw Exception('No media information returned by yt-dlp');
      }
    }

    // Desktop execution: invoke local yt-dlp using 'URL -F' template only
    return await _getFormatsViaDesktopCli(
      target,
      extraArgs,
      effectiveSearchId,
    );
  }

  Future<MediaResource> _getFormatsViaDesktopCli(
    String target,
    List<String> extraArgs,
    String searchId,
  ) async {
    final configFile = await _getOrCreateConfigFile();

    // Seal method: Try extracting full JSON metadata first
    try {
      final jsonArgs = [
        '--config-locations',
        configFile.path,
        '--dump-single-json',
        '--no-warnings',
        '--flat-playlist',
        ...extraArgs,
        target,
      ];
      final jsonOut = await _runCancellableSearchProcess(jsonArgs, searchId);
      if (jsonOut != null && jsonOut.trim().isNotEmpty) {
        return MediaResource.parseOutput(jsonOut.trim(), target);
      }
    } catch (e) {
      if (_cancelledSearchIds.remove(searchId) ||
          e.toString().contains('Search cancelled')) {
        throw Exception('Search cancelled');
      }
      // Fallback to table extraction below
    }

    if (_cancelledSearchIds.remove(searchId)) {
      throw Exception('Search cancelled');
    }

    final cliArgs = [
      '--config-locations',
      configFile.path,
      target,
      '-F',
      ...extraArgs,
    ];

    final rawOut = await _runCancellableSearchProcess(
      cliArgs,
      searchId,
      throwOnError: true,
    );

    if (_cancelledSearchIds.remove(searchId)) {
      throw Exception('Search cancelled');
    }

    if (rawOut == null || rawOut.trim().isEmpty) {
      throw Exception('yt-dlp returned empty output for "$target"');
    }

    return MediaResource.parseOutput(rawOut.trim(), target);
  }

  Future<String?> _runCancellableSearchProcess(
    List<String> args,
    String searchId, {
    bool throwOnError = false,
  }) async {
    Process process;
    try {
      process = await Process.start('yt-dlp', args, runInShell: true);
    } catch (e) {
      if (throwOnError) {
        throw Exception(
          'yt-dlp execution error: $e. Ensure yt-dlp is installed and in PATH.',
        );
      }
      return null;
    }

    _activeDesktopSearchProcesses[searchId] = process;
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    final stdoutDone = process.stdout
        .transform(utf8.decoder)
        .listen((chunk) => stdoutBuffer.write(chunk))
        .asFuture<void>();
    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .listen((chunk) => stderrBuffer.write(chunk))
        .asFuture<void>();

    final exitCode = await process.exitCode;
    await Future.wait([stdoutDone, stderrDone]);
    _activeDesktopSearchProcesses.remove(searchId);

    if (_cancelledSearchIds.contains(searchId)) {
      throw Exception('Search cancelled');
    }

    if (exitCode != 0) {
      if (throwOnError) {
        final err = stderrBuffer.toString().trim();
        throw Exception(
          err.isNotEmpty ? err : 'yt-dlp exited with error code $exitCode',
        );
      }
      return null;
    }

    return stdoutBuffer.toString();
  }

  Future<File> _getOrCreateConfigFile() async {
    final tempDir = Directory.systemTemp;
    final configFile = File(
      '${tempDir.path}${Platform.pathSeparator}yt-dlp.conf',
    );

    String nodePath = 'node';
    bool supportsRuntimes = true;
    try {
      final res = await Process.run('yt-dlp', ['--help'], runInShell: true);
      if (res.exitCode == 0) {
        supportsRuntimes = res.stdout.toString().contains('--no-js-runtimes');
      }
    } catch (_) {}

    try {
      final whichCmd = Platform.isWindows ? 'where' : 'which';
      final res = await Process.run(whichCmd, ['node'], runInShell: true);
      if (res.exitCode == 0) {
        final out = res.stdout
            .toString()
            .trim()
            .split(RegExp(r'[\r\n]+'))
            .first
            .trim();
        if (out.isNotEmpty) {
          nodePath = out;
        }
      }
    } catch (_) {}

    final configContent = StringBuffer()
      ..writeln('# yt-dlp configuration file generated by Ramen');
    if (supportsRuntimes) {
      configContent
        ..writeln('--no-js-runtimes')
        ..writeln('--js-runtimes node:$nodePath')
        ..writeln('--js-runtimes node');
    } else {
      configContent.writeln(
        '# Legacy yt-dlp version detected. Run `yt-dlp -U` to update and enable JS runtime flags.',
      );
    }

    await configFile.writeAsString(configContent.toString());
    return configFile;
  }

  /// Starts downloading the target stream with aria2c + FFmpeg muxing
  Future<bool> startDownload({
    required String taskId,
    required String url,
    required String outDir,
    required List<String> args,
    String? title,
  }) async {
    if (Platform.isAndroid) {
      if (!_isInitialized) {
        await initEngine();
      }
      final result = await _engineChannel.invokeMethod<bool>('startDownload', {
        'taskId': taskId,
        'url': url,
        'title': title ?? url,
        'outDir': outDir,
        'args': args,
      });
      return result ?? false;
    }

    // Desktop platform: run real download via yt-dlp process
    return _startDesktopDownload(
      taskId: taskId,
      url: url,
      outDir: outDir,
      args: args,
    );
  }

  Future<bool> _startDesktopDownload({
    required String taskId,
    required String url,
    required String outDir,
    required List<String> args,
  }) async {
    try {
      Directory targetDir;
      if (outDir.isNotEmpty && Directory(outDir).isAbsolute) {
        targetDir = Directory(outDir);
      } else {
        final home =
            Platform.environment['USERPROFILE'] ??
            Platform.environment['HOME'] ??
            Directory.current.path;
        final sub = (outDir.isEmpty || outDir == 'Download/Ramen')
            ? 'Downloads${Platform.pathSeparator}Ramen'
            : outDir.replaceAll('/', Platform.pathSeparator);
        targetDir = Directory('$home${Platform.pathSeparator}$sub');
      }
      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      final outTemplate =
          '${targetDir.path}${Platform.pathSeparator}%(title).200B.%(ext)s';
      final configFile = await _getOrCreateConfigFile();
      // On desktop, sanitize Android's libaria2c.so back to aria2c binary name
      final sanitizedArgs = args
          .map((arg) => arg == 'libaria2c.so' ? 'aria2c' : arg)
          .toList();
      final cliArgs = [
        '-o',
        outTemplate,
        '--newline',
        if (!sanitizedArgs.contains('--config-locations')) ...[
          '--config-locations',
          configFile.path,
        ],
        ...sanitizedArgs,
        url,
      ];

      final process = await Process.start('yt-dlp', cliArgs, runInShell: true);

      _activeDesktopProcesses[taskId] = process;

      final progressRegex = RegExp(
        r'\[download\]\s+([\d\.]+)%\s+of\s+~?([^\s]+)\s+at\s+([^\s]+)\s+ETA\s+([^\s]+)',
      );
      final liveProgressRegex = RegExp(
        r'\[download\]\s+([^\s]+)\s+at\s+([^\s]+)\s+\(([\d:]+)\)',
      );

      final errorLines = <String>[];

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            final match = progressRegex.firstMatch(line);
            if (match != null) {
              final progress = double.tryParse(match.group(1) ?? '') ?? 0.0;
              final speed = match.group(3) ?? '';
              final eta = match.group(4) ?? '';

              _streamController.add({
                'taskId': taskId,
                'status': 'DOWNLOADING',
                'progress': progress,
                'speed': speed,
                'eta': eta,
                'log': line,
              });
            } else {
              final liveMatch = liveProgressRegex.firstMatch(line);
              if (liveMatch != null) {
                final speed = liveMatch.group(2) ?? '';
                final elapsed = liveMatch.group(3) ?? '';
                _streamController.add({
                  'taskId': taskId,
                  'status': 'DOWNLOADING',
                  'speed': speed,
                  'eta': 'LIVE $elapsed',
                  'log': line,
                });
              } else {
                _streamController.add({
                  'taskId': taskId,
                  'status': 'DOWNLOADING',
                  'log': line,
                });
              }
            }
          });

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((errLine) {
            if (errLine.trim().isNotEmpty) {
              errorLines.add(errLine.trim());
            }
          });

      process.exitCode.then((exitCode) {
        _activeDesktopProcesses.remove(taskId);
        if (exitCode == 0) {
          _streamController.add({
            'taskId': taskId,
            'status': 'COMPLETED',
            'progress': 100.0,
            'speed': '0.0 KB/s',
            'eta': 'Done',
            'log': 'Download completed successfully',
          });
        } else {
          _streamController.add({
            'taskId': taskId,
            'status': 'FAILED',
            'error': errorLines.isNotEmpty
                ? errorLines.last
                : 'Download failed with exit code $exitCode',
            'log': errorLines.join('\n'),
          });
        }
      });

      return true;
    } catch (e) {
      _streamController.add({
        'taskId': taskId,
        'status': 'FAILED',
        'error': 'Failed to launch yt-dlp: $e',
        'log': e.toString(),
      });
      return false;
    }
  }

  /// Cancels an active download process by its task ID
  Future<bool> cancelDownload(String taskId) async {
    if (Platform.isAndroid) {
      try {
        final result = await _engineChannel.invokeMethod<bool>(
          'cancelDownload',
          {'taskId': taskId},
        );
        return result ?? false;
      } catch (e) {
        debugPrint('cancelDownload error: $e');
        return false;
      }
    }

    final process = _activeDesktopProcesses.remove(taskId);
    if (process != null) {
      return process.kill();
    }
    return true;
  }

  void dispose() {
    for (final process in _activeDesktopProcesses.values) {
      process.kill();
    }
    _activeDesktopProcesses.clear();
    for (final process in _activeDesktopSearchProcesses.values) {
      process.kill();
    }
    _activeDesktopSearchProcesses.clear();
    _nativeSubscription?.cancel();
    _streamController.close();
  }
}
