import 'ytdlp_options.dart';

class AppSettings {
  String downloadDirectory;
  bool useAria2c;
  int aria2Threads;
  int maxConcurrentDownloads;
  bool wifiOnly;
  String ytDlpUpdateChannel; // 'nightly' or 'stable'
  bool preferProtocolCompatibility;
  bool restrictFilenames;
  bool cropAudioArtwork;
  bool enableBackgroundProcessing;
  bool backgroundNotifications;
  String activeTemplateId;
  String defaultAudioFormat;
  String defaultVideoContainer;

  // Optional yt-dlp Arguments (all disabled by default)
  String proxy;
  String rateLimit;
  String userAgent;
  int socketTimeout;
  bool forceIpv4;
  bool forceIpv6;
  bool embedSubtitles;
  bool writeAutoSubtitles;
  String subLangs;
  bool embedThumbnail;
  bool embedMetadata;
  bool embedChapters;
  bool geoBypass;
  String cookiesFilePath;
  bool enableSponsorBlock;
  String rawCustomArgs;

  AppSettings({
    this.downloadDirectory = 'Download/Ramen',
    this.useAria2c = false,
    this.aria2Threads = 4,
    this.maxConcurrentDownloads = 3,
    this.wifiOnly = false,
    this.ytDlpUpdateChannel = 'nightly',
    this.preferProtocolCompatibility = false,
    this.restrictFilenames = false,
    this.cropAudioArtwork = false,
    this.enableBackgroundProcessing = true,
    this.backgroundNotifications = true,
    this.activeTemplateId = 'best_video_mux',
    this.defaultAudioFormat = 'm4a',
    this.defaultVideoContainer = 'mp4',
    this.proxy = '',
    this.rateLimit = '',
    this.userAgent = '',
    this.socketTimeout = 0,
    this.forceIpv4 = false,
    this.forceIpv6 = false,
    this.embedSubtitles = false,
    this.writeAutoSubtitles = false,
    this.subLangs = 'en.*',
    this.embedThumbnail = false,
    this.embedMetadata = false,
    this.embedChapters = false,
    this.geoBypass = false,
    this.cookiesFilePath = '',
    this.enableSponsorBlock = false,
    this.rawCustomArgs = '',
  });

  AppSettings copyWith({
    String? downloadDirectory,
    bool? useAria2c,
    int? aria2Threads,
    int? maxConcurrentDownloads,
    bool? wifiOnly,
    String? ytDlpUpdateChannel,
    bool? preferProtocolCompatibility,
    bool? restrictFilenames,
    bool? cropAudioArtwork,
    bool? enableBackgroundProcessing,
    bool? backgroundNotifications,
    String? activeTemplateId,
    String? defaultAudioFormat,
    String? defaultVideoContainer,
    String? proxy,
    String? rateLimit,
    String? userAgent,
    int? socketTimeout,
    bool? forceIpv4,
    bool? forceIpv6,
    bool? embedSubtitles,
    bool? writeAutoSubtitles,
    String? subLangs,
    bool? embedThumbnail,
    bool? embedMetadata,
    bool? embedChapters,
    bool? geoBypass,
    String? cookiesFilePath,
    bool? enableSponsorBlock,
    String? rawCustomArgs,
  }) {
    return AppSettings(
      downloadDirectory: downloadDirectory ?? this.downloadDirectory,
      useAria2c: useAria2c ?? this.useAria2c,
      aria2Threads: aria2Threads ?? this.aria2Threads,
      maxConcurrentDownloads:
          maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      ytDlpUpdateChannel: ytDlpUpdateChannel ?? this.ytDlpUpdateChannel,
      preferProtocolCompatibility:
          preferProtocolCompatibility ?? this.preferProtocolCompatibility,
      restrictFilenames: restrictFilenames ?? this.restrictFilenames,
      cropAudioArtwork: cropAudioArtwork ?? this.cropAudioArtwork,
      enableBackgroundProcessing:
          enableBackgroundProcessing ?? this.enableBackgroundProcessing,
      backgroundNotifications:
          backgroundNotifications ?? this.backgroundNotifications,
      activeTemplateId: activeTemplateId ?? this.activeTemplateId,
      defaultAudioFormat: defaultAudioFormat ?? this.defaultAudioFormat,
      defaultVideoContainer:
          defaultVideoContainer ?? this.defaultVideoContainer,
      proxy: proxy ?? this.proxy,
      rateLimit: rateLimit ?? this.rateLimit,
      userAgent: userAgent ?? this.userAgent,
      socketTimeout: socketTimeout ?? this.socketTimeout,
      forceIpv4: forceIpv4 ?? this.forceIpv4,
      forceIpv6: forceIpv6 ?? this.forceIpv6,
      embedSubtitles: embedSubtitles ?? this.embedSubtitles,
      writeAutoSubtitles: writeAutoSubtitles ?? this.writeAutoSubtitles,
      subLangs: subLangs ?? this.subLangs,
      embedThumbnail: embedThumbnail ?? this.embedThumbnail,
      embedMetadata: embedMetadata ?? this.embedMetadata,
      embedChapters: embedChapters ?? this.embedChapters,
      geoBypass: geoBypass ?? this.geoBypass,
      cookiesFilePath: cookiesFilePath ?? this.cookiesFilePath,
      enableSponsorBlock: enableSponsorBlock ?? this.enableSponsorBlock,
      rawCustomArgs: rawCustomArgs ?? this.rawCustomArgs,
    );
  }

  Map<String, dynamic> toJson() => {
        'downloadDirectory': downloadDirectory,
        'useAria2c': useAria2c,
        'aria2Threads': aria2Threads,
        'maxConcurrentDownloads': maxConcurrentDownloads,
        'wifiOnly': wifiOnly,
        'ytDlpUpdateChannel': ytDlpUpdateChannel,
        'preferProtocolCompatibility': preferProtocolCompatibility,
        'restrictFilenames': restrictFilenames,
        'cropAudioArtwork': cropAudioArtwork,
        'enableBackgroundProcessing': enableBackgroundProcessing,
        'backgroundNotifications': backgroundNotifications,
        'activeTemplateId': activeTemplateId,
        'defaultAudioFormat': defaultAudioFormat,
        'defaultVideoContainer': defaultVideoContainer,
        'proxy': proxy,
        'rateLimit': rateLimit,
        'userAgent': userAgent,
        'socketTimeout': socketTimeout,
        'forceIpv4': forceIpv4,
        'forceIpv6': forceIpv6,
        'embedSubtitles': embedSubtitles,
        'writeAutoSubtitles': writeAutoSubtitles,
        'subLangs': subLangs,
        'embedThumbnail': embedThumbnail,
        'embedMetadata': embedMetadata,
        'embedChapters': embedChapters,
        'geoBypass': geoBypass,
        'cookiesFilePath': cookiesFilePath,
        'enableSponsorBlock': enableSponsorBlock,
        'rawCustomArgs': rawCustomArgs,
      };

  factory AppSettings.fromJson(Map<dynamic, dynamic> map) {
    return AppSettings(
      downloadDirectory: (map['downloadDirectory'] == null ||
              map['downloadDirectory'].toString().trim().isEmpty)
          ? 'Download/Ramen'
          : map['downloadDirectory'].toString(),
      useAria2c: map['useAria2c'] as bool? ?? false,
      aria2Threads: (map['aria2Threads'] as num?)?.toInt() ?? 4,
      maxConcurrentDownloads:
          (map['maxConcurrentDownloads'] as num?)?.toInt() ?? 3,
      wifiOnly: map['wifiOnly'] as bool? ?? false,
      ytDlpUpdateChannel: map['ytDlpUpdateChannel']?.toString() ?? 'nightly',
      preferProtocolCompatibility:
          map['preferProtocolCompatibility'] as bool? ?? false,
      restrictFilenames: map['restrictFilenames'] as bool? ?? false,
      cropAudioArtwork: map['cropAudioArtwork'] as bool? ?? false,
      enableBackgroundProcessing:
          map['enableBackgroundProcessing'] as bool? ?? true,
      backgroundNotifications:
          map['backgroundNotifications'] as bool? ?? true,
      activeTemplateId:
          map['activeTemplateId']?.toString() ?? 'best_video_mux',
      defaultAudioFormat: map['defaultAudioFormat']?.toString() ?? 'm4a',
      defaultVideoContainer: map['defaultVideoContainer']?.toString() ?? 'mp4',
      proxy: map['proxy']?.toString() ?? '',
      rateLimit: map['rateLimit']?.toString() ?? '',
      userAgent: map['userAgent']?.toString() ?? '',
      socketTimeout: (map['socketTimeout'] as num?)?.toInt() ?? 0,
      forceIpv4: map['forceIpv4'] as bool? ?? false,
      forceIpv6: map['forceIpv6'] as bool? ?? false,
      embedSubtitles: map['embedSubtitles'] as bool? ?? false,
      writeAutoSubtitles: map['writeAutoSubtitles'] as bool? ?? false,
      subLangs: map['subLangs']?.toString() ?? 'en.*',
      embedThumbnail: map['embedThumbnail'] as bool? ?? false,
      embedMetadata: map['embedMetadata'] as bool? ?? false,
      embedChapters: map['embedChapters'] as bool? ?? false,
      geoBypass: map['geoBypass'] as bool? ?? false,
      cookiesFilePath: map['cookiesFilePath']?.toString() ?? '',
      enableSponsorBlock: map['enableSponsorBlock'] as bool? ?? false,
      rawCustomArgs: map['rawCustomArgs']?.toString() ?? '',
    );
  }

  YtDlpOptions toYtDlpOptions() {
    return YtDlpOptions(
      useAria2c: useAria2c,
      aria2Connections: aria2Threads,
      proxy: proxy.trim().isNotEmpty ? proxy.trim() : null,
      rateLimit: rateLimit.trim().isNotEmpty ? rateLimit.trim() : null,
      userAgent: userAgent.trim().isNotEmpty ? userAgent.trim() : null,
      socketTimeout: socketTimeout,
      forceIpv4: forceIpv4,
      forceIpv6: forceIpv6,
      embedSubtitles: embedSubtitles,
      writeAutoSubtitles: writeAutoSubtitles,
      subLangs: subLangs,
      embedThumbnail: embedThumbnail,
      embedMetadata: embedMetadata,
      embedChapters: embedChapters,
      cropAudioArtwork: cropAudioArtwork,
      restrictFilenames: restrictFilenames,
      preferProtocolCompatibility: preferProtocolCompatibility,
      geoBypass: geoBypass,
      cookiesFilePath:
          cookiesFilePath.trim().isNotEmpty ? cookiesFilePath.trim() : null,
      enableSponsorBlock: enableSponsorBlock,
      rawCustomArgs: rawCustomArgs,
    );
  }
}
