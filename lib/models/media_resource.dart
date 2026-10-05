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

    final height = json['height'] as int?;
    final width = json['width'] as int?;
    String? resolution = json['resolution'] as String?;
    if (resolution == null && height != null) {
      resolution = '${height}p';
    }

    final rawFilesize = json['filesize'] ?? json['filesize_approx'];
    final int? filesize = rawFilesize is num ? rawFilesize.toInt() : null;

    final rawTbr = json['tbr'];
    final double? tbr = rawTbr is num ? rawTbr.toDouble() : null;

    return FormatItem(
      formatId: json['format_id']?.toString() ?? 'unknown',
      ext: json['ext']?.toString() ?? 'mp4',
      resolution: resolution,
      height: height,
      width: width,
      fps: json['fps'] as int?,
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
    this.playlistEntries = const [],
    this.formats = const [],
  });

  factory MediaResource.fromJson(Map<String, dynamic> json, String fallbackUrl) {
    final isPlaylist = json['_type'] == 'playlist' || json['entries'] != null;

    if (isPlaylist) {
      final rawEntries = json['entries'] as List<dynamic>? ?? [];
      final entries = rawEntries
          .whereType<Map<String, dynamic>>()
          .map((entry) => MediaResource.fromJson(entry, entry['url'] ?? fallbackUrl))
          .toList();

      return MediaResource(
        id: json['id']?.toString() ?? 'playlist',
        url: json['webpage_url']?.toString() ?? fallbackUrl,
        title: json['title']?.toString() ?? 'Playlist',
        uploader: json['uploader']?.toString() ?? json['channel']?.toString(),
        uploaderUrl: json['uploader_url']?.toString(),
        thumbnail: json['thumbnail']?.toString() ?? (entries.isNotEmpty ? entries.first.thumbnail : null),
        isPlaylist: true,
        playlistEntries: entries,
        formats: const [],
      );
    }

    final rawFormats = json['formats'] as List<dynamic>? ?? [];
    final formats = rawFormats
        .whereType<Map<String, dynamic>>()
        .map((f) => FormatItem.fromJson(f))
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

    return MediaResource(
      id: json['id']?.toString() ?? 'video',
      url: json['webpage_url']?.toString() ?? fallbackUrl,
      title: json['title']?.toString() ?? 'Untitled Video',
      uploader: json['uploader']?.toString() ?? json['channel']?.toString() ?? 'Unknown Creator',
      uploaderUrl: json['uploader_url']?.toString(),
      thumbnail: thumb,
      durationSeconds: duration,
      viewCount: viewCount,
      isPlaylist: false,
      playlistEntries: const [],
      formats: formats,
    );
  }
}
