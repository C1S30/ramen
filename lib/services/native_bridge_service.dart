import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/media_resource.dart';

class NativeBridgeService {
  static const MethodChannel _engineChannel =
      MethodChannel('com.ramen.downloader/engine');
  static const EventChannel _streamChannel =
      EventChannel('com.ramen.downloader/download_stream');

  final StreamController<Map<String, dynamic>> _streamController =
      StreamController<Map<String, dynamic>>.broadcast();

  StreamSubscription? _nativeSubscription;
  bool _isInitialized = false;

  // Active desktop download processes (taskId -> Process)
  final Map<String, Process> _activeDesktopProcesses = {};

  NativeBridgeService() {
    _bindStream();
  }

  void _bindStream() {
    try {
      _nativeSubscription = _streamChannel
          .receiveBroadcastStream()
          .listen((dynamic rawData) {
        if (rawData is Map) {
          final mapped = Map<String, dynamic>.from(rawData);
          _streamController.add(mapped);
        }
      }, onError: (dynamic error) {
        debugPrint('Download stream error: $error');
      });
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
        final res = await _engineChannel
            .invokeMapMethod<String, String>('getEngineVersions');
        if (res != null) return res;
      } catch (e) {
        debugPrint('Android getEngineVersions error: $e');
      }
      return {
        'ytdlp': 'N/A',
        'ffmpeg': 'N/A',
        'aria2c': 'N/A',
        'node': 'N/A',
      };
    }

    // Desktop platform: query installed CLI binaries
    String ytDlpVer = 'Not installed';
    String ffmpegVer = 'Not installed';
    String aria2cVer = 'Not installed';
    String nodeVer = 'Not installed';

    try {
      final ytRes = await Process.run('yt-dlp', ['--version'], runInShell: true);
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
      final ariaRes = await Process.run('aria2c', ['--version'], runInShell: true);
      if (ariaRes.exitCode == 0) {
        final firstLine = ariaRes.stdout.toString().split('\n').first.trim();
        aria2cVer = firstLine.isNotEmpty ? firstLine : 'Available';
      }
    } catch (_) {}

    try {
      final nodeRes = await Process.run('node', ['--version'], runInShell: true);
      if (nodeRes.exitCode == 0 && nodeRes.stdout.toString().trim().isNotEmpty) {
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

  /// Triggers update of the yt-dlp binary
  Future<String> updateEngine() async {
    if (Platform.isAndroid) {
      try {
        final newVersion =
            await _engineChannel.invokeMethod<String>('updateEngine');
        return newVersion ?? 'Updated to latest stable';
      } catch (e) {
        throw Exception('Update failed: $e');
      }
    }

    try {
      final res = await Process.run('yt-dlp', ['-U'], runInShell: true);
      final out = res.stdout.toString().trim();
      final err = res.stderr.toString().trim();
      return out.isNotEmpty ? out : (err.isNotEmpty ? err : 'yt-dlp update executed');
    } catch (e) {
      throw Exception('Update failed: $e');
    }
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

  /// Inspects formats using yt-dlp ('URL -F' template only)
  Future<MediaResource> getFormats(
    String urlOrQuery, {
    List<String> extraArgs = const [],
  }) async {
    final target = resolveTarget(urlOrQuery);
    if (target.isEmpty) {
      throw Exception('Target URL or search query cannot be empty');
    }

    if (Platform.isAndroid) {
      if (!_isInitialized) {
        await initEngine();
      }
      final rawOut = await _engineChannel.invokeMethod<String>(
        'getFormats',
        {'url': target},
      );

      if (rawOut != null && rawOut.trim().isNotEmpty) {
        return MediaResource.parseOutput(rawOut, target);
      } else {
        throw Exception('No media information returned by yt-dlp');
      }
    }

    // Desktop execution: invoke local yt-dlp using 'URL -F' template only
    return await _getFormatsViaDesktopCli(target, extraArgs);
  }

  Future<MediaResource> _getFormatsViaDesktopCli(
    String target,
    List<String> extraArgs,
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
      final jsonRes = await Process.run(
        'yt-dlp',
        jsonArgs,
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      if (jsonRes.exitCode == 0 && jsonRes.stdout.toString().trim().isNotEmpty) {
        return MediaResource.parseOutput(jsonRes.stdout.toString().trim(), target);
      }
    } catch (_) {
      // Fallback to table extraction below
    }

    final cliArgs = [
      '--config-locations',
      configFile.path,
      target,
      '-F',
      ...extraArgs,
    ];

    ProcessResult res;
    try {
      res = await Process.run(
        'yt-dlp',
        cliArgs,
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
    } catch (e) {
      throw Exception('yt-dlp execution error: $e. Ensure yt-dlp is installed and in PATH.');
    }

    if (res.exitCode != 0) {
      final err = res.stderr.toString().trim();
      final cleanErr = err.isNotEmpty ? err : 'yt-dlp exited with error code ${res.exitCode}';
      throw Exception(cleanErr);
    }

    final rawOut = res.stdout.toString().trim();
    if (rawOut.isEmpty) {
      throw Exception('yt-dlp returned empty output for "$target"');
    }

    return MediaResource.parseOutput(rawOut, target);
  }

  Future<File> _getOrCreateConfigFile() async {
    final tempDir = Directory.systemTemp;
    final configFile = File('${tempDir.path}${Platform.pathSeparator}yt-dlp.conf');

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
        final out = res.stdout.toString().trim().split(RegExp(r'[\r\n]+')).first.trim();
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
  }) async {
    if (Platform.isAndroid) {
      if (!_isInitialized) {
        await initEngine();
      }
      final result = await _engineChannel.invokeMethod<bool>(
        'startDownload',
        {
          'taskId': taskId,
          'url': url,
          'outDir': outDir,
          'args': args,
        },
      );
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
        final home = Platform.environment['USERPROFILE'] ??
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

      final outTemplate = '${targetDir.path}${Platform.pathSeparator}%(title)s.%(ext)s';
      final configFile = await _getOrCreateConfigFile();
      // On desktop, sanitize Android's libaria2c.so back to aria2c binary name
      final sanitizedArgs = args.map((arg) => arg == 'libaria2c.so' ? 'aria2c' : arg).toList();
      final cliArgs = [
        '-o',
        outTemplate,
        '--newline',
        if (!sanitizedArgs.contains('--config-locations')) ...['--config-locations', configFile.path],
        ...sanitizedArgs,
        url,
      ];

      final process = await Process.start(
        'yt-dlp',
        cliArgs,
        runInShell: true,
      );

      _activeDesktopProcesses[taskId] = process;

      final progressRegex = RegExp(
        r'\[download\]\s+([\d\.]+)%\s+of\s+~?([^\s]+)\s+at\s+([^\s]+)\s+ETA\s+([^\s]+)',
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
          _streamController.add({
            'taskId': taskId,
            'status': 'DOWNLOADING',
            'log': line,
          });
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
    _nativeSubscription?.cancel();
    _streamController.close();
  }
}
