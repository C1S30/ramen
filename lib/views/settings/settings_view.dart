import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../controllers/settings_controller.dart';

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
}
