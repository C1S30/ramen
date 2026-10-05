import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../controllers/download_controller.dart';
import '../../controllers/search_format_controller.dart';
import '../../controllers/template_controller.dart';
import 'widgets/format_selector_sheet.dart';
import 'widgets/playlist_format_view.dart';
import 'widgets/quick_template_bar.dart';
import 'widgets/url_search_box.dart';

class HomeView extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const HomeView({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final searchCtrl = context.watch<SearchFormatController>();
    final templateCtrl = context.watch<TemplateController>();
    final downloadCtrl = context.watch<DownloadController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                SimpleIcons.youtube,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'RAMEN',
              style: AppStyles.titleLarge.copyWith(letterSpacing: 1.5),
            ),
          ],
        ),
        actions: [
          // Active Tasks Quick Counter
          if (downloadCtrl.activeCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: InkWell(
                onTap: () => onNavigateTab?.call(1),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentMuted,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_downward_rounded,
                          size: 14, color: AppColors.accentBright),
                      const SizedBox(width: 4),
                      Text(
                        '${downloadCtrl.activeCount} active',
                        style: AppStyles.monoAccent.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Box
            UrlSearchBox(controller: searchCtrl),
            const SizedBox(height: 16),

            // Command Templates Quick Switch Bar
            QuickTemplateBar(
              controller: searchCtrl,
              templates: templateCtrl.templates,
            ),
            const SizedBox(height: 16),

            // Inspect Formats Trigger Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceElevated,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  elevation: 0,
                ),
                onPressed: searchCtrl.isLoading
                    ? null
                    : () => searchCtrl.inspectUrl(),
                child: searchCtrl.isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('INSPECTING FORMATS...', style: AppStyles.monoLabel),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'FIND FORMATS (yt-dlp -F)',
                            style: AppStyles.monoLabel.copyWith(
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Error Banner if format inspection fails
            if (searchCtrl.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        searchCtrl.errorMessage!,
                        style: AppStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),

            // Dynamic Formats View (Video vs Playlist)
            if (searchCtrl.currentResource != null) ...[
              if (searchCtrl.currentResource!.isPlaylist)
                PlaylistFormatView(
                  controller: searchCtrl,
                  onDownloadStarted: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surfaceElevated,
                        content: Text(
                          'Enqueued playlist items for download.',
                          style: AppStyles.bodyMedium,
                        ),
                        action: SnackBarAction(
                          label: 'VIEW',
                          textColor: AppColors.accentBright,
                          onPressed: () => onNavigateTab?.call(1),
                        ),
                      ),
                    );
                    onNavigateTab?.call(1);
                  },
                )
              else
                FormatSelectorSheet(
                  controller: searchCtrl,
                  onDownloadStarted: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surfaceElevated,
                        content: Text(
                          'Download started.',
                          style: AppStyles.bodyMedium,
                        ),
                        action: SnackBarAction(
                          label: 'VIEW',
                          textColor: AppColors.accentBright,
                          onPressed: () => onNavigateTab?.call(1),
                        ),
                      ),
                    );
                    onNavigateTab?.call(1);
                  },
                ),
            ] else ...[
              // Default Welcome / Architecture Showcase card
              _buildFeatureOverviewCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal_rounded,
                  color: AppColors.accentBright, size: 18),
              const SizedBox(width: 8),
              Text('RAMEN CORE ARCHITECTURE', style: AppStyles.caption),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'High-Performance Native Pipeline',
            style: AppStyles.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Paste any YouTube video or playlist link to inspect available streams. Ramen executes native yt-dlp via JNI, leverages aria2c for 16-connection socket acceleration, and uses embedded FFmpeg for lossless container multiplexing.',
            style: AppStyles.bodyMedium.copyWith(height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildBadge('yt-dlp NDK'),
              const SizedBox(width: 8),
              _buildBadge('aria2c Multi-socket'),
              const SizedBox(width: 8),
              _buildBadge('FFmpeg Muxer'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.chipBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: AppStyles.monoSmall.copyWith(fontSize: 10)),
    );
  }
}
