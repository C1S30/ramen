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
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'SEARCHING...',
                style: AppStyles.monoLabel.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (resource == null) {
      final err = searchCtrl.errorMessage;
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.errorCodeLabel(err),
                    style: AppStyles.monoLabel.copyWith(
                      color: AppColors.error,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Formatters.cleanErrorMessage(err),
                    style: AppStyles.monoSmall.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
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
            size: 17,
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
          resource.url,
          style: AppStyles.monoHeadline.copyWith(
            fontSize: 13,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        actions: [
          if (searchCtrl.canReturnToPlaylist)
            TextButton.icon(
              onPressed: searchCtrl.returnToPlaylist,
              icon: const Icon(
                Icons.playlist_play_rounded,
                size: 16,
                color: AppColors.textPrimary,
              ),
              label: Text(
                'PLAYLIST',
                style: AppStyles.monoAccent.copyWith(fontSize: 10.5),
              ),
            ),
          IconButton(
            icon: const Icon(
              Icons.tune_rounded,
              size: 18,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Advanced yt-dlp Options',
            onPressed: () => _openAdvancedSheet(context, searchCtrl, resource),
          ),
          IconButton(
            icon: const Icon(
              Icons.copy_rounded,
              size: 17,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Copy URL',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: resource.url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('URL COPIED TO CLIPBOARD'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: resource.isPlaylist
          ? _buildPlaylistView(context, searchCtrl, resource)
          : _buildSingleMediaView(context, searchCtrl, resource),
    );
  }

  Widget _buildSingleMediaView(
    BuildContext context,
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

    final effectiveAudioFormats =
        (isAudio && audioFormats.isEmpty && videoFormats.isNotEmpty)
        ? videoFormats
        : audioFormats;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBigHeroPreviewCard(searchCtrl, resource),
                  const SizedBox(height: 16),

                  _buildStreamTypeToggle(searchCtrl, isAudio),
                  const SizedBox(height: 16),

                  if (resource.isLiveOrUpcoming) ...[
                    _buildLiveStreamControlsCard(searchCtrl, resource),
                    const SizedBox(height: 16),
                  ],

                  if (!isAudio && videoFormats.isNotEmpty) ...[
                    _buildQuickResolutionStrip(
                      videoFormats,
                      searchCtrl.selectedVideoFormat,
                      searchCtrl.selectVideoFormat,
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (!isAudio) ...[
                    _buildFormatDropdownSection(
                      title: 'VIDEO STREAM',
                      subtitle: resource.isLive
                          ? 'HLS / DASH live broadcast resolution'
                          : 'Select resolution, frame rate & video codec',
                      icon: Icons.videocam_outlined,
                      formats: videoFormats,
                      selectedFormat: searchCtrl.selectedVideoFormat,
                      emptyLabel: resource.isUpcoming
                          ? 'Auto-negotiated when broadcast goes live (bestvideo)'
                          : 'No video streams available',
                      onChanged: (format) {
                        if (format != null) {
                          searchCtrl.selectVideoFormat(format);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  _buildFormatDropdownSection(
                    title: 'AUDIO STREAM',
                    subtitle: isAudio
                        ? 'Select source audio track for extraction'
                        : 'Select companion audio bitrate & codec',
                    icon: Icons.graphic_eq_rounded,
                    formats: effectiveAudioFormats,
                    selectedFormat: isAudio && audioFormats.isEmpty
                        ? searchCtrl.selectedVideoFormat
                        : searchCtrl.selectedAudioFormat,
                    emptyLabel: resource.isUpcoming
                        ? 'Auto-negotiated when broadcast goes live (bestaudio)'
                        : (videoFormats.any((f) => f.isMerged || f.isHls)
                              ? 'Audio multiplexed inside video stream'
                              : 'No dedicated audio streams available'),
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
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: _buildDownloadButton(context, searchCtrl, resource),
          ),
        ],
      ),
    );
  }

  Widget _buildBigHeroPreviewCard(
    SearchFormatController searchCtrl,
    MediaResource resource,
  ) {
    final chosen = searchCtrl.selectedFormat;
    final rightBadge = resource.isLive
        ? (resource.concurrentViewCount != null
              ? '${Formatters.formatCompactNumber(resource.concurrentViewCount)} WATCHING'
              : 'LIVE EDGE')
        : (resource.isUpcoming && resource.releaseTimestamp != null
              ? Formatters.formatReleaseTimestamp(resource.releaseTimestamp)
              : (resource.durationSeconds != null
                    ? Formatters.formatDuration(resource.durationSeconds)
                    : 'STREAM'));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 228,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (resource.thumbnail != null)
                  Image.network(
                    resource.thumbnail!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceElevated,
                      child: const Center(
                        child: Icon(
                          Icons.movie_outlined,
                          size: 44,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    color: AppColors.surfaceElevated,
                    child: const Center(
                      child: Icon(
                        Icons.movie_outlined,
                        size: 44,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(6),
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
                          const SizedBox(width: 5),
                        ],
                        Text(
                          resource.liveStatus.badgeLabel,
                          style: AppStyles.monoSmall.copyWith(
                            color: AppColors.onAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Text(
                      rightBadge,
                      style: AppStyles.monoSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (resource.uploader ?? 'UNKNOWN CHANNEL')
                                  .toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.monoSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10.5,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          if (resource.viewCount != null && !resource.isLive)
                            Text(
                              '${Formatters.formatCompactNumber(resource.viewCount)} VIEWS',
                              style: AppStyles.monoSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        resource.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.monoTitle.copyWith(
                          fontSize: 15.5,
                          height: 1.25,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _buildMonoSpecChip(
                  chosen?.displayQuality.toUpperCase() ?? 'AUTO QUALITY',
                ),
                const SizedBox(width: 8),
                _buildMonoSpecChip(
                  (searchCtrl.isAudioOnly
                          ? searchCtrl.options.audioFormat
                          : (chosen?.ext ?? 'mp4'))
                      .toUpperCase(),
                ),
                if (chosen?.filesize != null) ...[
                  const SizedBox(width: 8),
                  _buildMonoSpecChip(Formatters.formatBytes(chosen!.filesize)),
                ],
                const Spacer(),
                Text(
                  '${resource.formats.length} STREAMS',
                  style: AppStyles.monoSmall.copyWith(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonoSpecChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        text,
        style: AppStyles.monoSmall.copyWith(
          fontSize: 10,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildQuickResolutionStrip(
    List<FormatItem> videoFormats,
    FormatItem? selectedVideo,
    ValueChanged<FormatItem> onSelect,
  ) {
    final uniqueByQuality = <String, FormatItem>{};
    for (final f in videoFormats) {
      final key = f.displayQuality;
      uniqueByQuality.putIfAbsent(key, () => f);
    }
    final items = uniqueByQuality.values.take(6).toList();
    if (items.length <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK RESOLUTION',
          style: AppStyles.caption.copyWith(letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final fmt = items[index];
              final isSelected = selectedVideo?.formatId == fmt.formatId;
              return GestureDetector(
                onTap: () => onSelect(fmt),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Text(
                    fmt.displayQuality,
                    style: AppStyles.monoSmall.copyWith(
                      color: isSelected
                          ? AppColors.onAccent
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBigPlaylistHeroCard(searchCtrl, resource),
            const SizedBox(height: 12),

            _buildStreamTypeToggle(searchCtrl, isAudio),
            const SizedBox(height: 10),

            _buildPlaylistFormatDropdowns(searchCtrl, resource, isAudio),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TRACKS // $selectedCount OF ${entries.length} SELECTED',
                  style: AppStyles.caption.copyWith(letterSpacing: 1.0),
                ),
                GestureDetector(
                  onTap: () => searchCtrl.selectAllPlaylistItems(!allSelected),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Text(
                      allSelected ? 'DESELECT ALL' : 'SELECT ALL',
                      style: AppStyles.monoSmall.copyWith(
                        fontSize: 10,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

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
                          'NO PLAYABLE ITEMS FOUND IN PLAYLIST',
                          style: AppStyles.monoSmall,
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

            _buildDownloadButton(context, searchCtrl, resource),
          ],
        ),
      ),
    );
  }

  Widget _buildBigPlaylistHeroCard(
    SearchFormatController searchCtrl,
    MediaResource resource,
  ) {
    final entries = resource.playlistEntries;
    return Container(
      height: 164,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (resource.thumbnail != null)
            Image.network(
              resource.thumbnail!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppColors.surfaceElevated),
            )
          else
            Container(color: AppColors.surfaceElevated),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        resource.isSearchResult ? 'SEARCH RESULTS' : 'PLAYLIST',
                        style: AppStyles.monoSmall.copyWith(
                          color: AppColors.onAccent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        '${resource.playlistCount ?? entries.length} TRACKS',
                        style: AppStyles.monoSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (resource.uploader != null)
                  Text(
                    resource.uploader!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.monoSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  resource.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.monoTitle.copyWith(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                                    child: Text('MP3 AUDIO'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'm4a',
                                    child: Text('M4A (AAC)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'opus',
                                    child: Text('OPUS AUDIO'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'flac',
                                    child: Text('FLAC LOSSLESS'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'wav',
                                    child: Text('WAV PCM'),
                                  ),
                                ],
                                style: AppStyles.monoSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
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
                                    child: Text('MAX QUALITY'),
                                  ),
                                  DropdownMenuItem(
                                    value: '2160',
                                    child: Text('2160P (4K)'),
                                  ),
                                  DropdownMenuItem(
                                    value: '1440',
                                    child: Text('1440P (2K)'),
                                  ),
                                  DropdownMenuItem(
                                    value: '1080',
                                    child: Text('1080P (FHD)'),
                                  ),
                                  DropdownMenuItem(
                                    value: '720',
                                    child: Text('720P (HD)'),
                                  ),
                                  DropdownMenuItem(
                                    value: '480',
                                    child: Text('480P (SD)'),
                                  ),
                                  DropdownMenuItem(
                                    value: '360',
                                    child: Text('360P (LOW)'),
                                  ),
                                ],
                                style: AppStyles.monoSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
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
                      isAudio ? 'BITRATE' : 'CONTAINER',
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
                                    child: Text('VBR 0 (BEST)'),
                                  ),
                                  DropdownMenuItem(
                                    value: '320k',
                                    child: Text('320 KBPS'),
                                  ),
                                  DropdownMenuItem(
                                    value: '256k',
                                    child: Text('256 KBPS'),
                                  ),
                                  DropdownMenuItem(
                                    value: '192k',
                                    child: Text('192 KBPS'),
                                  ),
                                  DropdownMenuItem(
                                    value: '128k',
                                    child: Text('128 KBPS'),
                                  ),
                                ],
                                style: AppStyles.monoSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
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
                                    child: Text('MP4 MUX'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'mkv',
                                    child: Text('MKV MUX'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'webm',
                                    child: Text('WEBM MUX'),
                                  ),
                                ],
                                style: AppStyles.monoSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
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
                        'SINGLE YT-DLP BATCH PROCESS (--yes-playlist --playlist-items)',
                        style: AppStyles.monoSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
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
    final idx = (entry.playlistIndex ?? displayIndex).toString().padLeft(
      2,
      '0',
    );

    return InkWell(
      onTap: isPlayable ? () => searchCtrl.togglePlaylistItem(entry.id) : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
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
              width: 26,
              child: Text(
                idx,
                style: AppStyles.monoSmall.copyWith(
                  fontSize: 10.5,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
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
                          width: 58,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 58,
                            height: 36,
                            color: AppColors.surfaceHighlight,
                            child: const Icon(
                              Icons.movie_outlined,
                              size: 15,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : Container(
                          width: 58,
                          height: 36,
                          color: AppColors.surfaceHighlight,
                          child: const Icon(
                            Icons.movie_outlined,
                            size: 15,
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
                    style: AppStyles.monoLabel.copyWith(
                      color: isPlayable
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontSize: 12,
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
                            style: AppStyles.monoSmall.copyWith(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
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
                  Icons.north_east_rounded,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
                tooltip: 'Inspect individual track formats',
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sensors_rounded,
                size: 16,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                resource.isLive
                    ? 'LIVE BROADCAST ENGINE'
                    : 'SCHEDULED BROADCAST ENGINE',
                style: AppStyles.monoHeadline.copyWith(
                  fontSize: 11.5,
                  letterSpacing: 0.8,
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () =>
                      searchCtrl.toggleLiveFromStart(!options.liveFromStart),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: options.liveFromStart
                          ? AppColors.accent
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: options.liveFromStart
                            ? AppColors.accent
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.replay_rounded,
                          size: 14,
                          color: options.liveFromStart
                              ? AppColors.onAccent
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'DVR // FROM START',
                            style: AppStyles.monoSmall.copyWith(
                              fontSize: 10,
                              color: options.liveFromStart
                                  ? AppColors.onAccent
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
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
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: options.hlsUseMpegts
                          ? AppColors.accent
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: options.hlsUseMpegts
                            ? AppColors.accent
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 14,
                          color: options.hlsUseMpegts
                              ? AppColors.onAccent
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'SAFE // MPEG-TS',
                            style: AppStyles.monoSmall.copyWith(
                              fontSize: 10,
                              color: options.hlsUseMpegts
                                  ? AppColors.onAccent
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
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
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'WAIT FOR STREAM (--wait-for-video)',
                  style: AppStyles.monoSmall.copyWith(fontSize: 10.5),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: options.waitForVideoSeconds,
                    isDense: true,
                    dropdownColor: AppColors.surfaceElevated,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('DISABLED')),
                      DropdownMenuItem(value: 15, child: Text('POLL 15S')),
                      DropdownMenuItem(value: 30, child: Text('POLL 30S')),
                      DropdownMenuItem(value: 60, child: Text('POLL 60S')),
                      DropdownMenuItem(value: 300, child: Text('POLL 5M')),
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

  Widget _buildStreamTypeToggle(
    SearchFormatController searchCtrl,
    bool isAudio,
  ) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        spacing: 5,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isAudio) searchCtrl.setAudioOnly(false);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: !isAudio ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_outlined,
                      size: 16,
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
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
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
                if (!isAudio) searchCtrl.setAudioOnly(true);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isAudio ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.graphic_eq_rounded,
                      size: 16,
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
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
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
        borderRadius: BorderRadius.circular(14),
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
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Icon(icon, size: 15, color: AppColors.textPrimary),
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
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Text(
                            '${formats.length}',
                            style: AppStyles.monoSmall.copyWith(
                              fontSize: 10,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppStyles.caption),
                  ],
                ),
              ),
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
                style: AppStyles.monoSmall.copyWith(color: AppColors.textMuted),
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
                    color: AppColors.textPrimary,
                  ),
                  items: formats.map((format) {
                    return DropdownMenuItem<FormatItem>(
                      value: format,
                      child: _buildDropdownItem(format, icon),
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

  Widget _buildDropdownItem(FormatItem format, IconData icon) {
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: AppColors.textPrimary),
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
        const SizedBox(width: 8),
        Text(
          format.ext.toUpperCase(),
          style: AppStyles.monoSmall.copyWith(
            fontSize: 10.5,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (codec != null) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '• ${codec.toUpperCase()}',
              style: AppStyles.monoSmall.copyWith(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ] else
          const Spacer(),
        if (codec != null) const Spacer(),
        if (format.isHls)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.accentMuted,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              'HLS',
              style: AppStyles.monoSmall.copyWith(
                color: AppColors.textPrimary,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else if (format.filesize != null)
          Text(
            Formatters.formatBytes(format.filesize!),
            style: AppStyles.monoSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
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
      buttonLabel = 'DOWNLOAD $selectedCount SELECTED';
      buttonIcon = Icons.playlist_add_check_rounded;
    } else if (resource.isLive) {
      buttonLabel = 'RECORD LIVE';
      buttonIcon = Icons.sensors_rounded;
    } else if (resource.isUpcoming) {
      buttonLabel = 'QUEUE STREAM';
      buttonIcon = Icons.schedule_send_rounded;
    } else {
      buttonLabel = 'DOWNLOAD';
      buttonIcon = Icons.south_rounded;
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled
              ? AppColors.surfaceElevated
              : AppColors.accent,
          foregroundColor: isDisabled
              ? AppColors.textMuted
              : AppColors.onAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
              size: 19,
              color: isDisabled ? AppColors.textMuted : AppColors.onAccent,
            ),
            const SizedBox(width: 10),
            Text(
              buttonLabel,
              style: AppStyles.monoHeadline.copyWith(
                color: isDisabled ? AppColors.textMuted : AppColors.onAccent,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
