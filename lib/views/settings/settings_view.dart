import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../controllers/settings_controller.dart';
import '../preview/widgets/advanced_ytdlp_sheet.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsCtrl = context.watch<SettingsController>();
    final settings = settingsCtrl.settings;
    final versions = settingsCtrl.engineVersions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'SETTINGS',
          style: AppStyles.titleMedium.copyWith(letterSpacing: 1.2),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Engine Toolchain Diagnostics Card
            _buildEngineCard(context, settingsCtrl, versions),
            const SizedBox(height: 24),

            // Performance & Downloader (aria2c)
            _buildSectionHeader('DOWNLOAD ACCELERATION (aria2c)'),
            const SizedBox(height: 10),
            _buildSettingCard(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.accent,
                  title: Text('Use aria2c Multi-Connection',
                      style: AppStyles.bodyLarge),
                  subtitle: Text(
                    'Accelerates downloads with parallel sockets',
                    style: AppStyles.bodyMedium,
                  ),
                  value: settings.useAria2c,
                  onChanged: (val) => settingsCtrl.toggleUseAria2c(val),
                ),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Parallel Connections per Server',
                        style: AppStyles.bodyLarge),
                    Text('${settings.aria2Threads} threads',
                        style: AppStyles.monoAccent),
                  ],
                ),
                Slider(
                  value: settings.aria2Threads.toDouble(),
                  min: 1,
                  max: 16,
                  divisions: 15,
                  activeColor: AppColors.accent,
                  inactiveColor: AppColors.surfaceHighlight,
                  onChanged: (val) => settingsCtrl.setAria2Threads(val.round()),
                ),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Max Concurrent Downloads',
                        style: AppStyles.bodyLarge),
                    Text('${settings.maxConcurrentDownloads} tasks',
                        style: AppStyles.monoAccent),
                  ],
                ),
                Slider(
                  value: settings.maxConcurrentDownloads.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: AppColors.accent,
                  inactiveColor: AppColors.surfaceHighlight,
                  onChanged: (val) => settingsCtrl.setMaxConcurrent(val.round()),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Network Constraints
            _buildSectionHeader('NETWORK & STORAGE'),
            const SizedBox(height: 10),
            _buildSettingCard(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.accent,
                  title: Text('Download on Wi-Fi Only',
                      style: AppStyles.bodyLarge),
                  subtitle: Text(
                    'Prevents accidental cellular data usage',
                    style: AppStyles.bodyMedium,
                  ),
                  value: settings.wifiOnly,
                  onChanged: (val) => settingsCtrl.toggleWifiOnly(val),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Download Directory', style: AppStyles.bodyLarge),
                  subtitle: Text(
                    settings.downloadDirectory.isNotEmpty
                        ? settings.downloadDirectory
                        : 'Download/Ramen',
                    style: AppStyles.monoSmall.copyWith(color: AppColors.accentBright),
                  ),
                  trailing: const Icon(Icons.folder_open_rounded,
                      color: AppColors.textSecondary),
                  onTap: () => _showEditDirectoryDialog(context, settingsCtrl),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Format Preferences
            _buildSectionHeader('DEFAULTS'),
            const SizedBox(height: 10),
            _buildSettingCard(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Preferred Audio Format',
                      style: AppStyles.bodyLarge),
                  trailing: DropdownButton<String>(
                    dropdownColor: AppColors.surfaceElevated,
                    value: settings.defaultAudioFormat,
                    underline: const SizedBox(),
                    items: ['m4a', 'mp3', 'flac', 'opus'].map((fmt) {
                      return DropdownMenuItem(
                        value: fmt,
                        child: Text(fmt.toUpperCase(), style: AppStyles.monoLabel),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        settingsCtrl.setDefaultAudioFormat(val);
                      }
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Preferred Video Container',
                      style: AppStyles.bodyLarge),
                  trailing: DropdownButton<String>(
                    dropdownColor: AppColors.surfaceElevated,
                    value: settings.defaultVideoContainer,
                    underline: const SizedBox(),
                    items: ['mp4', 'mkv', 'webm'].map((fmt) {
                      return DropdownMenuItem(
                        value: fmt,
                        child: Text(fmt.toUpperCase(), style: AppStyles.monoLabel),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        settingsCtrl.setDefaultVideoContainer(val);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Advanced yt-dlp Engine Options (Pro)
            _buildSectionHeader('ADVANCED YT-DLP CONFIGURATION (PRO)'),
            const SizedBox(height: 10),
            _buildSettingCard(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.chipBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: AppColors.accentBright,
                    ),
                  ),
                  title: Text('Interactive yt-dlp Suite', style: AppStyles.bodyLarge),
                  subtitle: Text(
                    'Full visual editor for aria2c, proxy, cookies & CLI flags',
                    style: AppStyles.caption,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppColors.textMuted),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AdvancedYtDlpSheet(
                        initialOptions: settings.toYtDlpOptions(),
                        targetUrl: 'https://example.com/video',
                        formatId: 'bestvideo+bestaudio/best',
                        onOptionsChanged: (newOpts) =>
                            settingsCtrl.updateFromYtDlpOptions(newOpts),
                      ),
                    );
                  },
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.accent,
                  title: Text('Embed Subtitles', style: AppStyles.bodyLarge),
                  subtitle: Text('Embeds subs into MP4/MKV video stream', style: AppStyles.caption),
                  value: settings.embedSubtitles,
                  onChanged: (val) =>
                      settingsCtrl.updateSettings(settings.copyWith(embedSubtitles: val)),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.accent,
                  title: Text('Embed Thumbnail & Artwork', style: AppStyles.bodyLarge),
                  subtitle: Text('Attach cover image to media tags', style: AppStyles.caption),
                  value: settings.embedThumbnail,
                  onChanged: (val) =>
                      settingsCtrl.updateSettings(settings.copyWith(embedThumbnail: val)),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.accent,
                  title: Text('Embed Chapters & Metadata', style: AppStyles.bodyLarge),
                  subtitle: Text('Writes artist, title and chapter intervals', style: AppStyles.caption),
                  value: settings.embedChapters,
                  onChanged: (val) =>
                      settingsCtrl.updateSettings(settings.copyWith(embedChapters: val, embedMetadata: val)),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.accent,
                  title: Text('SponsorBlock (Auto-Skip)', style: AppStyles.bodyLarge),
                  subtitle: Text('Removes sponsor segments and filler intros', style: AppStyles.caption),
                  value: settings.enableSponsorBlock,
                  onChanged: (val) =>
                      settingsCtrl.updateSettings(settings.copyWith(enableSponsorBlock: val)),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.accent,
                  title: Text('Geographic Bypass', style: AppStyles.bodyLarge),
                  subtitle: Text('Bypasses geographical restrictions', style: AppStyles.caption),
                  value: settings.geoBypass,
                  onChanged: (val) =>
                      settingsCtrl.updateSettings(settings.copyWith(geoBypass: val)),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Network Proxy', style: AppStyles.bodyLarge),
                  subtitle: Text(
                    settings.proxy.isNotEmpty ? settings.proxy : 'Direct connection (No proxy)',
                    style: AppStyles.monoSmall.copyWith(
                      color: settings.proxy.isNotEmpty ? AppColors.accentBright : AppColors.textMuted,
                    ),
                  ),
                  trailing: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                  onTap: () => _showEditProxyDialog(context, settingsCtrl),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Rate Limit', style: AppStyles.bodyLarge),
                  subtitle: Text(
                    settings.rateLimit.isNotEmpty ? settings.rateLimit : 'Unlimited bandwidth',
                    style: AppStyles.monoSmall.copyWith(
                      color: settings.rateLimit.isNotEmpty ? AppColors.accentBright : AppColors.textMuted,
                    ),
                  ),
                  trailing: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                  onTap: () => _showEditRateLimitDialog(context, settingsCtrl),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Custom yt-dlp Flags', style: AppStyles.bodyLarge),
                  subtitle: Text(
                    settings.rawCustomArgs.isNotEmpty ? settings.rawCustomArgs : 'None specified',
                    style: AppStyles.monoSmall.copyWith(
                      color: settings.rawCustomArgs.isNotEmpty ? AppColors.accentBright : AppColors.textMuted,
                    ),
                  ),
                  trailing: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                  onTap: () => _showEditRawFlagsDialog(context, settingsCtrl),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // About Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'RAMEN v1.0.0',
                    style: AppStyles.monoLabel.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Strict Minimalist Dark Architecture • 70-30-10 Design',
                    style: AppStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: AppStyles.caption.copyWith(letterSpacing: 1.0));
  }

  Widget _buildSettingCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildEngineCard(
    BuildContext context,
    SettingsController controller,
    Map<String, String> versions,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('EMBEDDED TOOLCHAIN', style: AppStyles.caption),
              if (controller.isUpdating)
                Row(
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentBright,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Updating...', style: AppStyles.monoSmall),
                  ],
                )
              else
                InkWell(
                  onTap: () => controller.updateEngine(),
                  child: Text('Check for Updates', style: AppStyles.monoAccent),
                ),
            ],
          ),
          const SizedBox(height: 14),

          _buildEngineRow('yt-dlp Engine', versions['ytdlp'] ?? 'Checking...'),
          const Divider(height: 16),
          _buildEngineRow('FFmpeg Muxer', versions['ffmpeg'] ?? 'Checking...'),
          const Divider(height: 16),
          _buildEngineRow('aria2c Downloader', versions['aria2c'] ?? 'Checking...'),
          const Divider(height: 16),
          _buildEngineRow('Node.js Runtime', versions['node'] ?? 'Checking...'),

          if (controller.updateMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent),
              ),
              child: Text(
                controller.updateMessage!,
                style: AppStyles.monoSmall.copyWith(color: AppColors.accentBright),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEngineRow(String tool, String version) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(tool, style: AppStyles.bodyLarge),
        Text(version, style: AppStyles.monoSmall),
      ],
    );
  }

  void _showEditDirectoryDialog(BuildContext context, SettingsController controller) {
    final textController = TextEditingController(text: controller.settings.downloadDirectory);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Download Directory', style: AppStyles.titleMedium.copyWith(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specify directory path for media outputs:', style: AppStyles.caption),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              style: AppStyles.monoSmall.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceElevated,
                hintText: 'Download/Ramen',
                hintStyle: AppStyles.monoSmall.copyWith(color: AppColors.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              icon: const Icon(Icons.restore_rounded, size: 16, color: AppColors.accentBright),
              label: Text('Reset to Download/Ramen', style: AppStyles.monoSmall.copyWith(color: AppColors.accentBright)),
              onPressed: () => textController.text = 'Download/Ramen',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppStyles.monoSmall.copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final newDir = textController.text.trim();
              controller.setDownloadDirectory(newDir.isEmpty ? 'Download/Ramen' : newDir);
              Navigator.of(ctx).pop();
            },
            child: Text('Save', style: AppStyles.monoSmall.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditProxyDialog(BuildContext context, SettingsController controller) {
    final textController = TextEditingController(text: controller.settings.proxy);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Network Proxy', style: AppStyles.titleMedium.copyWith(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specify SOCKS5 or HTTP proxy URL:', style: AppStyles.caption),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              style: AppStyles.monoSmall.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceElevated,
                hintText: 'socks5://127.0.0.1:1080',
                hintStyle: AppStyles.monoSmall.copyWith(color: AppColors.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppStyles.monoSmall.copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final newProxy = textController.text.trim();
              controller.updateSettings(controller.settings.copyWith(proxy: newProxy));
              Navigator.of(ctx).pop();
            },
            child: Text('Save', style: AppStyles.monoSmall.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditRateLimitDialog(BuildContext context, SettingsController controller) {
    final textController = TextEditingController(text: controller.settings.rateLimit);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Speed Rate Limit', style: AppStyles.titleMedium.copyWith(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Maximum download rate (e.g. 5M, 500K):', style: AppStyles.caption),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              style: AppStyles.monoSmall.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceElevated,
                hintText: '5M',
                hintStyle: AppStyles.monoSmall.copyWith(color: AppColors.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppStyles.monoSmall.copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final limit = textController.text.trim();
              controller.updateSettings(controller.settings.copyWith(rateLimit: limit));
              Navigator.of(ctx).pop();
            },
            child: Text('Save', style: AppStyles.monoSmall.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditRawFlagsDialog(BuildContext context, SettingsController controller) {
    final textController = TextEditingController(text: controller.settings.rawCustomArgs);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Custom yt-dlp Flags', style: AppStyles.titleMedium.copyWith(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pass raw arguments directly to the yt-dlp binary:', style: AppStyles.caption),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              maxLines: 3,
              style: AppStyles.monoSmall.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceElevated,
                hintText: '--no-check-certificates --referer https://...',
                hintStyle: AppStyles.monoSmall.copyWith(color: AppColors.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppStyles.monoSmall.copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final raw = textController.text.trim();
              controller.updateSettings(controller.settings.copyWith(rawCustomArgs: raw));
              Navigator.of(ctx).pop();
            },
            child: Text('Save', style: AppStyles.monoSmall.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
