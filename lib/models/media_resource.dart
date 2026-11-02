import 'dart:convert';

/// Represents yt-dlp's standardized `live_status` field from `yt_dlp/extractor/common.py`:
/// - `is_live`: Currently broadcasting in real time
/// - `is_upcoming`: Scheduled broadcast / premiere waiting room
/// - `was_live`: Former live broadcast that is now a VOD archive
/// - `post_live`: Broadcast has ended, VOD is still being processed
/// - `not_live`: Standard pre-recorded video
enum LiveStatus {
  notLive('not_live', 'STREAM READY'),
  isLive('is_live', 'LIVE NOW'),
  isUpcoming('is_upcoming', 'UPCOMING'),
  wasLive('was_live', 'WAS LIVE'),
  postLive('post_live', 'POST-LIVE');

  final String apiValue;
  final String badgeLabel;

  const LiveStatus(this.apiValue, this.badgeLabel);

  /// Normalizes `live_status`, `is_live`, and `was_live` according to
  /// `yt_dlp.extractor.common.InfoExtractor._fill_common_fields`
  static LiveStatus fromInfoDict(Map<String, dynamic> json) {
    final rawStatus = json['live_status']?.toString().trim().toLowerCase();
    switch (rawStatus) {
      case 'is_live':
        return LiveStatus.isLive;
      case 'is_upcoming':
        return LiveStatus.isUpcoming;
      case 'was_live':
        return LiveStatus.wasLive;
      case 'post_live':
        return LiveStatus.postLive;
      case 'not_live':
        return LiveStatus.notLive;
    }

    // Fallback normalization when `live_status` is absent
    final isLive = json['is_live'];
    final wasLive = json['was_live'];
    if (isLive == true) return LiveStatus.isLive;
    if (wasLive == true) return LiveStatus.wasLive;
    return LiveStatus.notLive;
  }
}

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
  final double? vbr; // Video bitrate in kbit/s
  final double? abr; // Audio bitrate in kbit/s
  final String? formatNote;
  final String? protocol; // e.g., m3u8_native, http_dash_segments, https
  final String? manifestUrl;
  final bool isFromStart;
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
    this.vbr,
    this.abr,
    this.formatNote,
    this.protocol,
    this.manifestUrl,
    this.isFromStart = false,
    this.isAudioOnly = false,
    this.isVideoOnly = false,
    this.isMerged = false,
  });

  bool get isHls =>
      protocol != null && protocol!.toLowerCase().contains('m3u8');

  bool get isDash =>
      protocol != null && protocol!.toLowerCase().contains('dash');

  bool get hasVideo => vcodec != null && vcodec != 'none';
  bool get hasAudio => acodec != null && acodec != 'none';

  factory FormatItem.fromJson(Map<String, dynamic> json) {
    final vcodec = json['vcodec'] as String?;
    final acodec = json['acodec'] as String?;
    final resolutionStr = json['resolution']?.toString();

    final hasVideo =
        (vcodec != null && vcodec != 'none') ||
        (vcodec == null &&
            resolutionStr != null &&
            resolutionStr != 'audio only');
    final hasAudio = acodec != null && acodec != 'none';

    final isAudioOnly =
        (!hasVideo && hasAudio) || resolutionStr == 'audio only';
    final isVideoOnly = hasVideo && !hasAudio;
    final isMerged = hasVideo && hasAudio;

    final height = (json['height'] as num?)?.toInt();
    final width = (json['width'] as num?)?.toInt();
    String? resolution = resolutionStr;
    if ((resolution == null || resolution.isEmpty) && height != null) {
      resolution = '${height}p';
    } else if (resolution != null &&
        RegExp(r'^\d+x(\d+)$').hasMatch(resolution) &&
        height != null) {
      resolution = '${height}p';
    }

    final rawFilesize = json['filesize'] ?? json['filesize_approx'];
    final int? filesize = rawFilesize is num ? rawFilesize.toInt() : null;

    final rawTbr = json['tbr'];
    final double? tbr = rawTbr is num ? rawTbr.toDouble() : null;

    final rawVbr = json['vbr'];
    final double? vbr = rawVbr is num ? rawVbr.toDouble() : null;

    final rawAbr = json['abr'];
    final double? abr = rawAbr is num ? rawAbr.toDouble() : null;

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
      tbr: tbr ?? ((vbr ?? 0) + (abr ?? 0) > 0 ? (vbr ?? 0) + (abr ?? 0) : null),
      vbr: vbr,
      abr: abr,
      formatNote: json['format_note']?.toString(),
      protocol: json['protocol']?.toString(),
      manifestUrl: json['manifest_url']?.toString(),
      isFromStart: json['is_from_start'] == true,
      isAudioOnly: isAudioOnly,
      isVideoOnly: isVideoOnly,
      isMerged: isMerged,
    );
  }

  String get displayQuality {
    if (isAudioOnly) {
      final effectiveBitrate = abr ?? tbr;
      if (acodec != null && acodec != 'none') {
        final cleanCodec = acodec!.split('.').first;
        final br = effectiveBitrate != null
            ? '${effectiveBitrate.round()} kbps'
            : '';
        return '$cleanCodec $br'.trim();
      }
      if (effectiveBitrate != null) {
        return 'Audio ${effectiveBitrate.round()} kbps';
      }
      return formatNote ?? 'Audio Stream';
    }
    if (resolution != null && resolution != 'audio only') {
      final fpsSuffix = fps != null && fps! > 30 ? '${fps}fps' : '';
      return '$resolution $fpsSuffix'.trim();
    }
    return formatNote ?? 'Video';
  }
}

class MediaResource {
  final String id;
  final String url;
  final String title;
  final String? description;
  final String? uploader;
  final String? uploaderId;
  final String? uploaderUrl;
  final String? thumbnail;
  final int? durationSeconds;
  final int? viewCount;
  final bool isPlaylist;
  final bool isSearchResult;
  final int? playlistCount;
  final int? playlistIndex;
  final String? modifiedDate;
  final String? availability;
  final LiveStatus liveStatus;
  final int? releaseTimestamp;
  final String? releaseDate;
  final int? concurrentViewCount;
  final List<MediaResource> playlistEntries;
  final List<FormatItem> formats;

  MediaResource({
    required this.id,
    required this.url,
    required this.title,
    this.description,
    this.uploader,
    this.uploaderId,
    this.uploaderUrl,
    this.thumbnail,
    this.durationSeconds,
    this.viewCount,
    this.isPlaylist = false,
    this.isSearchResult = false,
    this.playlistCount,
    this.playlistIndex,
    this.modifiedDate,
    this.availability,
    this.liveStatus = LiveStatus.notLive,
    this.releaseTimestamp,
    this.releaseDate,
    this.concurrentViewCount,
    this.playlistEntries = const [],
    this.formats = const [],
  });

  bool get isLive => liveStatus == LiveStatus.isLive;
  bool get isUpcoming => liveStatus == LiveStatus.isUpcoming;
  bool get wasLive => liveStatus == LiveStatus.wasLive;
  bool get isPostLive => liveStatus == LiveStatus.postLive;
  bool get isLiveOrUpcoming => isLive || isUpcoming || isPostLive;

  /// Checks whether a playlist entry represents an accessible media item
  bool get isPlayableEntry {
    final lower = title.trim().toLowerCase();
    return lower != '[private video]' &&
        lower != '[deleted video]' &&
        lower != 'private video' &&
        lower != 'deleted video' &&
        availability != 'private';
  }

  static String? _extractBestThumbnail(Map<String, dynamic> json) {
    final direct = json['thumbnail']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;

    final thumbs = json['thumbnails'];
    if (thumbs is List && thumbs.isNotEmpty) {
      // Iterate backwards from highest resolution thumbnail
      for (int i = thumbs.length - 1; i >= 0; i--) {
        final item = thumbs[i];
        if (item is Map) {
          final url = item['url']?.toString();
          if (url != null && url.isNotEmpty) return url;
        }
      }
    }
    return null;
  }

  factory MediaResource.fromJson(
    Map<String, dynamic> json,
    String fallbackUrl, {
    int? fallbackPlaylistIndex,
  }) {
    final type = json['_type']?.toString() ?? 'video';
    final isPlaylist =
        type == 'playlist' || type == 'multi_video' || json['entries'] != null;
    final extractorKey =
        (json['extractor_key'] ?? json['ie_key'])?.toString() ?? '';
    final extractor = json['extractor']?.toString() ?? '';
    final isSearch =
        extractorKey.toLowerCase().contains('search') ||
        extractor.toLowerCase().contains('search') ||
        fallbackUrl.startsWith('ytsearch');

    if (isPlaylist) {
      final rawEntries = json['entries'] as List<dynamic>? ?? [];
      final List<MediaResource> entries = [];
      int idx = 0;
      for (final rawEntry in rawEntries) {
        if (rawEntry is! Map) continue;
        idx++;
        final m = Map<String, dynamic>.from(rawEntry);
        final entryId = m['id']?.toString();
        final rawUrl = m['webpage_url']?.toString() ?? m['url']?.toString();
        final ieKey =
            (m['ie_key'] ?? m['extractor_key'] ?? extractorKey)?.toString() ??
            '';

        String entryUrl;
        if (rawUrl != null &&
            (rawUrl.startsWith('http://') || rawUrl.startsWith('https://'))) {
          entryUrl = rawUrl;
        } else if (entryId != null &&
            (ieKey.toLowerCase().contains('youtube') ||
                fallbackUrl.contains('youtube.com') ||
                fallbackUrl.contains('youtu.be') ||
                isSearch)) {
          entryUrl = 'https://www.youtube.com/watch?v=$entryId';
        } else if (rawUrl != null && rawUrl.isNotEmpty) {
          entryUrl = rawUrl;
        } else {
          entryUrl = fallbackUrl;
        }

        final parsedEntry = MediaResource.fromJson(
          m,
          entryUrl,
          fallbackPlaylistIndex:
              (m['playlist_index'] as num?)?.toInt() ?? idx,
        );
        entries.add(parsedEntry);
      }

      final rawPlaylistCount =
          (json['playlist_count'] ?? json['n_entries']) as num?;
      final playlistCount = rawPlaylistCount?.toInt() ?? entries.length;

      final uploader =
          json['uploader']?.toString() ??
          json['channel']?.toString() ??
          json['playlist_uploader']?.toString() ??
          json['creator']?.toString();

      final uploaderId =
          json['uploader_id']?.toString() ??
          json['channel_id']?.toString() ??
          json['playlist_uploader_id']?.toString();

      final uploaderUrl =
          json['uploader_url']?.toString() ?? json['channel_url']?.toString();

      final thumb =
          _extractBestThumbnail(json) ??
          (entries.isNotEmpty ? entries.first.thumbnail : null);

      final rawViews = json['view_count'];
      final int? viewCount = rawViews is num ? rawViews.toInt() : null;

      return MediaResource(
        id: json['id']?.toString() ?? 'playlist',
        url:
            json['webpage_url']?.toString() ??
            json['original_url']?.toString() ??
            fallbackUrl,
        title:
            json['title']?.toString() ??
            (isSearch ? 'Search Results' : 'Playlist'),
        description: json['description']?.toString(),
        uploader: uploader,
        uploaderId: uploaderId,
        uploaderUrl: uploaderUrl,
        thumbnail: thumb,
        viewCount: viewCount,
        isPlaylist: true,
        isSearchResult: isSearch,
        playlistCount: playlistCount,
        modifiedDate: json['modified_date']?.toString(),
        availability: json['availability']?.toString(),
        playlistEntries: entries,
        formats: const [],
      );
    }

    final rawFormats = json['formats'] as List<dynamic>? ?? [];
    final formats = rawFormats
        .whereType<Map>()
        .map((f) => FormatItem.fromJson(Map<String, dynamic>.from(f)))
        .where(
          (f) =>
              !f.formatId.startsWith('sb') &&
              f.ext != 'mhtml' &&
              (f.formatNote == null ||
                  !f.formatNote!.toLowerCase().contains('storyboard')),
        )
        .toList();

    final videoId = json['id']?.toString() ?? 'video';
    String? thumb = _extractBestThumbnail(json);
    if (thumb == null &&
        videoId != 'video' &&
        (fallbackUrl.contains('youtube.com') ||
            fallbackUrl.contains('youtu.be'))) {
      thumb = 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
    }

    final rawDuration = json['duration'];
    final int? duration = rawDuration is num ? rawDuration.toInt() : null;

    final rawViews = json['view_count'];
    final int? viewCount = rawViews is num ? rawViews.toInt() : null;

    final rawConcurrent = json['concurrent_view_count'];
    final int? concurrentViewCount = rawConcurrent is num
        ? rawConcurrent.toInt()
        : null;

    final rawReleaseTs = json['release_timestamp'];
    final int? releaseTimestamp = rawReleaseTs is num
        ? rawReleaseTs.toInt()
        : null;

    final liveStatus = LiveStatus.fromInfoDict(json);

    final resolvedUrl =
        json['webpage_url']?.toString() ??
        json['original_url']?.toString() ??
        (json['url'] != null &&
                (json['url'].toString().startsWith('http://') ||
                    json['url'].toString().startsWith('https://'))
            ? json['url'].toString()
            : null) ??
        (videoId != 'video' &&
                (fallbackUrl.contains('youtube.com') ||
                    fallbackUrl.contains('youtu.be'))
            ? 'https://www.youtube.com/watch?v=$videoId'
            : fallbackUrl);

    return MediaResource(
      id: videoId,
      url: resolvedUrl,
      title: json['title']?.toString() ?? 'Untitled Video',
      description: json['description']?.toString(),
      uploader:
          json['uploader']?.toString() ??
          json['channel']?.toString() ??
          json['creator']?.toString() ??
          'Unknown Creator',
      uploaderId:
          json['uploader_id']?.toString() ?? json['channel_id']?.toString(),
      uploaderUrl:
          json['uploader_url']?.toString() ?? json['channel_url']?.toString(),
      thumbnail: thumb,
      durationSeconds: duration,
      viewCount: viewCount,
      isPlaylist: false,
      isSearchResult: false,
      playlistIndex:
          (json['playlist_index'] as num?)?.toInt() ?? fallbackPlaylistIndex,
      availability: json['availability']?.toString(),
      liveStatus: liveStatus,
      releaseTimestamp: releaseTimestamp,
      releaseDate: json['release_date']?.toString(),
      concurrentViewCount: concurrentViewCount,
      playlistEntries: const [],
      formats: formats,
    );
  }

  /// Parses either JSON output (single object or NDJSON lines) or human-readable format table (-F) output from yt-dlp
  factory MediaResource.parseOutput(String rawOutput, String fallbackUrl) {
    final trimmed = rawOutput.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed) as Map<String, dynamic>;
        return MediaResource.fromJson(decoded, fallbackUrl);
      } catch (_) {
        // Check if multi-line NDJSON objects were emitted (e.g. multiple playlist lines)
        final jsonLines = trimmed
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.startsWith('{') && l.endsWith('}'))
            .toList();
        if (jsonLines.isNotEmpty) {
          try {
            if (jsonLines.length == 1) {
              return MediaResource.fromJson(
                jsonDecode(jsonLines.first) as Map<String, dynamic>,
                fallbackUrl,
              );
            }
            final entries = <Map<String, dynamic>>[];
            for (final line in jsonLines) {
              entries.add(jsonDecode(line) as Map<String, dynamic>);
            }
            final first = entries.first;
            return MediaResource.fromJson({
              '_type': 'playlist',
              'id': first['playlist_id'] ?? 'playlist',
              'title': first['playlist_title'] ?? first['playlist'] ?? 'Playlist',
              'uploader': first['playlist_uploader'] ?? first['uploader'],
              'playlist_count': entries.length,
              'entries': entries,
            }, fallbackUrl);
          } catch (_) {}
        }
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
    bool hasM3u8Formats = false;

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

      String? protocol;
      if (line.contains('m3u8')) {
        protocol = 'm3u8_native';
        hasM3u8Formats = true;
      } else if (line.contains('dash')) {
        protocol = 'http_dash_segments';
      } else if (line.contains('https')) {
        protocol = 'https';
      }

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
          protocol: protocol,
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

    final isLikelyLive =
        hasM3u8Formats && formats.isNotEmpty && formats.every((f) => f.filesize == null);

    return MediaResource(
      id: detectedId,
      url: fallbackUrl,
      title: 'Video ($detectedId)',
      thumbnail: thumb,
      liveStatus: isLikelyLive ? LiveStatus.isLive : LiveStatus.notLive,
      formats: formats,
    );
  }
}
