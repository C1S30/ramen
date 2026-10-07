import 'dart:convert';

class FormatItem {
  final String formatId;
  final String ext;
  final String? resolution;
  final int? height;
  final int? width;
  final int? fps;
  final String? vcodec;
  final String? acodec;
  final int? filesize;
  final double? tbr; // Total bitrate in kbit/s
  final String? formatNote;
  final bool isAudioOnly;
  final bool isVideoOnly;
  final bool isMerged;

  FormatItem({
    required this.formatId,
    required this.ext,
    this.resolution,
    this.height,
    this.width,
    this.fps,
    this.vcodec,
    this.acodec,
    this.filesize,
    this.tbr,
    this.formatNote,
    this.isAudioOnly = false,
    this.isVideoOnly = false,
    this.isMerged = false,
  });

  factory FormatItem.fromJson(Map<String, dynamic> json) {
    final vcodec = json['vcodec'] as String?;
    final acodec = json['acodec'] as String?;
    final hasVideo = vcodec != null && vcodec != 'none';
    final hasAudio = acodec != null && acodec != 'none';

    final isAudioOnly = !hasVideo && hasAudio;
    final isVideoOnly = hasVideo && !hasAudio;
    final isMerged = hasVideo && hasAudio;

    final height = (json['height'] as num?)?.toInt();
    final width = (json['width'] as num?)?.toInt();
    String? resolution = json['resolution'] as String?;
    if (resolution == null && height != null) {
      resolution = '${height}p';
    }

    final rawFilesize = json['filesize'] ?? json['filesize_approx'];
    final int? filesize = rawFilesize is num ? rawFilesize.toInt() : null;

    final rawTbr = json['tbr'];
    final double? tbr = rawTbr is num ? rawTbr.toDouble() : null;

    final rawFps = json['fps'];
    final int? fps = rawFps is num ? rawFps.toInt() : null;

    return FormatItem(
      formatId: json['format_id']?.toString() ?? 'unknown',
      ext: json['ext']?.toString() ?? 'mp4',
      resolution: resolution,
      height: height,
      width: width,
      fps: fps,
      vcodec: vcodec,
      acodec: acodec,
      filesize: filesize,
      tbr: tbr,
      formatNote: json['format_note']?.toString(),
      isAudioOnly: isAudioOnly,
      isVideoOnly: isVideoOnly,
      isMerged: isMerged,
    );
  }

  String get displayQuality {
    if (isAudioOnly) {
      if (acodec != null && acodec != 'none') {
        final abr = tbr != null ? '${tbr!.round()} kbps' : '';
        return '$acodec $abr'.trim();
      }
      return 'Audio Stream';
    }
    if (resolution != null) {
      final fpsSuffix = fps != null && fps! > 30 ? '$fps' : '';
      return '$resolution $fpsSuffix'.trim();
    }
    return formatNote ?? 'Video';
  }
}

class MediaResource {
  final String id;
  final String url;
  final String title;
  final String? uploader;
  final String? uploaderUrl;
  final String? thumbnail;
  final int? durationSeconds;
  final int? viewCount;
  final bool isPlaylist;
  final bool isSearchResult;
  final List<MediaResource> playlistEntries;
  final List<FormatItem> formats;

  MediaResource({
    required this.id,
    required this.url,
    required this.title,
    this.uploader,
    this.uploaderUrl,
    this.thumbnail,
    this.durationSeconds,
    this.viewCount,
    this.isPlaylist = false,
    this.isSearchResult = false,
    this.playlistEntries = const [],
    this.formats = const [],
  });

  factory MediaResource.fromJson(
    Map<String, dynamic> json,
    String fallbackUrl,
  ) {
    final isPlaylist = json['_type'] == 'playlist' || json['entries'] != null;
    final extractorKey = json['extractor_key']?.toString() ?? '';
    final extractor = json['extractor']?.toString() ?? '';
    final isSearch =
        extractorKey.toLowerCase().contains('search') ||
        extractor.toLowerCase().contains('search') ||
        fallbackUrl.startsWith('ytsearch');

    if (isPlaylist) {
      final rawEntries = json['entries'] as List<dynamic>? ?? [];
      final entries = rawEntries.whereType<Map>().map((entry) {
        final m = Map<String, dynamic>.from(entry);
        final entryId = m['id']?.toString();
        final entryUrl =
            m['webpage_url']?.toString() ??
            m['url']?.toString() ??
            (entryId != null
                ? 'https://www.youtube.com/watch?v=$entryId'
                : fallbackUrl);
        return MediaResource.fromJson(m, entryUrl);
      }).toList();

      return MediaResource(
        id: json['id']?.toString() ?? 'playlist',
        url: json['webpage_url']?.toString() ?? fallbackUrl,
        title:
            json['title']?.toString() ??
            (isSearch ? 'Search Results' : 'Playlist'),
        uploader: json['uploader']?.toString() ?? json['channel']?.toString(),
        uploaderUrl: json['uploader_url']?.toString(),
        thumbnail:
            json['thumbnail']?.toString() ??
            (entries.isNotEmpty ? entries.first.thumbnail : null),
        isPlaylist: true,
        isSearchResult: isSearch,
        playlistEntries: entries,
        formats: const [],
      );
    }

    final rawFormats = json['formats'] as List<dynamic>? ?? [];
    final formats = rawFormats
        .whereType<Map>()
        .map((f) => FormatItem.fromJson(Map<String, dynamic>.from(f)))
        .toList();

    // Pick best thumbnail
    String? thumb = json['thumbnail']?.toString();
    if (thumb == null && json['thumbnails'] is List) {
      final list = json['thumbnails'] as List;
      if (list.isNotEmpty && list.last is Map) {
        thumb = list.last['url']?.toString();
      }
    }

    final rawDuration = json['duration'];
    final int? duration = rawDuration is num ? rawDuration.toInt() : null;

    final rawViews = json['view_count'];
    final int? viewCount = rawViews is num ? rawViews.toInt() : null;

    final videoId = json['id']?.toString() ?? 'video';
    final resolvedUrl =
        json['webpage_url']?.toString() ??
        json['url']?.toString() ??
        (videoId != 'video'
            ? 'https://www.youtube.com/watch?v=$videoId'
            : fallbackUrl);

    return MediaResource(
      id: videoId,
      url: resolvedUrl,
      title: json['title']?.toString() ?? 'Untitled Video',
      uploader:
          json['uploader']?.toString() ??
          json['channel']?.toString() ??
          'Unknown Creator',
      uploaderUrl: json['uploader_url']?.toString(),
      thumbnail: thumb,
      durationSeconds: duration,
      viewCount: viewCount,
      isPlaylist: false,
      isSearchResult: false,
      playlistEntries: const [],
      formats: formats,
    );
  }

  /// Parses either JSON output or human-readable format table (-F) output from yt-dlp
  factory MediaResource.parseOutput(String rawOutput, String fallbackUrl) {
    final trimmed = rawOutput.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed) as Map<String, dynamic>;
        return MediaResource.fromJson(decoded, fallbackUrl);
      } catch (_) {
        // Fallback to table parser if jsonDecode fails
      }
    }
    return MediaResource.fromFormatListTable(trimmed, fallbackUrl);
  }

  /// Parses standard yt-dlp `-F` (format list) tabular output into structured FormatItem objects
  factory MediaResource.fromFormatListTable(
    String tableText,
    String fallbackUrl,
  ) {
    final lines = tableText.split('\n');
    final List<FormatItem> formats = [];
    String? detectedId;

    // Check for [info] Available formats for <id>:
    final idRegex = RegExp(
      r'Available formats for\s+([^:]+):',
      caseSensitive: false,
    );
    for (final line in lines) {
      final m = idRegex.firstMatch(line);
      if (m != null) {
        detectedId = m.group(1)?.trim();
        break;
      }
    }

    if (detectedId == null || detectedId.isEmpty) {
      if (fallbackUrl.contains('v=')) {
        detectedId = fallbackUrl.split('v=').last.split('&').first;
      } else if (fallbackUrl.contains('youtu.be/')) {
        detectedId = fallbackUrl.split('youtu.be/').last.split('?').first;
      } else {
        detectedId = 'media_${DateTime.now().millisecondsSinceEpoch}';
      }
    }

    bool passedHeader = false;
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('---') ||
          line.startsWith('───') ||
          line.startsWith('===')) {
        passedHeader = true;
        continue;
      }

      if (!passedHeader) {
        // Some older yt-dlp versions don't have divider lines, but have a format header line
        if (line.toLowerCase().startsWith('format code') ||
            line.toLowerCase().startsWith('id ') ||
            line.toLowerCase().startsWith('id\t')) {
          passedHeader = true;
        }
        continue;
      }

      // Ignore logging/warning lines
      if (line.startsWith('[') ||
          line.startsWith('WARNING') ||
          line.startsWith('ERROR')) {
        continue;
      }

      final tokens = line.split(RegExp(r'\s+'));
      if (tokens.length < 2) continue;

      final formatId = tokens[0].trim();
      final ext = tokens[1].trim().toLowerCase();

      // Skip header row if encountered
      if (formatId.toLowerCase() == 'id' ||
          formatId.toLowerCase() == 'format' ||
          ext == 'ext' ||
          ext == 'extension') {
        continue;
      }

      // Skip storyboard thumbnails
      if (formatId.startsWith('sb') ||
          ext == 'mhtml' ||
          line.contains('storyboard')) {
        continue;
      }

      final isAudioOnly =
          line.contains('audio only') ||
          (!line.contains('x') &&
              [
                'm4a',
                'mp3',
                'opus',
                'aac',
                'flac',
                'wav',
                'ogg',
              ].contains(ext));
      final isVideoOnly = line.contains('video only');
      final isMerged = !isAudioOnly && !isVideoOnly;

      // Extract resolution
      String? resolution;
      int? width;
      int? height;

      final resMatch = RegExp(r'\b(\d{2,5})x(\d{2,5})\b').firstMatch(line);
      if (resMatch != null) {
        width = int.tryParse(resMatch.group(1)!);
        height = int.tryParse(resMatch.group(2)!);
        resolution = '${height}p';
      } else {
        final pMatch = RegExp(r'\b(\d{3,4})p\b').firstMatch(line);
        if (pMatch != null) {
          height = int.tryParse(pMatch.group(1)!);
          resolution = '${height}p';
        } else if (isAudioOnly) {
          resolution = 'audio only';
        }
      }

      // Extract filesize
      int? filesize;
      final sizeMatch = RegExp(
        r'(~?\s*[\d\.]+)\s*(GiB|MiB|KiB|B|GB|MB|KB)',
        caseSensitive: false,
      ).firstMatch(line);
      if (sizeMatch != null) {
        final rawNum =
            double.tryParse(sizeMatch.group(1)!.replaceAll('~', '').trim()) ??
            0;
        final unit = sizeMatch.group(2)!.toLowerCase();
        if (unit == 'gib' || unit == 'gb') {
          filesize = (rawNum * 1024 * 1024 * 1024).toInt();
        } else if (unit == 'mib' || unit == 'mb') {
          filesize = (rawNum * 1024 * 1024).toInt();
        } else if (unit == 'kib' || unit == 'kb') {
          filesize = (rawNum * 1024).toInt();
        } else {
          filesize = rawNum.toInt();
        }
      }

      // Extract TBR
      double? tbr;
      final tbrMatch = RegExp(
        r'\b(\d+(?:\.\d+)?)\s*k\b',
        caseSensitive: false,
      ).firstMatch(line);
      if (tbrMatch != null) {
        tbr = double.tryParse(tbrMatch.group(1)!);
      }

      // Extract FPS
      int? fps;
      final fpsMatch = RegExp(r'\b(24|25|30|50|60|120)\b').firstMatch(line);
      if (fpsMatch != null && !isAudioOnly) {
        fps = int.tryParse(fpsMatch.group(1)!);
      }

      // Extract codecs
      String? vcodec;
      String? acodec;
      if (line.contains('av01')) {
        vcodec = 'av01';
      } else if (line.contains('avc1') || line.contains('h264')) {
        vcodec = 'h264';
      } else if (line.contains('vp9') || line.contains('vp09')) {
        vcodec = 'vp9';
      }

      if (line.contains('mp4a')) {
        acodec = 'aac';
      } else if (line.contains('opus')) {
        acodec = 'opus';
      } else if (line.contains('mp3')) {
        acodec = 'mp3';
      }

      formats.add(
        FormatItem(
          formatId: formatId,
          ext: ext,
          resolution: resolution,
          height: height,
          width: width,
          fps: fps,
          filesize: filesize,
          tbr: tbr,
          vcodec: vcodec,
          acodec: acodec,
          isAudioOnly: isAudioOnly,
          isVideoOnly: isVideoOnly,
          isMerged: isMerged,
        ),
      );
    }

    String? thumb;
    if (fallbackUrl.contains('youtu')) {
      thumb = 'https://i.ytimg.com/vi/$detectedId/hqdefault.jpg';
    }

    return MediaResource(
      id: detectedId,
      url: fallbackUrl,
      title: 'Video ($detectedId)',
      thumbnail: thumb,
      formats: formats,
    );
  }
}
