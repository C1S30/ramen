class AppSettings {
  String downloadDirectory;
  bool useAria2c;
  int aria2Threads;
  int maxConcurrentDownloads;
  bool wifiOnly;
  bool autoUpdateEngine;
  String activeTemplateId;
  String defaultAudioFormat;
  String defaultVideoContainer;

  AppSettings({
    this.downloadDirectory = '',
    this.useAria2c = true,
    this.aria2Threads = 16,
    this.maxConcurrentDownloads = 3,
    this.wifiOnly = false,
    this.autoUpdateEngine = true,
    this.activeTemplateId = 'ultra_fast_aria2c',
    this.defaultAudioFormat = 'm4a',
    this.defaultVideoContainer = 'mp4',
  });

  AppSettings copyWith({
    String? downloadDirectory,
    bool? useAria2c,
    int? aria2Threads,
    int? maxConcurrentDownloads,
    bool? wifiOnly,
    bool? autoUpdateEngine,
    String? activeTemplateId,
    String? defaultAudioFormat,
    String? defaultVideoContainer,
  }) {
    return AppSettings(
      downloadDirectory: downloadDirectory ?? this.downloadDirectory,
      useAria2c: useAria2c ?? this.useAria2c,
      aria2Threads: aria2Threads ?? this.aria2Threads,
      maxConcurrentDownloads:
          maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      autoUpdateEngine: autoUpdateEngine ?? this.autoUpdateEngine,
      activeTemplateId: activeTemplateId ?? this.activeTemplateId,
      defaultAudioFormat: defaultAudioFormat ?? this.defaultAudioFormat,
      defaultVideoContainer:
          defaultVideoContainer ?? this.defaultVideoContainer,
    );
  }

  Map<String, dynamic> toJson() => {
        'downloadDirectory': downloadDirectory,
        'useAria2c': useAria2c,
        'aria2Threads': aria2Threads,
        'maxConcurrentDownloads': maxConcurrentDownloads,
        'wifiOnly': wifiOnly,
        'autoUpdateEngine': autoUpdateEngine,
        'activeTemplateId': activeTemplateId,
        'defaultAudioFormat': defaultAudioFormat,
        'defaultVideoContainer': defaultVideoContainer,
      };

  factory AppSettings.fromJson(Map<dynamic, dynamic> map) {
    return AppSettings(
      downloadDirectory: map['downloadDirectory']?.toString() ?? '',
      useAria2c: map['useAria2c'] as bool? ?? true,
      aria2Threads: (map['aria2Threads'] as num?)?.toInt() ?? 16,
      maxConcurrentDownloads:
          (map['maxConcurrentDownloads'] as num?)?.toInt() ?? 3,
      wifiOnly: map['wifiOnly'] as bool? ?? false,
      autoUpdateEngine: map['autoUpdateEngine'] as bool? ?? true,
      activeTemplateId:
          map['activeTemplateId']?.toString() ?? 'ultra_fast_aria2c',
      defaultAudioFormat: map['defaultAudioFormat']?.toString() ?? 'm4a',
      defaultVideoContainer: map['defaultVideoContainer']?.toString() ?? 'mp4',
    );
  }
}
