import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/formatters.dart';
import '../../controllers/download_controller.dart';
import '../../controllers/search_format_controller.dart';
import '../../models/media_resource.dart';

class PreviewView extends StatefulWidget {
  final VoidCallback? onDownloadCompletedNavigation;

  const PreviewView({super.key, this.onDownloadCompletedNavigation});

  @override
  State<PreviewView> createState() => _PreviewViewState();
}

class _PreviewViewState extends State<PreviewView> {
  String _selectedFilter = 'All';
  final ScrollController _formatsScrollController = ScrollController();

  @override
  void dispose() {
    _formatsScrollController.dispose();
    super.dispose();
  }

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
          child: Text(
            'No media preview available',
            style: AppStyles.bodyMedium,
          ),
        ),
      );
    }

    final isAudio = searchCtrl.isAudioOnly;
    final allFormats = resource.formats;
    final List<FormatItem> availableFormats;
    if (isAudio) {
      availableFormats = allFormats.where((f) => f.isAudioOnly).toList()
        ..sort((a, b) => (b.tbr ?? 0).compareTo(a.tbr ?? 0));
    } else {
      final videoList = allFormats.where((f) => !f.isAudioOnly).toList()
        ..sort((a, b) => (b.height ?? 0).compareTo(a.height ?? 0));
      final audioList = allFormats.where((f) => f.isAudioOnly).toList()
        ..sort((a, b) => (b.tbr ?? 0).compareTo(a.tbr ?? 0));
      availableFormats = [...videoList, ...audioList];
    }

    final filteredFormats = _applyFilter(
      availableFormats,
      _selectedFilter,
      isAudio,
    );

    final videoFormats = filteredFormats.where((f) => !f.isAudioOnly).toList();
    final audioFormats = filteredFormats.where((f) => f.isAudioOnly).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          resource.url.length > 30
              ? '${resource.url.substring(0, 30)}...'
              : resource.url,
          style: AppStyles.monoHeadline.copyWith(
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.copy_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final thumbHeight = constraints.maxHeight > 750
              ? 160.0
              : (constraints.maxHeight > 620 ? 125.0 : 90.0);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Thumbnail Card with Badges
                  _buildThumbnail(resource, height: thumbHeight),
                  const SizedBox(height: 10),

                  // 2. Title & Metadata
                  Text(
                    resource.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.titleMedium.copyWith(
                      fontSize: 15,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.account_circle_outlined,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          resource.uploader ?? 'Unknown Channel',
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (resource.viewCount != null) ...[
                        Text(
                          '${Formatters.formatCompactNumber(resource.viewCount)} views',
                          style: AppStyles.monoSmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3. Audio vs Video Stream Mode Switcher
                  _buildStreamTypeToggle(searchCtrl, isAudio),
                  const SizedBox(height: 10),

                  // 4. Filter Chips (4K, 1080p, 720p, etc.)
                  // if (!isAudio) ...[
                  //   _buildFilterChips(),
                  //   const SizedBox(height: 8),
                  // ],

                  // 5. Available Formats List Header
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
                  const SizedBox(height: 6),

                  // Formats List - ONLY SCROLLABLE REGION
                  Expanded(
                    child: filteredFormats.isEmpty
                        ? Container(
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
                        : Scrollbar(
                            controller: _formatsScrollController,
                            thumbVisibility: true,
                            child: ListView(
                              controller: _formatsScrollController,
                              padding: const EdgeInsets.only(bottom: 8),
                              children: [
                                // 1. Video Formats Section
                                if (videoFormats.isNotEmpty) ...[
                                  _buildCategoryHeader(
                                    title: 'VIDEO FORMATS',
                                    count: videoFormats.length,
                                    icon: Icons.videocam_rounded,
                                    color: AppColors.accentBright,
                                    subtitle: isAudio
                                        ? 'Video stream'
                                        : 'Choose video stream resolution and container',
                                  ),
                                  const SizedBox(height: 8),
                                  ...videoFormats.map(
                                    (format) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: _buildFormatCard(
                                        format,
                                        searchCtrl,
                                      ),
                                    ),
                                  ),
                                ],

                                // Category separation spacing
                                if (videoFormats.isNotEmpty &&
                                    audioFormats.isNotEmpty)
                                  const SizedBox(height: 12),

                                // 2. Audio Formats Section
                                if (audioFormats.isNotEmpty) ...[
                                  _buildCategoryHeader(
                                    title: 'AUDIO FORMATS',
                                    count: audioFormats.length,
                                    icon: Icons.audiotrack_rounded,
                                    color: Colors.amberAccent,
                                    subtitle: isAudio
                                        ? 'Choose audio quality for extraction'
                                        : 'Choose audio stream for muxing with video',
                                  ),
                                  const SizedBox(height: 8),
                                  ...audioFormats.map(
                                    (format) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: _buildFormatCard(
                                        format,
                                        searchCtrl,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),

                  // 6. Selected Format Summary Card
                  // if (searchCtrl.selectedFormat != null ||
                  //     searchCtrl.selectedVideoFormat != null ||
                  //     searchCtrl.selectedAudioFormat != null) ...[
                  //   _buildSelectedFormatSummary(searchCtrl, isAudio),
                  //   const SizedBox(height: 8),
                  // ],

                  // Primary Download CTA Button
                  _buildDownloadButton(context, searchCtrl),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildThumbnail(MediaResource resource, {double height = 160}) {
    return Container(
      width: double.infinity,
      height: height,
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
                  child: Icon(
                    Icons.movie_outlined,
                    size: 40,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          else
            const Center(
              child: Icon(
                Icons.movie_outlined,
                size: 40,
                color: AppColors.textMuted,
              ),
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

  Widget _buildStreamTypeToggle(
    SearchFormatController searchCtrl,
    bool isAudio,
  ) {
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
              onTap: () {
                if (isAudio) {
                  setState(() => _selectedFilter = 'All');
                  searchCtrl.setAudioOnly(false);
                }
              },
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
                        color: !isAudio
                            ? Colors.white
                            : AppColors.textSecondary,
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
              onTap: () {
                if (!isAudio) {
                  setState(() => _selectedFilter = 'All');
                  searchCtrl.setAudioOnly(true);
                }
              },
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
    final filters = [
      'All',
      'Video Only',
      'Audio Only',
      '4K / 2K',
      '1080p',
      '720p',
      'SD',
    ];
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
                color: isSelected
                    ? AppColors.accentBright
                    : AppColors.textSecondary,
                fontSize: 11,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.accent : AppColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryHeader({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppStyles.monoHeadline.copyWith(
                        fontSize: 12,
                        letterSpacing: 0.8,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.chipBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: AppStyles.monoSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: AppStyles.caption.copyWith(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatCard(
    FormatItem format,
    SearchFormatController searchCtrl,
  ) {
    final isAudioTrack = format.isAudioOnly;
    final isSelected = isAudioTrack
        ? (searchCtrl.includeAudio &&
              searchCtrl.selectedAudioFormat?.formatId == format.formatId)
        : (searchCtrl.includeVideo &&
              searchCtrl.selectedVideoFormat?.formatId == format.formatId);

    final isTrackActive = isAudioTrack
        ? searchCtrl.selectedAudioFormat?.formatId == format.formatId
        : searchCtrl.selectedVideoFormat?.formatId == format.formatId;

    return InkWell(
      onTap: () => searchCtrl.selectFormat(format),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentMuted.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.accentBright
                : (isTrackActive ? AppColors.accentMuted : AppColors.border),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Track / Quality Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent
                    : (isAudioTrack
                          ? AppColors.surfaceElevated
                          : AppColors.chipBackground),
                borderRadius: BorderRadius.circular(6),
                border: isAudioTrack && !isSelected
                    ? Border.all(color: AppColors.borderLight)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAudioTrack
                        ? Icons.audiotrack_rounded
                        : Icons.videocam_rounded,
                    size: 13,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    format.displayQuality,
                    style: AppStyles.monoSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 11,
                    ),
                  ),
                ],
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.chipBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          format.ext.toUpperCase(),
                          style: AppStyles.monoSmall.copyWith(fontSize: 10),
                        ),
                      ),
                      if (format.fps != null && format.fps! > 30) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${format.fps}fps',
                          style: AppStyles.monoAccent.copyWith(fontSize: 11),
                        ),
                      ],
                      if (format.vcodec != null && format.vcodec != 'none') ...[
                        const SizedBox(width: 6),
                        Text(
                          '• ${format.vcodec!.split('.').first}',
                          style: AppStyles.caption,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isAudioTrack
                        ? (format.acodec != null && format.acodec != 'none'
                              ? 'Audio Track • ${format.acodec!.split('.').first}'
                              : 'Audio Track')
                        : (format.acodec != null && format.acodec != 'none'
                              ? 'Video + Audio stream'
                              : 'Video Stream (lossless muxing)'),
                    style: AppStyles.caption.copyWith(
                      color: isSelected
                          ? AppColors.accentBright
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Filesize
            if (format.filesize != null)
              Text(
                Formatters.formatBytes(format.filesize!),
                style: AppStyles.monoSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(width: 10),

            // Selection Checkmark / Radio
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : (isTrackActive
                        ? Icons.remove_circle_outline_rounded
                        : Icons.radio_button_unchecked_rounded),
              color: isSelected
                  ? AppColors.accentBright
                  : (isTrackActive
                        ? AppColors.accentMuted
                        : AppColors.textMuted),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFormatSummary(
    SearchFormatController searchCtrl,
    bool isAudioOnlyTab,
  ) {
    if (isAudioOnlyTab) {
      final format = searchCtrl.selectedFormat;
      if (format == null) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
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
                const Icon(
                  Icons.audiotrack_rounded,
                  size: 16,
                  color: AppColors.accentBright,
                ),
                const SizedBox(width: 8),
                Text(
                  'SELECTED AUDIO TARGET',
                  style: AppStyles.monoSmall.copyWith(
                    color: AppColors.accentBright,
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: ${format.formatId}',
                  style: AppStyles.monoSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${format.displayQuality} • ${format.ext.toUpperCase()}',
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (format.filesize != null)
                  Text(
                    '~${Formatters.formatBytes(format.filesize!)}',
                    style: AppStyles.monoLabel,
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'FFmpeg will extract and encode clean audio stream',
              style: AppStyles.caption,
            ),
          ],
        ),
      );
    }

    final hasBoth = searchCtrl.includeVideo && searchCtrl.includeAudio;
    final isVideoOnly = searchCtrl.includeVideo && !searchCtrl.includeAudio;
    final isAudioOnly = !searchCtrl.includeVideo && searchCtrl.includeAudio;

    final targetModeLabel = hasBoth
        ? 'VIDEO + AUDIO'
        : (isVideoOnly ? 'VIDEO ONLY' : 'AUDIO ONLY');

    final chosen = searchCtrl.selectedFormat;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Mode Badge & Format ID
          Row(
            children: [
              const Icon(
                Icons.done_all_rounded,
                size: 15,
                color: AppColors.accentBright,
              ),
              const SizedBox(width: 6),
              Text(
                'STREAM TARGET',
                style: AppStyles.monoSmall.copyWith(
                  color: AppColors.accentBright,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.accent),
                ),
                child: Text(
                  targetModeLabel,
                  style: AppStyles.monoSmall.copyWith(
                    color: AppColors.accentBright,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
              if (chosen != null) ...[
                const SizedBox(width: 6),
                Text(
                  'ID: ${chosen.formatId}',
                  style: AppStyles.monoSmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // 3-Way Quick Selector: [Both (Video + Audio)] [Video Only] [Audio Only]
          Row(
            children: [
              _buildStreamModePill(
                label: 'Both (Video + Audio)',
                isSelected: hasBoth,
                onTap: () => searchCtrl.setStreamSelectionMode(
                  includeVideo: true,
                  includeAudio: true,
                ),
              ),
              const SizedBox(width: 6),
              _buildStreamModePill(
                label: 'Video Only',
                isSelected: isVideoOnly,
                onTap: () => searchCtrl.setStreamSelectionMode(
                  includeVideo: true,
                  includeAudio: false,
                ),
              ),
              const SizedBox(width: 6),
              _buildStreamModePill(
                label: 'Audio Only',
                isSelected: isAudioOnly,
                onTap: () => searchCtrl.setStreamSelectionMode(
                  includeVideo: false,
                  includeAudio: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Interactive Stream Checkboxes
          InkWell(
            onTap: () =>
                searchCtrl.toggleIncludeVideo(!searchCtrl.includeVideo),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: searchCtrl.includeVideo,
                      onChanged: (val) =>
                          searchCtrl.toggleIncludeVideo(val ?? false),
                      activeColor: AppColors.accent,
                      checkColor: Colors.white,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.videocam_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      searchCtrl.includeVideo
                          ? (searchCtrl.selectedVideoFormat != null
                                ? 'Video: ${searchCtrl.selectedVideoFormat!.displayQuality} • ${searchCtrl.selectedVideoFormat!.ext.toUpperCase()}'
                                : 'Video: Default Video Stream')
                          : 'Video: Disabled (Audio Only)',
                      style: AppStyles.caption.copyWith(
                        color: searchCtrl.includeVideo
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontWeight: searchCtrl.includeVideo
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (searchCtrl.includeVideo &&
                      searchCtrl.selectedVideoFormat?.filesize != null)
                    Text(
                      Formatters.formatBytes(
                        searchCtrl.selectedVideoFormat!.filesize!,
                      ),
                      style: AppStyles.monoSmall.copyWith(fontSize: 10),
                    ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () =>
                searchCtrl.toggleIncludeAudio(!searchCtrl.includeAudio),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: searchCtrl.includeAudio,
                      onChanged: (val) =>
                          searchCtrl.toggleIncludeAudio(val ?? false),
                      activeColor: AppColors.accent,
                      checkColor: Colors.white,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.audiotrack_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      searchCtrl.includeAudio
                          ? (searchCtrl.selectedAudioFormat != null
                                ? 'Audio: ${searchCtrl.selectedAudioFormat!.displayQuality} • ${searchCtrl.selectedAudioFormat!.ext.toUpperCase()}'
                                : 'Audio: Default Audio Stream')
                          : 'Audio: Disabled (Muted video)',
                      style: AppStyles.caption.copyWith(
                        color: searchCtrl.includeAudio
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontWeight: searchCtrl.includeAudio
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (searchCtrl.includeAudio &&
                      searchCtrl.selectedAudioFormat?.filesize != null)
                    Text(
                      Formatters.formatBytes(
                        searchCtrl.selectedAudioFormat!.filesize!,
                      ),
                      style: AppStyles.monoSmall.copyWith(fontSize: 10),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasBoth
                    ? 'Lossless muxing into MP4 via aria2c + FFmpeg'
                    : (isVideoOnly
                          ? 'Direct video download without audio track'
                          : 'FFmpeg will extract clean audio stream'),
                style: AppStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              if (chosen?.filesize != null)
                Text(
                  'Total: ~${Formatters.formatBytes(chosen!.filesize!)}',
                  style: AppStyles.monoAccent.copyWith(fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreamModePill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppColors.accentBright : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppStyles.monoSmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildDownloadButton(
    BuildContext context,
    SearchFormatController searchCtrl,
  ) {
    final downloadCtrl = context.read<DownloadController>();

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
            downloadCtrl.associateTaskWithTab(tab.id, task.id);
            final tabIndex = downloadCtrl.tabs.indexWhere(
              (t) => t.id == tab.id,
            );
            if (tabIndex != -1) {
              downloadCtrl.selectTab(tabIndex);
            }

            Navigator.of(
              context,
            ).pop(); // Exit preview page back to main navigation
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
    if (filter == 'Video Only') {
      return formats.where((f) => !f.isAudioOnly).toList();
    }
    if (filter == 'Audio Only') {
      return formats.where((f) => f.isAudioOnly).toList();
    }
    if (filter == '4K / 2K') {
      return formats
          .where((f) => !f.isAudioOnly && (f.height ?? 0) >= 1440)
          .toList();
    }
    if (filter == '1080p') {
      return formats
          .where((f) => !f.isAudioOnly && (f.height ?? 0) == 1080)
          .toList();
    }
    if (filter == '720p') {
      return formats
          .where((f) => !f.isAudioOnly && (f.height ?? 0) == 720)
          .toList();
    }
    if (filter == 'SD') {
      return formats
          .where((f) => !f.isAudioOnly && (f.height ?? 0) < 720)
          .toList();
    }
    return formats;
  }
}
