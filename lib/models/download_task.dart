enum DownloadStatus {
  queued,
  downloading,
  postProcessing,
  completed,
  paused,
  failed,
  cancelled,
}

class DownloadTask {
  final String id;
  final String url;
  final String title;
  final String? uploader;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final String selectedFormatId;
  final String extension;
  final int? totalBytes;
  int downloadedBytes;
  double progress; // 0.0 to 100.0
  String speed;
  String eta;
  DownloadStatus status;
  String? localFilePath;
  final DateTime createdAt;
  DateTime? completedAt;
  List<String> commandFlags;
  String? errorLog;

  DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    this.uploader,
    this.thumbnailUrl,
    this.durationSeconds,
    required this.selectedFormatId,
    required this.extension,
    this.totalBytes,
    this.downloadedBytes = 0,
    this.progress = 0.0,
    this.speed = '0.0 KB/s',
    this.eta = '--:--',
    this.status = DownloadStatus.queued,
    this.localFilePath,
    DateTime? createdAt,
    this.completedAt,
    this.commandFlags = const [],
    this.errorLog,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isActive =>
      status == DownloadStatus.queued ||
      status == DownloadStatus.downloading ||
      status == DownloadStatus.postProcessing;

  bool get isCompleted => status == DownloadStatus.completed;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isPaused => status == DownloadStatus.paused;

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'title': title,
        'uploader': uploader,
        'thumbnailUrl': thumbnailUrl,
        'durationSeconds': durationSeconds,
        'selectedFormatId': selectedFormatId,
        'extension': extension,
        'totalBytes': totalBytes,
        'downloadedBytes': downloadedBytes,
        'progress': progress,
        'speed': speed,
        'eta': eta,
        'status': status.name,
        'localFilePath': localFilePath,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'commandFlags': commandFlags,
        'errorLog': errorLog,
      };

  factory DownloadTask.fromJson(Map<dynamic, dynamic> map) {
    return DownloadTask(
      id: map['id']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled',
      uploader: map['uploader']?.toString(),
      thumbnailUrl: map['thumbnailUrl']?.toString(),
      durationSeconds: map['durationSeconds'] as int?,
      selectedFormatId: map['selectedFormatId']?.toString() ?? 'best',
      extension: map['extension']?.toString() ?? 'mp4',
      totalBytes: map['totalBytes'] as int?,
      downloadedBytes: (map['downloadedBytes'] as num?)?.toInt() ?? 0,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      speed: map['speed']?.toString() ?? '0.0 KB/s',
      eta: map['eta']?.toString() ?? '--:--',
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DownloadStatus.queued,
      ),
      localFilePath: map['localFilePath']?.toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'])
          : null,
      commandFlags: (map['commandFlags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      errorLog: map['errorLog']?.toString(),
    );
  }
}
