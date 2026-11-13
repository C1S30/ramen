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

  const PreviewView({super.key, this.onDownloadCompletedNavigation});

  @override
  State<PreviewView> createState() => _PreviewViewState();
}

class _PreviewViewState extends State<PreviewView> {
  void _openAdvancedSheet(
    BuildContext context,
    SearchFormatController searchCtrl,
    MediaResource resource,
  ) {
    final formatId = resource.isPlaylist
        ? searchCtrl.playlistFormatSelector
        : (searchCtrl.selectedFormat?.formatId ?? 'best');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdvancedYtDlpSheet(
        initialOptions: searchCtrl.options,
        targetUrl: resource.url,
        formatId: formatId,
        onOptionsChanged: searchCtrl.updateOptions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchCtrl = context.watch<SearchFormatController>();
    final resource = searchCtrl.currentResource;

    if (searchCtrl.isLoading) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.accentBright,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Inspecting stream metadata...',
                style: AppStyles.monoSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
            searchCtrl.errorMessage ?? 'No media preview available',
            style: AppStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

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
          tooltip: searchCtrl.canReturnToPlaylist ? 'Back to Playlist' : 'Back',
          onPressed: () {
            if (searchCtrl.canReturnToPlaylist) {
              searchCtrl.returnToPlaylist();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          resource.url.length > 28
              ? '${resource.url.substring(0, 28)}...'
              : resource.url,
          style: AppStyles.monoHeadline.copyWith(
            fontSize: 13,
            letterSpacing: 0.8,
          ),
        ),
        centerTitle: true,
        actions: [
          if (searchCtrl.canReturnToPlaylist)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton.icon(
                onPressed: searchCtrl.returnToPlaylist,
                icon: const Icon(
                  Icons.playlist_play_rounded,
                  size: 16,
                  color: AppColors.accentBright,
                ),
                label: Text(
                  'Playlist',
                  style: AppStyles.monoAccent.copyWith(fontSize: 11),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(
              Icons.tune_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Advanced yt-dlp Options',
            onPressed: () => _openAdvancedSheet(context, searchCtrl, resource),
          ),
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
          if (resource.isPlaylist) {
            return _buildPlaylistView(context, searchCtrl, resource);
          }
          return _buildSingleMediaView(
            context,
            constraints,
            searchCtrl,
            resource,
          );
        },
      ),
    );
  }

  Widget _buildSingleMediaView(
    BuildContext context,
    BoxConstraints constraints,
    SearchFormatController searchCtrl,
    MediaResource resource,
  ) {
    final isAudio = searchCtrl.isAudioOnly;
    final allFormats = resource.formats;
    final isLiveEdge = resource.isLive && !searchCtrl.options.liveFromStart;
    final hasHlsFormats = allFormats.any(
      (f) => f.isHls || (!f.isAudioOnly && f.isMerged),
    );

    final seenVideoIds = <String>{};
    final videoFormats =
        allFormats
            .where(
              (f) =>
                  !f.isAudioOnly &&
                  !(isLiveEdge && hasHlsFormats && f.isDash) &&
                  seenVideoIds.add(f.formatId),
            )
            .toList()
          ..sort((a, b) {
            if (isLiveEdge) {
              final aHls = (a.isHls || a.isMerged) ? 1 : 0;
              final bHls = (b.isHls || b.isMerged) ? 1 : 0;
              if (aHls != bHls) return bHls.compareTo(aHls);
            }
            final hCmp = (b.height ?? 0).compareTo(a.height ?? 0);
            if (hCmp != 0) return hCmp;
            return (b.tbr ?? 0).compareTo(a.tbr ?? 0);
          });

    final seenAudioIds = <String>{};
    final audioFormats =
        allFormats
            .where(
              (f) =>
                  f.isAudioOnly &&
                  !(isLiveEdge && hasHlsFormats && f.isDash) &&
                  seenAudioIds.add(f.formatId),
            )
            .toList()
          ..sort(
            (a, b) => ((b.abr ?? b.tbr) ?? 0).compareTo((a.abr ?? a.tbr) ?? 0),
          );

    // For live streams (HLS m3u8), streams are often multiplexed without separate audio-only tracks.
    // In Audio-Only mode, allow selecting from multiplexed streams if no dedicated audio stream exists.
    final effectiveAudioFormats =
        (isAudio && audioFormats.isEmpty && videoFormats.isNotEmpty)
        ? videoFormats
        : audioFormats;

    final totalFormatsCount = isAudio
        ? effectiveAudioFormats.length
        : videoFormats.length + audioFormats.length;

    final thumbHeight = constraints.maxHeight > 750
        ? 160.0
        : (constraints.maxHeight > 620 ? 125.0 : 90.0);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Thumbnail Card with Live / Duration Badges
            _buildThumbnail(resource, height: thumbHeight),
            const SizedBox(height: 10),

            // 2. Title & Metadata
            Text(
              resource.title,
              // maxLines: 1,
              overflow: TextOverflow.clip,
              style: AppStyles.titleMedium.copyWith(fontSize: 15, height: 1.2),
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
                if (resource.concurrentViewCount != null &&
                    resource.isLive) ...[
                  Text(
                    '${Formatters.formatCompactNumber(resource.concurrentViewCount)} watching',
                    style: AppStyles.monoAccent.copyWith(fontSize: 11),
                  ),
                ] else if (resource.viewCount != null) ...[
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
            const SizedBox(height: 12),

            // 4. Available Formats Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AVAILABLE FORMATS ($totalFormatsCount)',
                  style: AppStyles.caption.copyWith(letterSpacing: 0.8),
                ),
                if (searchCtrl.selectedFormat != null)
                  Text(
                    'ID: ${searchCtrl.selectedFormat!.formatId}',
                    style: AppStyles.monoAccent.copyWith(fontSize: 11),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // 5. Video & Audio Format Dropdowns + Live Stream Controls
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (resource.isLiveOrUpcoming) ...[
                      _buildLiveStreamControlsCard(searchCtrl, resource),
                      const SizedBox(height: 12),
                    ],
                    if (!isAudio) ...[
                      _buildFormatDropdownSection(
                        title: 'VIDEO FORMAT',
                        subtitle: resource.isLive
                            ? 'Choose live HLS/DASH video stream resolution'
                            : 'Choose video quality & resolution',
                        icon: Icons.videocam_rounded,
                        accentColor: AppColors.accentBright,
                        formats: videoFormats,
                        selectedFormat: searchCtrl.selectedVideoFormat,
                        emptyLabel: resource.isUpcoming
                            ? 'Auto-negotiated when broadcast goes live (bestvideo)'
                            : 'No video formats available',
                        onChanged: (format) {
                          if (format != null) {
                            searchCtrl.selectVideoFormat(format);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    _buildFormatDropdownSection(
                      title: 'AUDIO FORMAT',
                      subtitle: isAudio
                          ? 'Choose audio quality for extraction'
                          : 'Choose audio stream quality',
                      icon: Icons.audiotrack_rounded,
                      accentColor: AppColors.textPrimary,
                      formats: effectiveAudioFormats,
                      selectedFormat: isAudio && audioFormats.isEmpty
                          ? searchCtrl.selectedVideoFormat
                          : searchCtrl.selectedAudioFormat,
                      emptyLabel: resource.isUpcoming
                          ? 'Auto-negotiated when broadcast goes live (bestaudio)'
                          : (videoFormats.any((f) => f.isMerged || f.isHls)
                                ? 'Included in multiplexed HLS/video stream'
                                : 'No audio formats available'),
                      onChanged: (format) {
                        if (format != null) {
                          if (isAudio && audioFormats.isEmpty) {
                            searchCtrl.selectVideoFormat(format);
                          } else {
                            searchCtrl.selectAudioFormat(format);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Primary Download CTA Button
            _buildDownloadButton(context, searchCtrl, resource),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistView(
    BuildContext context,
    SearchFormatController searchCtrl,
    MediaResource resource,
  ) {
    final isAudio = searchCtrl.isAudioOnly;
    final entries = resource.playlistEntries;
    final playableCount = entries.where((e) => e.isPlayableEntry).length;
    final selectedCount = searchCtrl.selectedPlaylistEntries.length;
    final allSelected = playableCount > 0 && selectedCount >= playableCount;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Playlist Summary Header Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 76,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: resource.thumbnail != null
                          ? Image.network(
                              resource.thumbnail!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.playlist_play_rounded,
                                size: 28,
                                color: AppColors.textMuted,
                              ),
                            )
                          : const Icon(
                              Icons.playlist_play_rounded,
                              size: 28,
                              color: AppColors.textMuted,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                resource.isSearchResult
                                    ? 'SEARCH RESULTS'
                                    : 'PLAYLIST',
                                style: AppStyles.monoSmall.copyWith(
                                  color: AppColors.onAccent,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${resource.playlistCount ?? entries.length} tracks',
                              style: AppStyles.monoSmall.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          resource.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.titleMedium.copyWith(fontSize: 14),
                        ),
                        if (resource.uploader != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            resource.uploader!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 2. Stream Mode Toggle
            _buildStreamTypeToggle(searchCtrl, isAudio),
            const SizedBox(height: 10),

            // 3. Playlist Video / Audio Format Preset Dropdowns
            _buildPlaylistFormatDropdowns(searchCtrl, resource, isAudio),
            const SizedBox(height: 10),

            // 4. Playlist Entries Header & Select All Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PLAYLIST ENTRIES ($selectedCount/${entries.length} SELECTED)',
                  style: AppStyles.caption.copyWith(letterSpacing: 0.8),
                ),
                GestureDetector(
                  onTap: () => searchCtrl.selectAllPlaylistItems(!allSelected),
                  child: Text(
                    allSelected ? 'Deselect All' : 'Select All',
                    style: AppStyles.monoAccent.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // 5. Scrollable Playlist Entries List
            Expanded(
              child: entries.isEmpty
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
                          'No playable entries found in this playlist',
                          style: AppStyles.bodyMedium,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final isSelected = searchCtrl.selectedPlaylistEntries
                            .contains(entry.id);
                        return _buildPlaylistEntryTile(
                          entry,
                          index + 1,
                          isSelected,
                          searchCtrl,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),

            // 6. Primary Batch Download Button
            _buildDownloadButton(context, searchCtrl, resource),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistFormatDropdowns(
    SearchFormatController searchCtrl,
    MediaResource resource,
    bool isAudio,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAudio ? 'AUDIO FORMAT' : 'VIDEO QUALITY',
                      style: AppStyles.caption.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: isAudio
                            ? DropdownButton<String>(
                                value: searchCtrl.options.audioFormat,
                                isExpanded: true,
                                isDense: true,
                                dropdownColor: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'mp3',
                                    child: Text('MP3 Audio'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'm4a',
                                    child: Text('M4A (AAC)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'opus',
                                    child: Text('Opus Audio'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'flac',
                                    child: Text('FLAC Lossless'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'wav',
                                    child: Text('WAV PCM'),
                                  ),
                                ],
                                style: AppStyles.monoSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                onChanged: (val) {
                                  if (val != null) {
                                    searchCtrl.setPlaylistAudioFormat(val);
                                  }
                                },
                              )
                            : DropdownButton<String>(
                                value: searchCtrl.playlistVideoQuality,
                                isExpanded: true,
                                isDense: true,
                                dropdownColor: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'best',
                                    child: Text('Best Available'),
                                  ),
                                  DropdownMenuItem(
                                    value: '2160',
                                    child: Text('2160p (4K UHD)'),
                                  ),
                                  DropdownMenuItem(
                                    value: '1440',
                                    child: Text('1440p (2K QHD)'),
                                  ),
                                  DropdownMenuItem(
                                    value: '1080',
                                    child: Text('1080p (Full HD)'),
                                  ),
                                  DropdownMenuItem(
                                    value: '720',
                                    child: Text('720p (HD)'),
                                  ),
                                  DropdownMenuItem(
                                    value: '480',
                                    child: Text('480p (SD)'),
                                  ),
                                  DropdownMenuItem(
                                    value: '360',
                                    child: Text('360p (Data Saver)'),
                                  ),
                                ],
                                style: AppStyles.monoSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                onChanged: (val) {
                                  if (val != null) {
                                    searchCtrl.setPlaylistVideoQuality(val);
                                  }
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAudio ? 'AUDIO BITRATE' : 'CONTAINER',
                      style: AppStyles.caption.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: isAudio
                            ? DropdownButton<String>(
                                value: searchCtrl.options.audioQuality,
                                isExpanded: true,
                                isDense: true,
                                dropdownColor: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                items: const [
                                  DropdownMenuItem(
                                    value: '0',
                                    child: Text('Best (VBR 0)'),
                                  ),
                                  DropdownMenuItem(
                                    value: '320k',
                                    child: Text('320 kbps'),
                                  ),
                                  DropdownMenuItem(
                                    value: '256k',
                                    child: Text('256 kbps'),
                                  ),
                                  DropdownMenuItem(
                                    value: '192k',
                                    child: Text('192 kbps'),
                                  ),
                                  DropdownMenuItem(
                                    value: '128k',
                                    child: Text('128 kbps'),
                                  ),
                                ],
                                style: AppStyles.monoSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                onChanged: (val) {
                                  if (val != null) {
                                    searchCtrl.setPlaylistAudioQuality(val);
                                  }
                                },
                              )
                            : DropdownButton<String>(
                                value: searchCtrl.playlistVideoContainer,
                                isExpanded: true,
                                isDense: true,
                                dropdownColor: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'mp4',
                                    child: Text('MP4 Container'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'mkv',
                                    child: Text('MKV Container'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'webm',
                                    child: Text('WebM Container'),
                                  ),
                                ],
                                style: AppStyles.monoSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                onChanged: (val) {
                                  if (val != null) {
                                    searchCtrl.setPlaylistVideoContainer(val);
                                  }
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!resource.isSearchResult) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => searchCtrl.setUseNativePlaylistProcess(
                !searchCtrl.useNativePlaylistProcess,
              ),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: searchCtrl.useNativePlaylistProcess,
                        activeColor: AppColors.accent,
                        checkColor: AppColors.onAccent,
                        onChanged: (val) => searchCtrl
                            .setUseNativePlaylistProcess(val ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Batch via single yt-dlp process (--yes-playlist --playlist-items)',
                        style: AppStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaylistEntryTile(
    MediaResource entry,
    int displayIndex,
    bool isSelected,
    SearchFormatController searchCtrl,
  ) {
    final isPlayable = entry.isPlayableEntry;
    final idx = entry.playlistIndex ?? displayIndex;

    return InkWell(
      onTap: isPlayable ? () => searchCtrl.togglePlaylistItem(entry.id) : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentMuted.withValues(alpha: 0.14)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accentBright : AppColors.border,
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: isSelected,
                activeColor: AppColors.accent,
                checkColor: AppColors.onAccent,
                onChanged: isPlayable
                    ? (_) => searchCtrl.togglePlaylistItem(entry.id)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 24,
              child: Text(
                '#$idx',
                style: AppStyles.monoSmall.copyWith(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  entry.thumbnail != null
                      ? Image.network(
                          entry.thumbnail!,
                          width: 60,
                          height: 38,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 38,
                            color: AppColors.surfaceElevated,
                            child: const Icon(
                              Icons.movie_outlined,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 38,
                          color: AppColors.surfaceElevated,
                          child: const Icon(
                            Icons.movie_outlined,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ),
                  if (entry.isLive)
                    Positioned(
                      right: 3,
                      bottom: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'LIVE',
                          style: AppStyles.monoSmall.copyWith(
                            color: AppColors.onAccent,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.bodyMedium.copyWith(
                      color: isPlayable
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (entry.durationSeconds != null) ...[
                        Text(
                          Formatters.formatDuration(entry.durationSeconds),
                          style: AppStyles.monoSmall.copyWith(fontSize: 10),
                        ),
                        const SizedBox(width: 6),
                      ] else if (entry.isUpcoming) ...[
                        Text(
                          'UPCOMING',
                          style: AppStyles.monoSmall.copyWith(
                            fontSize: 9.5,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (entry.uploader != null)
                        Expanded(
                          child: Text(
                            entry.uploader!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.caption.copyWith(fontSize: 10.5),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (isPlayable)
              IconButton(
                icon: const Icon(
                  Icons.tune_rounded,
                  size: 17,
                  color: AppColors.accentBright,
                ),
                tooltip: 'Inspect individual video formats',
                visualDensity: VisualDensity.compact,
                onPressed: () => searchCtrl.inspectPlaylistEntry(entry),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStreamControlsCard(
    SearchFormatController searchCtrl,
    MediaResource resource,
  ) {
    final options = searchCtrl.options;
    final statusColor = resource.isLive
        ? AppColors.accentBright
        : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sensors_rounded, size: 16, color: statusColor),
              const SizedBox(width: 8),
              Text(
                resource.isLive
                    ? 'LIVE STREAM SETTINGS'
                    : 'SCHEDULED STREAM SETTINGS',
                style: AppStyles.monoHeadline.copyWith(
                  fontSize: 11.5,
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (resource.releaseTimestamp != null)
                Text(
                  Formatters.formatReleaseTimestamp(resource.releaseTimestamp),
                  style: AppStyles.monoSmall.copyWith(fontSize: 10),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () =>
                      searchCtrl.toggleLiveFromStart(!options.liveFromStart),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: options.liveFromStart
                          ? AppColors.accentMuted
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: options.liveFromStart
                            ? AppColors.accentBright
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.replay_rounded,
                          size: 14,
                          color: options.liveFromStart
                              ? AppColors.accentBright
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'From Beginning (DVR)',
                            style: AppStyles.monoSmall.copyWith(
                              fontSize: 10.5,
                              color: options.liveFromStart
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: options.liveFromStart
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () =>
                      searchCtrl.toggleHlsUseMpegts(!options.hlsUseMpegts),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: options.hlsUseMpegts
                          ? AppColors.accentMuted
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: options.hlsUseMpegts
                            ? AppColors.accentBright
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 14,
                          color: options.hlsUseMpegts
                              ? AppColors.accentBright
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Safe MPEG-TS',
                            style: AppStyles.monoSmall.copyWith(
                              fontSize: 10.5,
                              color: options.hlsUseMpegts
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: options.hlsUseMpegts
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (resource.isUpcoming || resource.isPostLive) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wait for broadcast (--wait-for-video):',
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: options.waitForVideoSeconds,
                    isDense: true,
                    dropdownColor: AppColors.surfaceElevated,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Do not wait')),
                      DropdownMenuItem(value: 15, child: Text('Poll 15s')),
                      DropdownMenuItem(value: 30, child: Text('Poll 30s')),
                      DropdownMenuItem(value: 60, child: Text('Poll 60s')),
                      DropdownMenuItem(value: 300, child: Text('Poll 5m')),
                    ],
                    style: AppStyles.monoAccent.copyWith(fontSize: 11),
                    onChanged: searchCtrl.setWaitForVideo,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThumbnail(MediaResource resource, {double height = 280}) {
    final badgeColor = switch (resource.liveStatus) {
      LiveStatus.isLive => AppColors.accent,
      LiveStatus.isUpcoming => AppColors.warning,
      LiveStatus.postLive => AppColors.warning,
      LiveStatus.wasLive => AppColors.surfaceElevated,
      LiveStatus.notLive => AppColors.accent,
    };

    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.0),
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

          // Duration or Live Status Meta Badge (Bottom-Right)
          // if (resource.isLive)
          //   Positioned(
          //     right: 10,
          //     bottom: 10,
          //     child: Container(
          //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          //       decoration: BoxDecoration(
          //         color: Colors.black.withValues(alpha: 0.82),
          //         borderRadius: BorderRadius.circular(4),
          //         border: Border.all(color: AppColors.accentBright),
          //       ),
          //       child: Text(
          //         resource.concurrentViewCount != null
          //             ? '${Formatters.formatCompactNumber(resource.concurrentViewCount)} LIVE'
          //             : 'LIVE STREAM',
          //         style: AppStyles.monoSmall.copyWith(
          //           color: AppColors.accentBright,
          //           fontWeight: FontWeight.w700,
          //           fontSize: 10.5,
          //         ),
          //       ),
          //     ),
          //   )
          if (resource.isUpcoming && resource.releaseTimestamp != null)
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Text(
                  Formatters.formatReleaseTimestamp(resource.releaseTimestamp),
                  style: AppStyles.monoSmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                  ),
                ),
              ),
            )
          else if (resource.durationSeconds != null)
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

          // Live Status / Source Tag (Top-Left)
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(4),
                border: resource.wasLive
                    ? Border.all(color: AppColors.borderLight)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (resource.isLive) ...[
                    const Icon(
                      Icons.fiber_manual_record_rounded,
                      size: 10,
                      color: AppColors.onAccent,
                    ),
                    const SizedBox(width: 4),
                  ] else if (resource.isUpcoming) ...[
                    const Icon(
                      Icons.schedule_rounded,
                      size: 11,
                      color: AppColors.onAccent,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    resource.liveStatus.badgeLabel,
                    style: AppStyles.monoSmall.copyWith(
                      color: resource.wasLive
                          ? AppColors.textPrimary
                          : AppColors.onAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ],
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
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        spacing: 10,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isAudio) {
                  searchCtrl.setAudioOnly(false);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: !isAudio ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_collection_outlined,
                      size: 15,
                      color: !isAudio
                          ? AppColors.onAccent
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'VIDEO + AUDIO',
                      style: AppStyles.monoSmall.copyWith(
                        color: !isAudio
                            ? AppColors.onAccent
                            : AppColors.textSecondary,
                        fontWeight: !isAudio
                            ? FontWeight.w700
                            : FontWeight.w500,
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
                  searchCtrl.setAudioOnly(true);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isAudio ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.audiotrack_rounded,
                      size: 15,
                      color: isAudio
                          ? AppColors.onAccent
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AUDIO ONLY',
                      style: AppStyles.monoSmall.copyWith(
                        color: isAudio
                            ? AppColors.onAccent
                            : AppColors.textSecondary,
                        fontWeight: isAudio ? FontWeight.w700 : FontWeight.w500,
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

  Widget _buildFormatDropdownSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required List<FormatItem> formats,
    required FormatItem? selectedFormat,
    required String emptyLabel,
    required ValueChanged<FormatItem?> onChanged,
  }) {
    final activeSelection = formats.cast<FormatItem?>().firstWhere(
      (f) => f?.formatId == selectedFormat?.formatId,
      orElse: () => formats.isNotEmpty ? formats.first : null,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 15, color: accentColor),
              ),
              const SizedBox(width: 10),
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
                            '${formats.length}',
                            style: AppStyles.monoSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
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
              // if (activeSelection != null)
              //   Text(
              //     'ID: ${activeSelection.formatId}',
              //     style: AppStyles.monoSmall.copyWith(
              //       color: AppColors.textMuted,
              //       fontSize: 10.5,
              //     ),
              //   ),
            ],
          ),
          const SizedBox(height: 12),
          if (formats.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                emptyLabel,
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<FormatItem>(
                  value: activeSelection,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                  items: formats.map((format) {
                    return DropdownMenuItem<FormatItem>(
                      value: format,
                      child: _buildDropdownItem(format, icon, accentColor),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownItem(
    FormatItem format,
    IconData icon,
    Color accentColor,
  ) {
    final isAudioTrack = format.isAudioOnly;
    final codec = isAudioTrack
        ? (format.acodec != null && format.acodec != 'none'
              ? format.acodec!.split('.').first
              : null)
        : (format.vcodec != null && format.vcodec != 'none'
              ? format.vcodec!.split('.').first
              : null);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.chipBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: accentColor),
              const SizedBox(width: 5),
              Text(
                format.displayQuality,
                style: AppStyles.monoSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            format.ext.toUpperCase(),
            style: AppStyles.monoSmall.copyWith(fontSize: 10),
          ),
        ),
        if (!isAudioTrack && format.fps != null && format.fps! > 30) ...[
          const SizedBox(width: 6),
          Text(
            '${format.fps}fps',
            style: AppStyles.monoAccent.copyWith(fontSize: 10.5),
          ),
        ],
        if (codec != null) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '• $codec',
              style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ] else
          const Spacer(),
        if (codec != null) const Spacer(),
        if (format.isHls) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.accentMuted,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'HLS',
              style: AppStyles.monoSmall.copyWith(
                color: AppColors.accentBright,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ] else if (format.filesize != null) ...[
          const SizedBox(width: 8),
          Text(
            Formatters.formatBytes(format.filesize!),
            style: AppStyles.monoSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDownloadButton(
    BuildContext context,
    SearchFormatController searchCtrl,
    MediaResource resource,
  ) {
    final downloadCtrl = context.read<DownloadController>();
    final isPlaylist = resource.isPlaylist;
    final selectedCount = searchCtrl.selectedPlaylistEntries.length;
    final isDisabled = isPlaylist && selectedCount == 0;

    final String buttonLabel;
    final IconData buttonIcon;
    if (isPlaylist) {
      buttonLabel = 'DOWNLOAD $selectedCount SELECTED ITEMS';
      buttonIcon = Icons.playlist_add_check_rounded;
    } else if (resource.isLive) {
      buttonLabel = 'START RECORDING';
      buttonIcon = Icons.sensors_rounded;
    } else if (resource.isUpcoming) {
      buttonLabel = 'WAIT & DOWNLOAD STREAM';
      buttonIcon = Icons.schedule_send_rounded;
    } else {
      buttonLabel = 'DOWNLOAD';
      buttonIcon = Icons.downloading_rounded;
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled
              ? AppColors.surfaceElevated
              : AppColors.accent,
          foregroundColor: isDisabled
              ? AppColors.textMuted
              : AppColors.onAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: isDisabled
            ? null
            : () async {
                final tab = downloadCtrl.createTab(title: resource.title);

                final tasks = await searchCtrl.startDownloadTasks(
                  targetTabId: tab.id,
                );

                if (tasks.isNotEmpty && context.mounted) {
                  if (tasks.length == 1) {
                    downloadCtrl.associateTaskWithTab(tab.id, tasks.first.id);
                  }
                  final tabIndex = downloadCtrl.tabs.indexWhere(
                    (t) => t.id == tab.id,
                  );
                  if (tabIndex != -1) {
                    downloadCtrl.selectTab(tabIndex);
                  }

                  Navigator.of(context).pop();
                  widget.onDownloadCompletedNavigation?.call();
                }
              },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              buttonIcon,
              size: 20,
              color: isDisabled ? AppColors.textMuted : AppColors.onAccent,
            ),
            const SizedBox(width: 10),
            Text(
              buttonLabel,
              style: AppStyles.monoHeadline.copyWith(
                color: isDisabled ? AppColors.textMuted : AppColors.onAccent,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
