import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../models/ytdlp_options.dart';

class AdvancedYtDlpSheet extends StatefulWidget {
  final YtDlpOptions initialOptions;
  final String targetUrl;
  final String formatId;
  final ValueChanged<YtDlpOptions> onOptionsChanged;

  const AdvancedYtDlpSheet({
    super.key,
    required this.initialOptions,
    required this.targetUrl,
    required this.formatId,
    required this.onOptionsChanged,
  });

  @override
  State<AdvancedYtDlpSheet> createState() => _AdvancedYtDlpSheetState();
}

class _AdvancedYtDlpSheetState extends State<AdvancedYtDlpSheet> {
  late YtDlpOptions _options;
  late TextEditingController _proxyController;
  late TextEditingController _userAgentController;
  late TextEditingController _rateLimitController;
  late TextEditingController _rawArgsController;
  late TextEditingController _subLangsController;
  late TextEditingController _cookiesFileController;

  @override
  void initState() {
    super.initState();
    _options = widget.initialOptions;
    _proxyController = TextEditingController(text: _options.proxy ?? '');
    _userAgentController = TextEditingController(
      text: _options.userAgent ?? '',
    );
    _rateLimitController = TextEditingController(
      text: _options.rateLimit ?? '',
    );
    _rawArgsController = TextEditingController(text: _options.rawCustomArgs);
    _subLangsController = TextEditingController(text: _options.subLangs);
    _cookiesFileController = TextEditingController(
      text: _options.cookiesFilePath ?? '',
    );
  }

  @override
  void dispose() {
    _proxyController.dispose();
    _userAgentController.dispose();
    _rateLimitController.dispose();
    _rawArgsController.dispose();
    _subLangsController.dispose();
    _cookiesFileController.dispose();
    super.dispose();
  }

  void _update(YtDlpOptions next) {
    setState(() {
      _options = next;
    });
    widget.onOptionsChanged(_options);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      child: Column(
        children: [
          // Drag handle & title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.accentMuted,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: AppColors.accentBright,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'ADVANCED CONFIGURATION',
                          style: AppStyles.monoHeadline.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: AppColors.textSecondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Settings Form
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // Live CLI command preview
                _buildCliPreview(),
                const SizedBox(height: 16),

                // 1. Aria2c & Downloader Acceleration
                _buildSectionHeader(
                  'ARIA2C MULTI-THREAD ACCELERATION',
                  Icons.speed_rounded,
                ),
                _buildSwitchTile(
                  title: 'Embedded aria2c Downloader',
                  subtitle: '16-connection multi-socket acceleration',
                  value: _options.useAria2c,
                  onChanged: (val) =>
                      _update(_options.copyWith(useAria2c: val)),
                ),
                if (_options.useAria2c) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Concurrent connections',
                          style: AppStyles.bodyMedium,
                        ),
                        Text(
                          '${_options.aria2Connections} threads',
                          style: AppStyles.monoAccent,
                        ),
                      ],
                    ),
                  ),
                  Slider(
                    value: _options.aria2Connections.toDouble(),
                    min: 1,
                    max: 32,
                    divisions: 31,
                    activeColor: AppColors.accentBright,
                    inactiveColor: AppColors.surfaceElevated,
                    onChanged: (val) => _update(
                      _options.copyWith(aria2Connections: val.round()),
                    ),
                  ),
                ],
                _buildTextField(
                  controller: _rateLimitController,
                  label: 'Rate Limit (e.g. 5M, 500K)',
                  hint: 'Uncapped',
                  onChanged: (val) => _update(
                    _options.copyWith(rateLimit: val.isEmpty ? null : val),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. FFmpeg Post-Processing & Audio
                _buildSectionHeader(
                  'FFMPEG POST-PROCESSING',
                  Icons.transform_rounded,
                ),
                _buildDropdown<String>(
                  title: 'Audio Conversion Format',
                  value: _options.audioFormat,
                  items: const ['mp3', 'm4a', 'opus', 'flac', 'wav'],
                  onChanged: (val) {
                    if (val != null) {
                      _update(_options.copyWith(audioFormat: val));
                    }
                  },
                ),
                _buildDropdown<String>(
                  title: 'Audio Quality Bitrate',
                  value: _options.audioQuality,
                  items: const ['0', '320k', '256k', '192k', '128k'],
                  onChanged: (val) {
                    if (val != null) {
                      _update(_options.copyWith(audioQuality: val));
                    }
                  },
                ),
                _buildDropdown<String?>(
                  title: 'Remux Video Container',
                  value: _options.remuxContainer,
                  items: const [null, 'mp4', 'mkv', 'webm'],
                  itemLabels: {
                    null: 'Source Container',
                    'mp4': 'MP4',
                    'mkv': 'MKV',
                    'webm': 'WebM',
                  },
                  onChanged: (val) =>
                      _update(_options.copyWith(remuxContainer: val)),
                ),
                _buildSwitchTile(
                  title: 'Keep Original Video Streams',
                  subtitle: 'Preserve source files after post-processing (-k)',
                  value: _options.keepVideo,
                  onChanged: (val) =>
                      _update(_options.copyWith(keepVideo: val)),
                ),
                const SizedBox(height: 20),

                // 3. Subtitles & Chapters
                _buildSectionHeader(
                  'SUBTITLES & CHAPTERS',
                  Icons.subtitles_rounded,
                ),
                _buildSwitchTile(
                  title: 'Embed Subtitles into Video',
                  subtitle: 'Soft-code subtitles into MP4/MKV container',
                  value: _options.embedSubtitles,
                  onChanged: (val) =>
                      _update(_options.copyWith(embedSubtitles: val)),
                ),
                if (_options.embedSubtitles) ...[
                  _buildSwitchTile(
                    title: 'Include Auto-Generated Subtitles',
                    subtitle: 'Fetch machine-generated captions if available',
                    value: _options.writeAutoSubtitles,
                    onChanged: (val) =>
                        _update(_options.copyWith(writeAutoSubtitles: val)),
                  ),
                  _buildTextField(
                    controller: _subLangsController,
                    label: 'Subtitle Languages (Regex or comma-separated)',
                    hint: 'en.*,es',
                    onChanged: (val) =>
                        _update(_options.copyWith(subLangs: val)),
                  ),
                ],
                _buildSwitchTile(
                  title: 'Embed Video Chapters',
                  subtitle: 'Include track chapters in media container',
                  value: _options.embedChapters,
                  onChanged: (val) =>
                      _update(_options.copyWith(embedChapters: val)),
                ),
                const SizedBox(height: 20),

                // 4. Metadata & Artwork
                _buildSectionHeader('METADATA & ARTWORK', Icons.image_rounded),
                _buildSwitchTile(
                  title: 'Embed High-Res Thumbnail',
                  subtitle: 'Embed cover art as video/audio thumbnail',
                  value: _options.embedThumbnail,
                  onChanged: (val) =>
                      _update(_options.copyWith(embedThumbnail: val)),
                ),
                _buildSwitchTile(
                  title: 'Embed ID3 / Container Tags',
                  subtitle: 'Title, artist, album, date, and descriptions',
                  value: _options.embedMetadata,
                  onChanged: (val) =>
                      _update(_options.copyWith(embedMetadata: val)),
                ),
                const SizedBox(height: 20),

                // 5. Network, Proxy & Headers
                _buildSectionHeader('NETWORK & PROXY', Icons.public_rounded),
                _buildTextField(
                  controller: _proxyController,
                  label: 'Proxy URL (HTTP/HTTPS/SOCKS5)',
                  hint: 'socks5://127.0.0.1:9050',
                  onChanged: (val) => _update(
                    _options.copyWith(proxy: val.isEmpty ? null : val),
                  ),
                ),
                _buildTextField(
                  controller: _userAgentController,
                  label: 'Custom User-Agent',
                  hint: 'Default yt-dlp browser agent',
                  onChanged: (val) => _update(
                    _options.copyWith(userAgent: val.isEmpty ? null : val),
                  ),
                ),
                _buildSwitchTile(
                  title: 'Force IPv4 Only',
                  subtitle: 'Bypass broken IPv6 ISP routes (-4)',
                  value: _options.forceIpv4,
                  onChanged: (val) => _update(
                    _options.copyWith(forceIpv4: val, forceIpv6: false),
                  ),
                ),
                _buildSwitchTile(
                  title: 'Geo-Bypass Restrictions',
                  subtitle: 'Simulate regional IP headers (--geo-bypass)',
                  value: _options.geoBypass,
                  onChanged: (val) =>
                      _update(_options.copyWith(geoBypass: val)),
                ),
                const SizedBox(height: 20),

                // 6. Cookies & Authentication
                _buildSectionHeader(
                  'COOKIES & AUTHENTICATION',
                  Icons.cookie_rounded,
                ),
                _buildDropdown<String?>(
                  title: 'Extract Cookies from Browser',
                  value: _options.cookiesBrowser,
                  items: const [
                    null,
                    'chrome',
                    'firefox',
                    'brave',
                    'edge',
                    'chromium',
                  ],
                  itemLabels: {
                    null: 'None',
                    'chrome': 'Chrome',
                    'firefox': 'Firefox',
                    'brave': 'Brave',
                    'edge': 'Edge',
                    'chromium': 'Chromium',
                  },
                  onChanged: (val) =>
                      _update(_options.copyWith(cookiesBrowser: val)),
                ),
                _buildTextField(
                  controller: _cookiesFileController,
                  label: 'Cookies File Path (Netscape format)',
                  hint: '/path/to/cookies.txt',
                  onChanged: (val) => _update(
                    _options.copyWith(
                      cookiesFilePath: val.isEmpty ? null : val,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 7. Live Stream & Broadcast
                _buildSectionHeader(
                  'LIVE STREAM & BROADCAST',
                  Icons.sensors_rounded,
                ),
                _buildSwitchTile(
                  title: 'Download Live from Start',
                  subtitle:
                      'Record from beginning of broadcast via DVR (--live-from-start)',
                  value: _options.liveFromStart,
                  onChanged: (val) =>
                      _update(_options.copyWith(liveFromStart: val)),
                ),
                _buildSwitchTile(
                  title: 'Use MPEG-TS for Live HLS',
                  subtitle:
                      'Keep stream playable if interrupted (--hls-use-mpegts)',
                  value: _options.hlsUseMpegts,
                  onChanged: (val) =>
                      _update(_options.copyWith(hlsUseMpegts: val)),
                ),
                _buildDropdown<int?>(
                  title: 'Wait for Scheduled Stream',
                  value: _options.waitForVideoSeconds,
                  items: const [null, 15, 30, 60, 120, 300],
                  itemLabels: const {
                    null: 'Disabled',
                    15: 'Poll every 15s',
                    30: 'Poll every 30s',
                    60: 'Poll every 60s',
                    120: 'Poll every 2m',
                    300: 'Poll every 5m',
                  },
                  onChanged: (val) => _update(
                    _options.copyWith(
                      waitForVideoSeconds: val,
                      clearWaitForVideo: val == null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 8. SponsorBlock
                _buildSectionHeader('SPONSORBLOCK', Icons.content_cut_rounded),
                _buildSwitchTile(
                  title: 'Remove Sponsored Segments',
                  subtitle:
                      'Automatically cut sponsored, self-promo & intro segments',
                  value: _options.enableSponsorBlock,
                  onChanged: (val) =>
                      _update(_options.copyWith(enableSponsorBlock: val)),
                ),
                const SizedBox(height: 20),

                // 8. Raw yt-dlp CLI Flags (Supports ALL commands)
                _buildSectionHeader(
                  'RAW YT-DLP CLI ARGUMENTS',
                  Icons.terminal_rounded,
                ),
                Text(
                  'Enter any official yt-dlp command line arguments. These are directly appended to the execution command.',
                  style: AppStyles.caption,
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _rawArgsController,
                  label: 'Custom yt-dlp Arguments',
                  hint: '--no-check-certificates --limit-rate 10M',
                  maxLines: 2,
                  onChanged: (val) =>
                      _update(_options.copyWith(rawCustomArgs: val)),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCliPreview() {
    final cmd = _options.toCommandLine(widget.targetUrl, widget.formatId);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.code_rounded,
                size: 14,
                color: AppColors.accentBright,
              ),
              const SizedBox(width: 6),
              Text(
                'ACTIVE DOWNLOAD TEMPLATE',
                style: AppStyles.monoSmall.copyWith(
                  color: AppColors.accentBright,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            cmd,
            style: AppStyles.monoSmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: 10.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.accentBright),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppStyles.monoSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppStyles.bodyLarge.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppStyles.caption),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String title,
    required T value,
    required List<T> items,
    Map<T, String>? itemLabels,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
          DropdownButton<T>(
            value: value,
            dropdownColor: AppColors.surfaceElevated,
            underline: const SizedBox.shrink(),
            icon: const Icon(
              Icons.arrow_drop_down,
              color: AppColors.accentBright,
            ),
            items: items.map((item) {
              final label = itemLabels != null
                  ? (itemLabels[item] ?? '$item')
                  : '$item';
              return DropdownMenuItem<T>(
                value: item,
                child: Text(label, style: AppStyles.monoSmall),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: AppStyles.monoSmall.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppStyles.caption,
          hintText: hint,
          hintStyle: AppStyles.monoSmall.copyWith(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.surfaceElevated,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.accentBright),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
