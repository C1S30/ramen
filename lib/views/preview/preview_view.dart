import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/formatters.dart';
import '../../controllers/download_controller.dart';
import '../../controllers/search_format_controller.dart';
import '../../models/media_resource.dart';
import 'widgets/advanced_ytdlp_sheet.dart';

class PreviewView extends StatefulWidget {
  final VoidCallback? onDownloadCompletedNavigation;

  const PreviewView({
    super.key,
    this.onDownloadCompletedNavigation,
  });

  @override
  State<PreviewView> createState() => _PreviewViewState();
}

class _PreviewViewState extends State<PreviewView> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final searchCtrl = context.watch<SearchFormatController>();
    final resource = searchCtrl.currentResource;

    if (resource == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Text('No media preview available', style: AppStyles.bodyMedium),
        ),
      );
    }

    final isAudio = searchCtrl.isAudioOnly;
    final allFormats = resource.formats;
    final availableFormats = isAudio
        ? allFormats.where((f) => f.isAudioOnly).toList()
        : allFormats.where((f) => !f.isAudioOnly || f.isMerged).toList();

    final filteredFormats = _applyFilter(availableFormats, _selectedFilter, isAudio);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'MEDIA PREVIEW',
          style: AppStyles.monoHeadline.copyWith(fontSize: 14, letterSpacing: 1),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textSecondary),
            tooltip: 'Copy URL',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: resource.url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Media URL copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Thumbnail Card with Badges
            _buildThumbnail(resource),
            const SizedBox(height: 16),

            // 2. Title & Metadata
            Text(
              resource.title,
              style: AppStyles.titleMedium.copyWith(fontSize: 17, height: 1.3),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.account_circle_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    resource.uploader ?? 'Unknown Channel',
                    style: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (resource.viewCount != null) ...[
                  Text(
                    '${Formatters.formatCompactNumber(resource.viewCount)} views',
                    style: AppStyles.monoSmall,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // 3. Audio vs Video Stream Mode Switcher
            _buildStreamTypeToggle(searchCtrl, isAudio),
            const SizedBox(height: 18),

            // 4. Filter Chips (4K, 1080p, 720p, etc.)
            if (!isAudio) ...[
              _buildFilterChips(),
              const SizedBox(height: 12),
            ],

            // 5. Available Formats List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AVAILABLE FORMATS (${filteredFormats.length})',
                  style: AppStyles.caption.copyWith(letterSpacing: 0.8),
                ),
                if (searchCtrl.selectedFormat != null)
                  Text(
                    'ID: ${searchCtrl.selectedFormat!.formatId}',
                    style: AppStyles.monoAccent.copyWith(fontSize: 11),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (filteredFormats.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    'No formats found matching filter',
                    style: AppStyles.bodyMedium,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredFormats.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final format = filteredFormats[index];
                  final isSelected = searchCtrl.selectedFormat?.formatId == format.formatId;
                  return _buildFormatCard(format, isSelected, searchCtrl);
                },
              ),
            const SizedBox(height: 20),

            // 6. Selected Format Summary Card
            if (searchCtrl.selectedFormat != null)
              _buildSelectedFormatSummary(searchCtrl.selectedFormat!, isAudio),
            const SizedBox(height: 16),

            // 7. Advanced yt-dlp Options Bar (Hidden for simple users)
            _buildAdvancedYtDlpTrigger(context, searchCtrl, resource),
            const SizedBox(height: 24),

            // 8. Primary Download CTA Button
            _buildDownloadButton(context, searchCtrl),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(MediaResource resource) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (resource.thumbnail != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.network(
                resource.thumbnail!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.movie_outlined, size: 40, color: AppColors.textMuted),
                ),
              ),
            )
          else
            const Center(
              child: Icon(Icons.movie_outlined, size: 40, color: AppColors.textMuted),
            ),

          // Duration Badge (Bottom-Right)
          if (resource.durationSeconds != null)
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  Formatters.formatDuration(resource.durationSeconds),
                  style: AppStyles.monoSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ),

          // Quality / Source Tag (Top-Left)
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'STREAM READY',
                style: AppStyles.monoSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamTypeToggle(SearchFormatController searchCtrl, bool isAudio) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => searchCtrl.setAudioOnly(false),
              child: Container(
                decoration: BoxDecoration(
                  color: !isAudio ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_collection_outlined,
                      size: 16,
                      color: !isAudio ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'VIDEO + AUDIO',
                      style: AppStyles.monoSmall.copyWith(
                        color: !isAudio ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => searchCtrl.setAudioOnly(true),
              child: Container(
                decoration: BoxDecoration(
                  color: isAudio ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.audiotrack_rounded,
                      size: 16,
                      color: isAudio ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AUDIO ONLY',
                      style: AppStyles.monoSmall.copyWith(
                        color: isAudio ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', '4K / 2K', '1080p', '720p', 'SD'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedFilter = filter);
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.accentMuted,
              labelStyle: AppStyles.monoSmall.copyWith(
                color: isSelected ? AppColors.accentBright : AppColors.textSecondary,
                fontSize: 11,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.accent : AppColors.border,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFormatCard(
    FormatItem format,
    bool isSelected,
    SearchFormatController searchCtrl,
  ) {
    return InkWell(
      onTap: () => searchCtrl.selectFormat(format),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentMuted.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accentBright : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Resolution / Quality Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.chipBackground,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                format.displayQuality,
                style: AppStyles.monoSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Format Details (Container, Codecs, FPS)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        format.ext.toUpperCase(),
                        style: AppStyles.monoLabel.copyWith(fontSize: 12),
                      ),
                      if (format.fps != null && format.fps! > 30) ...[
                        const SizedBox(width: 6),
                        Text('${format.fps}fps', style: AppStyles.monoAccent.copyWith(fontSize: 11)),
                      ],
                      if (format.vcodec != null && format.vcodec != 'none') ...[
                        const SizedBox(width: 6),
                        Text(
                          '•  ${format.vcodec!.split('.').first}',
                          style: AppStyles.caption,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    format.acodec != null && format.acodec != 'none'
                        ? 'Audio: ${format.acodec!.split('.').first}'
                        : 'Video Stream',
                    style: AppStyles.caption,
                  ),
                ],
              ),
            ),

            // Filesize
            if (format.filesize != null)
              Text(
                Formatters.formatBytes(format.filesize!),
                style: AppStyles.monoSmall.copyWith(color: AppColors.textSecondary),
              ),
            const SizedBox(width: 8),

            // Selection Checkmark
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.accentBright : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFormatSummary(FormatItem format, bool isAudio) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.done_all_rounded, size: 16, color: AppColors.accentBright),
              const SizedBox(width: 8),
              Text('SELECTED STREAM TARGET', style: AppStyles.monoSmall.copyWith(color: AppColors.accentBright)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${format.displayQuality} • ${format.ext.toUpperCase()}',
                style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              if (format.filesize != null)
                Text(
                  '~${Formatters.formatBytes(format.filesize!)}',
                  style: AppStyles.monoLabel,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isAudio
                ? 'FFmpeg will extract and encode clean audio stream'
                : 'lossless muxing via aria2c + FFmpeg pipeline',
            style: AppStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedYtDlpTrigger(
    BuildContext context,
    SearchFormatController searchCtrl,
    MediaResource resource,
  ) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AdvancedYtDlpSheet(
            initialOptions: searchCtrl.options,
            targetUrl: resource.url,
            formatId: searchCtrl.selectedFormat?.formatId ?? 'best',
            onOptionsChanged: (newOpts) => searchCtrl.updateOptions(newOpts),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.chipBackground,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.tune_rounded, size: 16, color: AppColors.accentBright),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Advanced yt-dlp Options (Pro)', style: AppStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                  Text('Aria2c threads, proxy, subtitles, cookies & custom flags', style: AppStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton(BuildContext context, SearchFormatController searchCtrl) {
    final downloadCtrl = context.read<DownloadController>();

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          shadowColor: AppColors.accentGlow,
        ),
        onPressed: () async {
          // Create tab for simultaneous stream if needed
          final tab = downloadCtrl.createTab(
            title: searchCtrl.currentResource?.title,
          );

          final task = await searchCtrl.startDownload(targetTabId: tab.id);

          if (task != null && context.mounted) {
            // Assign task to tab
            final tabIndex = downloadCtrl.tabs.indexWhere((t) => t.id == tab.id);
            if (tabIndex != -1) {
              downloadCtrl.selectTab(tabIndex);
            }

            Navigator.of(context).pop(); // Exit preview page back to main navigation
            widget.onDownloadCompletedNavigation?.call();
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download_rounded, size: 20),
            const SizedBox(width: 10),
            Text(
              'START DOWNLOAD',
              style: AppStyles.monoHeadline.copyWith(
                color: Colors.white,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FormatItem> _applyFilter(
    List<FormatItem> formats,
    String filter,
    bool isAudio,
  ) {
    if (isAudio || filter == 'All') return formats;
    if (filter == '4K / 2K') {
      return formats.where((f) => (f.height ?? 0) >= 1440).toList();
    }
    if (filter == '1080p') {
      return formats.where((f) => (f.height ?? 0) == 1080).toList();
    }
    if (filter == '720p') {
      return formats.where((f) => (f.height ?? 0) == 720).toList();
    }
    if (filter == 'SD') {
      return formats.where((f) => (f.height ?? 0) < 720).toList();
    }
    return formats;
  }
}
