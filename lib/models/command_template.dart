class CommandTemplate {
  final String id;
  final String name;
  final String description;
  final List<String> flags;
  final bool isBuiltIn;
  final bool isDefault;
  final String iconKey; // For UI rendering

  CommandTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.flags,
    this.isBuiltIn = false,
    this.isDefault = false,
    this.iconKey = 'bolt',
  });

  CommandTemplate copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? flags,
    bool? isBuiltIn,
    bool? isDefault,
    String? iconKey,
  }) {
    return CommandTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      flags: flags ?? this.flags,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isDefault: isDefault ?? this.isDefault,
      iconKey: iconKey ?? this.iconKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'flags': flags,
        'isBuiltIn': isBuiltIn,
        'isDefault': isDefault,
        'iconKey': iconKey,
      };

  factory CommandTemplate.fromJson(Map<dynamic, dynamic> map) {
    return CommandTemplate(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Custom Template',
      description: map['description']?.toString() ?? '',
      flags: (map['flags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isBuiltIn: map['isBuiltIn'] as bool? ?? false,
      isDefault: map['isDefault'] as bool? ?? false,
      iconKey: map['iconKey']?.toString() ?? 'code',
    );
  }

  static List<CommandTemplate> get defaultPresets => [
        CommandTemplate(
          id: 'ultra_fast_aria2c',
          name: 'Ultra-Fast Multi-Segment',
          description: 'Leverages aria2c with 16 parallel socket connections',
          flags: [
            '-N', '16',
            '--downloader', 'aria2c',
            '--downloader-args', 'aria2c:-x 16 -s 16 -k 1M',
          ],
          isBuiltIn: true,
          isDefault: true,
          iconKey: 'bolt',
        ),
        CommandTemplate(
          id: 'best_video_mux',
          name: 'Best 4K/UHD Video + Audio',
          description: 'Merges highest resolution stream with best audio into MKV',
          flags: [
            '-f', 'bestvideo+bestaudio/best',
            '--merge-output-format', 'mkv',
          ],
          isBuiltIn: true,
          iconKey: 'video',
        ),
        CommandTemplate(
          id: 'lossless_audio',
          name: 'Audiophile Lossless (FLAC)',
          description: 'Extracts studio-grade FLAC with embedded thumbnail & tags',
          flags: [
            '-x',
            '--audio-format', 'flac',
            '--audio-quality', '0',
            '--embed-thumbnail',
            '--add-metadata',
          ],
          isBuiltIn: true,
          iconKey: 'music',
        ),
        CommandTemplate(
          id: 'data_saver_720p',
          name: 'Mobile Data Saver (720p)',
          description: 'Restricts video to 720p MP4 for lightweight bandwidth & storage',
          flags: [
            '-f', 'bestvideo[height<=720]+bestaudio/best',
            '--merge-output-format', 'mp4',
          ],
          isBuiltIn: true,
          iconKey: 'download',
        ),
        CommandTemplate(
          id: 'full_archive',
          name: 'Archive with Subtitles',
          description: 'Downloads media with embedded auto-subtitles & chapters',
          flags: [
            '--write-subs',
            '--write-auto-subs',
            '--embed-subs',
            '--embed-chapters',
          ],
          isBuiltIn: true,
          iconKey: 'subtitles',
        ),
      ];
}
