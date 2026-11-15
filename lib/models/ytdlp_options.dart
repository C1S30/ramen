class YtDlpOptions {
  // Downloader & Acceleration
  final bool useAria2c;
  final int aria2Connections;
  final int concurrentFragments;
  final int retries;
  final String? rateLimit;

  // Video / Audio Post-Processing (FFmpeg)
  final bool isAudioOnly;
  final String audioFormat;
  final String audioQuality;
  final String? videoRecodeFormat;
  final String? remuxContainer;
  final bool keepVideo;

  // Subtitles & Chapters
  final bool embedSubtitles;
  final bool writeAutoSubtitles;
  final bool skipAutoTranslatedSubtitles;
  final String subLangs;
  final bool embedChapters;

  // Metadata & Thumbnail
  final bool embedThumbnail;
  final bool embedMetadata;
  final bool cropAudioArtwork;
  final bool restrictFilenames;

  // Network & Proxy
  final String? proxy;
  final int socketTimeout;
  final String? userAgent;
  final bool forceIpv4;
  final bool forceIpv6;
  final List<String> customHeaders;

  // Bypass, Protocol Compatibility & Authentication
  final bool geoBypass;
  final String? geoBypassCountry;
  final bool preferProtocolCompatibility;
  final String? formatSortString;
  final String? cookiesBrowser;
  final String? cookiesFilePath;
  final String? extractorArgs;

  // SponsorBlock
  final bool enableSponsorBlock;
  final List<String> sponsorBlockCategories;

  // Live Stream & Playlist Options
  final bool liveFromStart;
  final int? waitForVideoSeconds;
  final bool hlsUseMpegts;
  final String? playlistItems;
  final bool yesPlaylist;

  // Unrestricted Raw Arguments
  final String rawCustomArgs;

  const YtDlpOptions({
    this.useAria2c = false,
    this.aria2Connections = 4,
    this.concurrentFragments = 0,
    this.retries = 0,
    this.rateLimit,
    this.isAudioOnly = false,
    this.audioFormat = 'mp3',
    this.audioQuality = '0',
    this.videoRecodeFormat,
    this.remuxContainer,
    this.keepVideo = false,
    this.embedSubtitles = false,
    this.writeAutoSubtitles = false,
    this.skipAutoTranslatedSubtitles = true,
    this.subLangs = 'en.*',
    this.embedChapters = false,
    this.embedThumbnail = false,
    this.embedMetadata = false,
    this.cropAudioArtwork = false,
    this.restrictFilenames = false,
    this.proxy,
    this.socketTimeout = 0,
    this.userAgent,
    this.forceIpv4 = false,
    this.forceIpv6 = false,
    this.customHeaders = const [],
    this.geoBypass = false,
    this.geoBypassCountry,
    this.preferProtocolCompatibility = false,
    this.formatSortString,
    this.cookiesBrowser,
    this.cookiesFilePath,
    this.extractorArgs,
    this.enableSponsorBlock = false,
    this.sponsorBlockCategories = const ['sponsor', 'selfpromo', 'interaction'],
    this.liveFromStart = false,
    this.waitForVideoSeconds,
    this.hlsUseMpegts = false,
    this.playlistItems,
    this.yesPlaylist = false,
    this.rawCustomArgs = '',
  });

  YtDlpOptions copyWith({
    bool? useAria2c,
    int? aria2Connections,
    int? concurrentFragments,
    int? retries,
    String? rateLimit,
    bool? isAudioOnly,
    String? audioFormat,
    String? audioQuality,
    String? videoRecodeFormat,
    String? remuxContainer,
    bool? keepVideo,
    bool? embedSubtitles,
    bool? writeAutoSubtitles,
    bool? skipAutoTranslatedSubtitles,
    String? subLangs,
    bool? embedChapters,
    bool? embedThumbnail,
    bool? embedMetadata,
    bool? cropAudioArtwork,
    bool? restrictFilenames,
    String? proxy,
    int? socketTimeout,
    String? userAgent,
    bool? forceIpv4,
    bool? forceIpv6,
    List<String>? customHeaders,
    bool? geoBypass,
    String? geoBypassCountry,
    bool? preferProtocolCompatibility,
    String? formatSortString,
    String? cookiesBrowser,
    String? cookiesFilePath,
    String? extractorArgs,
    bool? enableSponsorBlock,
    List<String>? sponsorBlockCategories,
    bool? liveFromStart,
    int? waitForVideoSeconds,
    bool clearWaitForVideo = false,
    bool? hlsUseMpegts,
    String? playlistItems,
    bool clearPlaylistItems = false,
    bool? yesPlaylist,
    String? rawCustomArgs,
  }) {
    return YtDlpOptions(
      useAria2c: useAria2c ?? this.useAria2c,
      aria2Connections: aria2Connections ?? this.aria2Connections,
      concurrentFragments: concurrentFragments ?? this.concurrentFragments,
      retries: retries ?? this.retries,
      rateLimit: rateLimit ?? this.rateLimit,
      isAudioOnly: isAudioOnly ?? this.isAudioOnly,
      audioFormat: audioFormat ?? this.audioFormat,
      audioQuality: audioQuality ?? this.audioQuality,
      videoRecodeFormat: videoRecodeFormat ?? this.videoRecodeFormat,
      remuxContainer: remuxContainer ?? this.remuxContainer,
      keepVideo: keepVideo ?? this.keepVideo,
      embedSubtitles: embedSubtitles ?? this.embedSubtitles,
      writeAutoSubtitles: writeAutoSubtitles ?? this.writeAutoSubtitles,
      skipAutoTranslatedSubtitles:
          skipAutoTranslatedSubtitles ?? this.skipAutoTranslatedSubtitles,
      subLangs: subLangs ?? this.subLangs,
      embedChapters: embedChapters ?? this.embedChapters,
      embedThumbnail: embedThumbnail ?? this.embedThumbnail,
      embedMetadata: embedMetadata ?? this.embedMetadata,
      cropAudioArtwork: cropAudioArtwork ?? this.cropAudioArtwork,
      restrictFilenames: restrictFilenames ?? this.restrictFilenames,
      proxy: proxy ?? this.proxy,
      socketTimeout: socketTimeout ?? this.socketTimeout,
      userAgent: userAgent ?? this.userAgent,
      forceIpv4: forceIpv4 ?? this.forceIpv4,
      forceIpv6: forceIpv6 ?? this.forceIpv6,
      customHeaders: customHeaders ?? this.customHeaders,
      geoBypass: geoBypass ?? this.geoBypass,
      geoBypassCountry: geoBypassCountry ?? this.geoBypassCountry,
      preferProtocolCompatibility:
          preferProtocolCompatibility ?? this.preferProtocolCompatibility,
      formatSortString: formatSortString ?? this.formatSortString,
      cookiesBrowser: cookiesBrowser ?? this.cookiesBrowser,
      cookiesFilePath: cookiesFilePath ?? this.cookiesFilePath,
      extractorArgs: extractorArgs ?? this.extractorArgs,
      enableSponsorBlock: enableSponsorBlock ?? this.enableSponsorBlock,
      sponsorBlockCategories:
          sponsorBlockCategories ?? this.sponsorBlockCategories,
      liveFromStart: liveFromStart ?? this.liveFromStart,
      waitForVideoSeconds: clearWaitForVideo
          ? null
          : (waitForVideoSeconds ?? this.waitForVideoSeconds),
      hlsUseMpegts: hlsUseMpegts ?? this.hlsUseMpegts,
      playlistItems: clearPlaylistItems
          ? null
          : (playlistItems ?? this.playlistItems),
      yesPlaylist: yesPlaylist ?? this.yesPlaylist,
      rawCustomArgs: rawCustomArgs ?? this.rawCustomArgs,
    );
  }

  List<String> buildSearchArgs() {
    final args = <String>[];
    if (restrictFilenames) {
      args.add('--restrict-filenames');
    }
    if (forceIpv4) {
      args.add('-4');
    } else if (forceIpv6) {
      args.add('-6');
    }
    if (proxy != null && proxy!.trim().isNotEmpty) {
      args.addAll(['--proxy', proxy!.trim()]);
    }
    if (userAgent != null && userAgent!.trim().isNotEmpty) {
      args.addAll(['--add-header', 'User-Agent:${userAgent!.trim()}']);
    }
    if (cookiesBrowser != null && cookiesBrowser!.trim().isNotEmpty) {
      args.addAll(['--cookies-from-browser', cookiesBrowser!.trim()]);
    } else if (cookiesFilePath != null && cookiesFilePath!.trim().isNotEmpty) {
      args.addAll(['--cookies', cookiesFilePath!.trim()]);
    }
    if (preferProtocolCompatibility) {
      args.addAll(['-S', 'proto,vcodec:h264,ext']);
    } else if (formatSortString != null && formatSortString!.trim().isNotEmpty) {
      args.addAll(['-S', formatSortString!.trim()]);
    }
    if (geoBypass) {
      args.add('--geo-bypass');
    }
    return args;
  }

  List<String> buildArgs({
    required String formatId,
    bool isLiveStream = false,
  }) {
    final args = <String>[];

    if (restrictFilenames) {
      args.add('--restrict-filenames');
    }

    if (formatId.isNotEmpty) {
      args.addAll(['-f', formatId]);
    }
    if (preferProtocolCompatibility) {
      args.addAll(['-S', 'proto,vcodec:h264,ext']);
    } else if (formatSortString != null && formatSortString!.trim().isNotEmpty) {
      args.addAll(['-S', formatSortString!.trim()]);
    }

    if (useAria2c && !isLiveStream) {
      if (concurrentFragments > 0) {
        args.addAll(['--concurrent-fragments', '$concurrentFragments']);
      }
      args.addAll([
        '--downloader',
        'aria2c',
        '--downloader-args',
        'aria2c:-c -j $aria2Connections -x $aria2Connections -s $aria2Connections -k 1M',
      ]);
    } else if (concurrentFragments > 0) {
      args.addAll([
        '--concurrent-fragments',
        '$concurrentFragments',
      ]);
    }

    if (liveFromStart) {
      args.add('--live-from-start');
    }
    if (hlsUseMpegts) {
      args.add('--hls-use-mpegts');
    }

    if (waitForVideoSeconds != null && waitForVideoSeconds! > 0) {
      args.addAll(['--wait-for-video', '$waitForVideoSeconds']);
    }

    if (yesPlaylist) {
      args.add('--yes-playlist');
    }
    if (playlistItems != null && playlistItems!.trim().isNotEmpty) {
      args.addAll(['--playlist-items', playlistItems!.trim()]);
    }

    if (retries > 0) {
      args.addAll([
        '--retries',
        '$retries',
        '--fragment-retries',
        '$retries',
      ]);
    }

    if (rateLimit != null && rateLimit!.trim().isNotEmpty) {
      args.addAll(['--limit-rate', rateLimit!.trim()]);
    }

    // Audio extraction, quality & Seal ID3/MP4 metadata parsing
    if (isAudioOnly) {
      args.addAll([
        '-x',
        '--audio-format',
        audioFormat,
        '--audio-quality',
        audioQuality,
      ]);
      if (embedMetadata) {
        args.addAll([
          '--parse-metadata',
          '%(release_year,upload_date)s:%(meta_date)s',
          '--parse-metadata',
          '%(album,playlist,title)s:%(meta_album)s',
          '--parse-metadata',
          '%(track_number,playlist_index)d:%(meta_track)s',
        ]);
      }
      if (embedThumbnail && !isLiveStream) {
        args.addAll(['--convert-thumbnails', 'jpg']);
        if (cropAudioArtwork) {
          args.addAll([
            '--ppa',
            "ffmpeg: -c:v mjpeg -vf crop=\"'if(gt(ih,iw),iw,ih)':'if(gt(iw,ih),ih,iw)'\"",
          ]);
        }
      }
    } else {
      if (videoRecodeFormat != null && videoRecodeFormat!.isNotEmpty) {
        args.addAll(['--recode-video', videoRecodeFormat!]);
      }
      if (remuxContainer != null && remuxContainer!.isNotEmpty) {
        args.addAll([
          '--remux-video',
          remuxContainer!,
          '--merge-output-format',
          remuxContainer!,
        ]);
      }
    }

    if (keepVideo) {
      args.add('-k');
    }

    // Metadata & Embeds (Disable thumbnail/chapter embedding on live streams,
    // as MPEG-TS / live HLS containers fail FFmpeg post-processing with exit code 183)
    if (embedMetadata && (!isLiveStream || !hlsUseMpegts)) {
      args.add('--embed-metadata');
    }
    if (embedThumbnail && !isLiveStream) {
      args.add('--embed-thumbnail');
    }
    if (embedChapters && !isLiveStream && !isAudioOnly) {
      args.add('--embed-chapters');
    }

    // Subtitles (with Seal's youtube:skip=translated_subs optimization)
    if (embedSubtitles) {
      args.add('--embed-subs');
      if (writeAutoSubtitles) {
        args.add('--write-auto-subs');
        if (skipAutoTranslatedSubtitles) {
          args.addAll(['--extractor-args', 'youtube:skip=translated_subs']);
        }
      } else {
        args.add('--write-subs');
      }
      if (subLangs.isNotEmpty) {
        args.addAll(['--sub-langs', subLangs]);
      }
    }

    // Network & Proxies
    if (proxy != null && proxy!.trim().isNotEmpty) {
      args.addAll(['--proxy', proxy!.trim()]);
    }
    if (socketTimeout > 0) {
      args.addAll(['--socket-timeout', '$socketTimeout']);
    }
    if (userAgent != null && userAgent!.trim().isNotEmpty) {
      args.addAll([
        '--user-agent',
        userAgent!.trim(),
        '--add-header',
        'User-Agent:${userAgent!.trim()}',
      ]);
    }
    if (forceIpv4) args.add('-4');
    if (forceIpv6) args.add('-6');
    for (final header in customHeaders) {
      if (header.trim().isNotEmpty) {
        args.addAll(['--add-header', header.trim()]);
      }
    }

    // Workarounds & Geo
    if (geoBypass) {
      args.add('--geo-bypass');
      if (geoBypassCountry != null && geoBypassCountry!.trim().isNotEmpty) {
        args.addAll(['--geo-bypass-country', geoBypassCountry!.trim()]);
      }
    }
    if (extractorArgs != null && extractorArgs!.trim().isNotEmpty) {
      args.addAll(['--extractor-args', extractorArgs!.trim()]);
    }

    // Cookies
    if (cookiesBrowser != null && cookiesBrowser!.trim().isNotEmpty) {
      args.addAll(['--cookies-from-browser', cookiesBrowser!.trim()]);
    } else if (cookiesFilePath != null && cookiesFilePath!.trim().isNotEmpty) {
      args.addAll(['--cookies', cookiesFilePath!.trim()]);
    }

    // SponsorBlock
    if (enableSponsorBlock && sponsorBlockCategories.isNotEmpty) {
      args.addAll([
        '--sponsorblock-remove',
        sponsorBlockCategories.join(','),
      ]);
    }

    // Raw user custom flags
    if (rawCustomArgs.trim().isNotEmpty) {
      final tokens = _tokenizeArgs(rawCustomArgs.trim());
      args.addAll(tokens);
    }

    return args;
  }

  String toCommandLine(
    String url,
    String formatId, {
    bool isLiveStream = false,
  }) {
    final buffer = StringBuffer('yt-dlp');
    final args = buildArgs(formatId: formatId, isLiveStream: isLiveStream);
    for (final arg in args) {
      if (arg.contains(' ') || arg.contains('"')) {
        buffer.write(' "${arg.replaceAll('"', r'\"')}"');
      } else {
        buffer.write(' $arg');
      }
    }
    buffer.write(' "$url"');
    return buffer.toString();
  }

  static List<String> _tokenizeArgs(String input) {
    final List<String> tokens = [];
    final regex = RegExp(r'[^\s"\x27]+|"([^"]*)"|\x27([^\x27]*)\x27');
    for (final match in regex.allMatches(input)) {
      if (match.group(1) != null) {
        tokens.add(match.group(1)!);
      } else if (match.group(2) != null) {
        tokens.add(match.group(2)!);
      } else if (match.group(0) != null) {
        tokens.add(match.group(0)!);
      }
    }
    return tokens;
  }
}
