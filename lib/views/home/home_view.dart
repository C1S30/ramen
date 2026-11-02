import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../controllers/download_controller.dart';
import '../../controllers/search_format_controller.dart';
import '../preview/preview_view.dart';

class HomeView extends StatefulWidget {
  final Function(int)? onNavigateTab;
  final bool Function()? isActiveTab;

  const HomeView({super.key, this.onNavigateTab, this.isActiveTab});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final List<String> _quickLinks = [
    'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    'https://youtu.be/jNQXAC9IVRw',
  ];

  void _navigateToPreview(BuildContext context) {
    context.read<SearchFormatController>().markSearchResultRead();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreviewView(
          onDownloadCompletedNavigation: () {
            widget.onNavigateTab?.call(1); // Switch to Downloads tab
          },
        ),
      ),
    );
  }

  Future<void> _handleSearch(
    BuildContext context,
    SearchFormatController searchCtrl,
  ) async {
    final query = searchCtrl.urlInputController.text.trim();
    if (searchCtrl.currentResource != null &&
        (query.isEmpty || query == searchCtrl.currentResource!.url)) {
      _navigateToPreview(context);
      return;
    }

    final resource = await searchCtrl.inspectUrl();
    final isStillOnSearchTab = widget.isActiveTab?.call() ?? true;
    if (resource != null && context.mounted && isStillOnSearchTab) {
      _navigateToPreview(context);
    }
  }

  Future<void> _pasteFromClipboard(SearchFormatController searchCtrl) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      searchCtrl.setUrl(data.text!.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchCtrl = context.watch<SearchFormatController>();
    final downloadCtrl = context.watch<DownloadController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/icons/ramen_icon.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'RAMEN',
              style: AppStyles.monoHeadline.copyWith(
                fontSize: 18,
                letterSpacing: 2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          if (searchCtrl.currentResource != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: InkWell(
                onTap: () => _navigateToPreview(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.smart_display_rounded,
                        size: 14,
                        color: AppColors.accentBright,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Preview',
                        style: AppStyles.monoAccent.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (downloadCtrl.activeCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: InkWell(
                onTap: () => widget.onNavigateTab?.call(1),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentMuted,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.arrow_downward_rounded,
                        size: 14,
                        color: AppColors.accentBright,
                      ),
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Minimalist Brand Hero
                Container(
                  width: 84,
                  height: 84,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Image.asset(
                    'assets/icons/ramen_icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'R . A . M . E . N',
                  style: AppStyles.titleMedium.copyWith(
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Built with ❤️ by ToM \nPowered by yt-dlp, FFmpeg muxer & aria2c',
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Active Media Preview Resume Banner
                if (searchCtrl.currentResource != null) ...[
                  _buildActivePreviewBanner(context, searchCtrl),
                  const SizedBox(height: 18),
                ],

                // Core Searchbox Component
                _buildSearchBox(context, searchCtrl),
                const SizedBox(height: 14),

                // Inspect & Preview Button
                _buildInspectButton(context, searchCtrl),
                const SizedBox(height: 16),

                // Error Banner
                if (searchCtrl.errorMessage != null)
                  _buildErrorBanner(searchCtrl.errorMessage!),

                // Quick Presets & Links
                // const SizedBox(height: 16),
                // _buildQuickPresets(searchCtrl),
                const SizedBox(height: 28),

                // Engine Capability Badges
                _buildArchitectureBadges(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox(
    BuildContext context,
    SearchFormatController searchCtrl,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: searchCtrl.urlInputController,
        style: AppStyles.bodyLarge.copyWith(fontSize: 14),
        onSubmitted: (_) => _handleSearch(context, searchCtrl),
        decoration: InputDecoration(
          hintText: 'Paste video, audio, or playlist URL...',
          hintStyle: AppStyles.bodyMedium.copyWith(color: AppColors.textMuted),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.accentBright,
            size: 20,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (searchCtrl.urlInputController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => searchCtrl.clearUrl(),
                ),
              IconButton(
                icon: const Icon(
                  Icons.content_paste_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                tooltip: 'Paste from clipboard',
                onPressed: () => _pasteFromClipboard(searchCtrl),
              ),
              const SizedBox(width: 4),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildInspectButton(
    BuildContext context,
    SearchFormatController searchCtrl,
  ) {
    if (searchCtrl.isLoading) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceElevated,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppColors.accent),
                      ),
                    ),
                    onPressed: null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentBright,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'SEARCHING IN BACKGROUND...',
                          style: AppStyles.monoLabel.copyWith(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => searchCtrl.cancelSearch(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text(
                    'CANCEL',
                    style: AppStyles.monoLabel.copyWith(
                      color: AppColors.error,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bolt_rounded,
                size: 14,
                color: AppColors.accentBright,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Search continues if you switch tabs or minimize the app',
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        onPressed: () => _handleSearch(context, searchCtrl),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stream_rounded, size: 18),
            const SizedBox(width: 8),
            Text(
              'SEARCH & PREVIEW',
              style: AppStyles.monoHeadline.copyWith(
                color: Colors.white,
                fontSize: 13,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPresets(SearchFormatController searchCtrl) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DEMO TARGETS', style: AppStyles.caption),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickLinks.map((url) {
            return InkWell(
              onTap: () {
                searchCtrl.setUrl(url);
                _handleSearch(context, searchCtrl);
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      size: 12,
                      color: AppColors.accentBright,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      url.length > 28 ? '${url.substring(0, 28)}...' : url,
                      style: AppStyles.monoSmall.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildArchitectureBadges() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBadge('yt-dlp JNI/NDK'),
          _buildBadge('aria2c 16x Socket'),
          _buildBadge('FFmpeg Lossless'),
        ],
      ),
    );
  }

  Widget _buildBadge(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: AppColors.accentBright,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppStyles.monoSmall.copyWith(
            fontSize: 10.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActivePreviewBanner(
    BuildContext context,
    SearchFormatController searchCtrl,
  ) {
    final res = searchCtrl.currentResource!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentBright, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToPreview(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: res.thumbnail != null
                        ? Image.network(
                            res.thumbnail!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.movie_outlined,
                              size: 24,
                              color: AppColors.textMuted,
                            ),
                          )
                        : const Icon(
                            Icons.movie_outlined,
                            size: 24,
                            color: AppColors.textMuted,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Details
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
                              color: res.isUpcoming
                                  ? AppColors.warning
                                  : AppColors.accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              res.isPlaylist
                                  ? (res.isSearchResult
                                        ? 'SEARCH RESULTS'
                                        : 'PLAYLIST')
                                  : (res.isLive
                                        ? '● LIVE NOW'
                                        : (res.isUpcoming
                                              ? 'UPCOMING'
                                              : 'READY TO DOWNLOAD')),
                              style: AppStyles.monoSmall.copyWith(
                                color: res.isUpcoming
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (res.isPlaylist) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${searchCtrl.selectedPlaylistEntries.length}/${res.playlistEntries.length} selected',
                              style: AppStyles.monoAccent.copyWith(
                                fontSize: 10.5,
                              ),
                            ),
                          ] else if (searchCtrl.selectedFormat != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              searchCtrl.selectedFormat!.displayQuality,
                              style: AppStyles.monoAccent.copyWith(
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        res.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        res.uploader ?? 'Unknown Channel',
                        style: AppStyles.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Action Indicator
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentMuted.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.accentBright,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
