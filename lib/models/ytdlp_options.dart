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
  final String subLangs;
  final bool embedChapters;

  // Metadata & Thumbnail
  final bool embedThumbnail;
  final bool embedMetadata;

  // Network & Proxy
  final String? proxy;
  final int socketTimeout;
  final String? userAgent;
  final bool forceIpv4;
  final bool forceIpv6;
  final List<String> customHeaders;

  // Bypass & Authentication
  final bool geoBypass;
  final String? geoBypassCountry;
  final String? cookiesBrowser;
  final String? cookiesFilePath;
  final String? extractorArgs;

  // SponsorBlock
  final bool enableSponsorBlock;
  final List<String> sponsorBlockCategories;

  // Unrestricted Raw Arguments
  final String rawCustomArgs;

  const YtDlpOptions({
    this.useAria2c = false,
    this.aria2Connections = 4,
    this.concurrentFragments = 8,
    this.retries = 10,
    this.rateLimit,
    this.isAudioOnly = false,
    this.audioFormat = 'mp3',
    this.audioQuality = '0',
    this.videoRecodeFormat,
    this.remuxContainer,
    this.keepVideo = false,
    this.embedSubtitles = false,
    this.writeAutoSubtitles = false,
    this.subLangs = 'en.*',
    this.embedChapters = true,
    this.embedThumbnail = true,
    this.embedMetadata = true,
    this.proxy,
    this.socketTimeout = 30,
    this.userAgent,
    this.forceIpv4 = false,
    this.forceIpv6 = false,
    this.customHeaders = const [],
    this.geoBypass = true,
    this.geoBypassCountry,
    this.cookiesBrowser,
    this.cookiesFilePath,
    this.extractorArgs,
    this.enableSponsorBlock = false,
    this.sponsorBlockCategories = const ['sponsor', 'selfpromo', 'interaction'],
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
    String? subLangs,
    bool? embedChapters,
    bool? embedThumbnail,
    bool? embedMetadata,
    String? proxy,
    int? socketTimeout,
    String? userAgent,
    bool? forceIpv4,
    bool? forceIpv6,
    List<String>? customHeaders,
    bool? geoBypass,
    String? geoBypassCountry,
    String? cookiesBrowser,
    String? cookiesFilePath,
    String? extractorArgs,
    bool? enableSponsorBlock,
    List<String>? sponsorBlockCategories,
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
      subLangs: subLangs ?? this.subLangs,
      embedChapters: embedChapters ?? this.embedChapters,
      embedThumbnail: embedThumbnail ?? this.embedThumbnail,
      embedMetadata: embedMetadata ?? this.embedMetadata,
      proxy: proxy ?? this.proxy,
      socketTimeout: socketTimeout ?? this.socketTimeout,
      userAgent: userAgent ?? this.userAgent,
      forceIpv4: forceIpv4 ?? this.forceIpv4,
      forceIpv6: forceIpv6 ?? this.forceIpv6,
      customHeaders: customHeaders ?? this.customHeaders,
      geoBypass: geoBypass ?? this.geoBypass,
      geoBypassCountry: geoBypassCountry ?? this.geoBypassCountry,
      cookiesBrowser: cookiesBrowser ?? this.cookiesBrowser,
      cookiesFilePath: cookiesFilePath ?? this.cookiesFilePath,
      extractorArgs: extractorArgs ?? this.extractorArgs,
      enableSponsorBlock: enableSponsorBlock ?? this.enableSponsorBlock,
      sponsorBlockCategories:
          sponsorBlockCategories ?? this.sponsorBlockCategories,
      rawCustomArgs: rawCustomArgs ?? this.rawCustomArgs,
    );
  }

  List<String> buildArgs({required String formatId}) {
    final args = <String>[];

    // Format selection
    if (formatId.isNotEmpty) {
      args.addAll(['-f', formatId]);
    }

    // Downloader & multi-thread aria2c
    if (useAria2c) {
      args.addAll([
        '-N',
        '$concurrentFragments',
        '--downloader',
        'aria2c',
        '--downloader-args',
        'aria2c:-c -j $aria2Connections -x $aria2Connections -s $aria2Connections -k 1M',
      ]);
    } else {
      args.addAll([
        '-N',
        '$concurrentFragments',
      ]);
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

    // Audio extraction & quality
    if (isAudioOnly) {
      args.addAll([
        '-x',
        '--audio-format',
        audioFormat,
        '--audio-quality',
        audioQuality,
      ]);
    } else {
      if (videoRecodeFormat != null && videoRecodeFormat!.isNotEmpty) {
        args.addAll(['--recode-video', videoRecodeFormat!]);
      }
      if (remuxContainer != null && remuxContainer!.isNotEmpty) {
        args.addAll(['--remux-video', remuxContainer!]);
      }
    }

    if (keepVideo) {
      args.add('-k');
    }

    // Metadata & Embeds
    if (embedMetadata) {
      args.add('--embed-metadata');
    }
    if (embedThumbnail) {
      args.add('--embed-thumbnail');
    }
    if (embedChapters) {
      args.add('--embed-chapters');
    }

    // Subtitles
    if (embedSubtitles) {
      args.add('--embed-subs');
      if (writeAutoSubtitles) {
        args.add('--write-auto-subs');
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
      args.addAll(['--user-agent', userAgent!.trim()]);
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

  String toCommandLine(String url, String formatId) {
    final buffer = StringBuffer('yt-dlp');
    final args = buildArgs(formatId: formatId);
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
