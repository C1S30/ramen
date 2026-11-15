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
        titleSpacing: 22,
        centerTitle: false,
        title: Row(
          children: [
            Text(
              'SETTINGS',
              style: AppStyles.monoHeadline.copyWith(
                fontSize: 15,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Text(
                settings.ytDlpUpdateChannel.toUpperCase(),
                style: AppStyles.monoSmall.copyWith(
                  fontSize: 10,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEngineBentoCard(context, settingsCtrl, versions),
            const SizedBox(height: 22),

            _buildSectionHeader('ACCELERATION // ARIA2C'),
            const SizedBox(height: 10),
            _buildSettingCard(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'aria2c Multi-Socket Engine',
                    style: AppStyles.monoLabel,
                  ),
                  subtitle: Text(
                    'Parallel segment acceleration for non-live streams',
                    style: AppStyles.caption,
                  ),
                  value: settings.useAria2c,
                  onChanged: settingsCtrl.toggleUseAria2c,
                ),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PARALLEL CONNECTIONS', style: AppStyles.monoSmall),
                    Text(
                      '${settings.aria2Threads} THREADS',
                      style: AppStyles.monoAccent,
                    ),
                  ],
                ),
                Slider(
                  value: settings.aria2Threads.toDouble(),
                  min: 1,
                  max: 16,
                  divisions: 15,
                  onChanged: (val) => settingsCtrl.setAria2Threads(val.round()),
                ),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CONCURRENT QUEUE WORKERS',
                      style: AppStyles.monoSmall,
                    ),
                    Text(
                      '${settings.maxConcurrentDownloads} TASKS',
                      style: AppStyles.monoAccent,
                    ),
                  ],
                ),
                Slider(
                  value: settings.maxConcurrentDownloads.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (val) =>
                      settingsCtrl.setMaxConcurrent(val.round()),
                ),
              ],
            ),
            const SizedBox(height: 22),

            _buildSectionHeader('STORAGE & DEFAULTS'),
            const SizedBox(height: 10),
            _buildSettingCard(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Output Directory', style: AppStyles.monoLabel),
                  subtitle: Text(
                    settings.downloadDirectory.isNotEmpty
                        ? settings.downloadDirectory
                        : 'Download/Ramen',
                    style: AppStyles.monoSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.folder_open_rounded,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                  onTap: () => _showEditDirectoryDialog(context, settingsCtrl),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Default Audio Format',
                    style: AppStyles.monoLabel,
                  ),
                  trailing: DropdownButton<String>(
                    dropdownColor: AppColors.surfaceElevated,
                    value: settings.defaultAudioFormat,
                    underline: const SizedBox(),
                    items: ['m4a', 'mp3', 'flac', 'opus'].map((fmt) {
                      return DropdownMenuItem(
                        value: fmt,
                        child: Text(
                          fmt.toUpperCase(),
                          style: AppStyles.monoLabel,
                        ),
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
                  title: Text(
                    'Default Video Container',
                    style: AppStyles.monoLabel,
                  ),
                  trailing: DropdownButton<String>(
                    dropdownColor: AppColors.surfaceElevated,
                    value: settings.defaultVideoContainer,
                    underline: const SizedBox(),
                    items: ['mp4', 'mkv', 'webm'].map((fmt) {
                      return DropdownMenuItem(
                        value: fmt,
                        child: Text(
                          fmt.toUpperCase(),
                          style: AppStyles.monoLabel,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        settingsCtrl.setDefaultVideoContainer(val);
                      }
                    },
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Wi-Fi Only Transfers',
                    style: AppStyles.monoLabel,
                  ),
                  subtitle: Text(
                    'Block downloads over cellular connections',
                    style: AppStyles.caption,
                  ),
                  value: settings.wifiOnly,
                  onChanged: settingsCtrl.toggleWifiOnly,
                ),
              ],
            ),
            const SizedBox(height: 22),

            _buildSectionHeader('AUTHENTICATION & 403 BYPASS'),
            const SizedBox(height: 10),
            _buildSettingCard(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Netscape Cookies (cookies.txt)',
                    style: AppStyles.monoLabel,
                  ),
                  subtitle: Text(
                    settings.cookiesFilePath.isNotEmpty
                        ? 'ACTIVE // Cookies loaded'
                        : 'Optional cookies.txt for authenticated downloads',
                    style: AppStyles.caption.copyWith(
                      color: settings.cookiesFilePath.isNotEmpty
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.key_rounded,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                  onTap: () => _showEditCookiesDialog(context, settingsCtrl),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Force IPv4 (-4)', style: AppStyles.monoLabel),
                  subtitle: Text(
                    'Optional: force IPv4 connections',
                    style: AppStyles.caption,
                  ),
                  value: settings.forceIpv4,
                  onChanged: (val) => settingsCtrl.updateSettings(
                    settings.copyWith(forceIpv4: val, forceIpv6: false),
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Geo Bypass (--geo-bypass)', style: AppStyles.monoLabel),
                  subtitle: Text(
                    'Optional: bypass geographic restrictions',
                    style: AppStyles.caption,
                  ),
                  value: settings.geoBypass,
                  onChanged: (val) => settingsCtrl.updateSettings(
                    settings.copyWith(geoBypass: val),
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Protocol Compatibility (-S proto)',
                    style: AppStyles.monoLabel,
                  ),
                  subtitle: Text(
                    'Optional: prefer direct HTTPS streams',
                    style: AppStyles.caption,
                  ),
                  value: settings.preferProtocolCompatibility,
                  onChanged: (val) => settingsCtrl.updateSettings(
                    settings.copyWith(preferProtocolCompatibility: val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            _buildSectionHeader('BACKGROUND & POST-PROCESSING'),
            const SizedBox(height: 10),
            _buildSettingCard(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Background Service', style: AppStyles.monoLabel),
                  subtitle: Text(
                    'Keep extractions running when app is minimized',
                    style: AppStyles.caption,
                  ),
                  value: settings.enableBackgroundProcessing,
                  onChanged: settingsCtrl.toggleBackgroundProcessing,
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Unrestricted Battery Mode',
                    style: AppStyles.monoLabel,
                  ),
                  subtitle: Text(
                    settingsCtrl.isIgnoringBatteryOptimizations
                        ? 'EXEMPTED // Background jobs unrestricted'
                        : 'Tap to exempt Ramen from Android battery throttling',
                    style: AppStyles.caption,
                  ),
                  trailing: Icon(
                    settingsCtrl.isIgnoringBatteryOptimizations
                        ? Icons.verified_outlined
                        : Icons.battery_saver_rounded,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                  onTap: settingsCtrl.isIgnoringBatteryOptimizations
                      ? null
                      : settingsCtrl.requestUnrestrictedBattery,
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Embed Artwork & Metadata',
                    style: AppStyles.monoLabel,
                  ),
                  subtitle: Text(
                    'Write ID3 tags, 1:1 album cover art & chapters',
                    style: AppStyles.caption,
                  ),
                  value: settings.embedThumbnail,
                  onChanged: (val) => settingsCtrl.updateSettings(
                    settings.copyWith(
                      embedThumbnail: val,
                      embedMetadata: val,
                      embedChapters: val,
                    ),
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'SponsorBlock Auto-Cut',
                    style: AppStyles.monoLabel,
                  ),
                  subtitle: Text(
                    'Strip sponsor segments & intros automatically',
                    style: AppStyles.caption,
                  ),
                  value: settings.enableSponsorBlock,
                  onChanged: (val) => settingsCtrl.updateSettings(
                    settings.copyWith(enableSponsorBlock: val),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Interactive yt-dlp CLI Suite',
                    style: AppStyles.monoLabel,
                  ),
                  subtitle: Text(
                    'Configure proxy, rate limit, subtitles & raw flags',
                    style: AppStyles.caption,
                  ),
                  trailing: const Icon(
                    Icons.north_east_rounded,
                    size: 17,
                    color: AppColors.textPrimary,
                  ),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AdvancedYtDlpSheet(
                        initialOptions: settings.toYtDlpOptions(),
                        targetUrl: 'https://example.com/video',
                        formatId: 'bestvideo+bestaudio/best',
                        onOptionsChanged: settingsCtrl.updateFromYtDlpOptions,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),

            Center(
              child: Text(
                'RAMEN // STUDIO v2.0',
                style: AppStyles.monoSmall.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 2.0,
                  fontSize: 10.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: AppStyles.caption.copyWith(letterSpacing: 1.4));
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

  Widget _buildEngineBentoCard(
    BuildContext context,
    SettingsController controller,
    Map<String, String> versions,
  ) {
    final items = [
      ('YT-DLP CORE', versions['ytdlp'] ?? 'CHECKING...'),
      ('FFMPEG MUX', versions['ffmpeg'] ?? 'CHECKING...'),
      ('ARIA2C ENGINE', versions['aria2c'] ?? 'CHECKING...'),
      ('NODE RUNTIME', versions['node'] ?? 'CHECKING...'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOOLCHAIN TELEMETRY',
                style: AppStyles.monoHeadline.copyWith(
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: AppColors.surfaceElevated,
                      value: controller.settings.ytDlpUpdateChannel,
                      isDense: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'nightly',
                          child: Text('NIGHTLY'),
                        ),
                        DropdownMenuItem(
                          value: 'stable',
                          child: Text('STABLE'),
                        ),
                      ],
                      style: AppStyles.monoSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                      onChanged: (val) {
                        if (val != null) {
                          controller.setYtDlpUpdateChannel(val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (controller.isUpdating)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: AppColors.accent,
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: controller.updateEngine,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'UPDATE',
                        style: AppStyles.monoSmall.copyWith(
                          color: AppColors.onAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.5,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.$1,
                      style: AppStyles.caption.copyWith(fontSize: 9.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.monoLabel.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              );
            },
          ),
          if (controller.updateMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              controller.updateMessage!,
              style: AppStyles.monoSmall.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditDirectoryDialog(
    BuildContext context,
    SettingsController controller,
  ) {
    final textController = TextEditingController(
      text: controller.settings.downloadDirectory,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        title: Text('OUTPUT DIRECTORY', style: AppStyles.monoHeadline),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: textController,
              style: AppStyles.monoSmall.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background,
                hintText: 'Download/Ramen',
                hintStyle: AppStyles.monoSmall.copyWith(
                  color: AppColors.textMuted,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => textController.text = 'Download/Ramen',
              child: Text('RESET DEFAULT', style: AppStyles.monoAccent),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCEL', style: AppStyles.monoSmall),
          ),
          ElevatedButton(
            onPressed: () {
              final newDir = textController.text.trim();
              controller.setDownloadDirectory(
                newDir.isEmpty ? 'Download/Ramen' : newDir,
              );
              Navigator.of(ctx).pop();
            },
            child: Text(
              'SAVE',
              style: AppStyles.monoSmall.copyWith(
                color: AppColors.onAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditCookiesDialog(
    BuildContext context,
    SettingsController controller,
  ) async {
    final existing = await controller.getCustomCookies();
    if (!context.mounted) return;
    final textController = TextEditingController(text: existing);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        title: Text('NETSCAPE COOKIES.TXT', style: AppStyles.monoHeadline),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste Netscape cookies.txt lines for authenticated Instagram, YouTube, or X access:',
              style: AppStyles.caption,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              maxLines: 6,
              style: AppStyles.monoSmall.copyWith(
                color: AppColors.textPrimary,
                fontSize: 11,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background,
                hintText:
                    '# Netscape HTTP Cookie File\n.instagram.com\tTRUE\t/\tTRUE\t0\tsessionid\t...',
                hintStyle: AppStyles.monoSmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10.5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (existing.isNotEmpty)
            TextButton(
              onPressed: () async {
                await controller.saveCustomCookies('');
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Text(
                'CLEAR',
                style: AppStyles.monoSmall.copyWith(color: AppColors.error),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCEL', style: AppStyles.monoSmall),
          ),
          ElevatedButton(
            onPressed: () async {
              await controller.saveCustomCookies(textController.text.trim());
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(
              'SAVE',
              style: AppStyles.monoSmall.copyWith(
                color: AppColors.onAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
