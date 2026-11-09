import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'RAMEN',
          style: AppStyles.monoHeadline.copyWith(
            fontSize: 14,
            letterSpacing: 4.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Minimalist Monochrome Brand Mark
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderLight, width: 1),
                  ),
                  child: Image.asset(
                    'assets/icons/ramen_icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'MEDIA EXTRACTOR',
                  style: AppStyles.monoHeadline.copyWith(
                    fontSize: 12,
                    letterSpacing: 3.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Minimalist video, audio & live stream downloader',
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Active Media Preview Resume Banner
                if (searchCtrl.currentResource != null) ...[
                  _buildActivePreviewBanner(context, searchCtrl),
                  const SizedBox(height: 16),
                ],

                // Core Searchbox Component
                _buildSearchBox(context, searchCtrl),
                const SizedBox(height: 12),

                // Inspect & Preview Button
                _buildInspectButton(context, searchCtrl),
                const SizedBox(height: 16),

                // Error Banner
                if (searchCtrl.errorMessage != null)
                  _buildErrorBanner(
                    searchCtrl.errorMessage!.length > 90
                        ? '${searchCtrl.errorMessage!.substring(0, 90)}...'
                        : searchCtrl.errorMessage!,
                  ),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: TextField(
        controller: searchCtrl.urlInputController,
        style: AppStyles.monoSmall.copyWith(
          fontSize: 13.5,
          color: AppColors.textPrimary,
        ),
        cursorColor: AppColors.accent,
        onSubmitted: (_) => _handleSearch(context, searchCtrl),
        decoration: InputDecoration(
          hintText: 'Paste URL or search query...',
          hintStyle: AppStyles.monoSmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.north_east_rounded,
            color: AppColors.textSecondary,
            size: 18,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (searchCtrl.urlInputController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => searchCtrl.clearUrl(),
                ),
              IconButton(
                icon: const Icon(
                  Icons.content_paste_rounded,
                  size: 16,
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
            vertical: 15,
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
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.borderLight, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'INSPECTING STREAM',
                style: AppStyles.monoLabel.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 11.5,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        onPressed: () => _handleSearch(context, searchCtrl),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.arrow_forward_rounded,
              size: 17,
              color: AppColors.onAccent,
            ),
            const SizedBox(width: 8),
            Text(
              'INSPECT MEDIA',
              style: AppStyles.monoHeadline.copyWith(
                color: AppColors.onAccent,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: AppStyles.monoSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToPreview(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: res.thumbnail != null
                        ? Image.network(
                            res.thumbnail!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.movie_outlined,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                          )
                        : const Icon(
                            Icons.movie_outlined,
                            size: 20,
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
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              res.isPlaylist
                                  ? (res.isSearchResult
                                        ? 'SEARCH'
                                        : 'PLAYLIST')
                                  : (res.isLive
                                        ? '● LIVE'
                                        : (res.isUpcoming
                                              ? 'UPCOMING'
                                              : 'READY')),
                              style: AppStyles.monoSmall.copyWith(
                                color: AppColors.onAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (res.isPlaylist) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${searchCtrl.selectedPlaylistEntries.length}/${res.playlistEntries.length} selected',
                              style: AppStyles.monoSmall.copyWith(
                                fontSize: 10.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ] else if (searchCtrl.selectedFormat != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              searchCtrl.selectedFormat!.displayQuality,
                              style: AppStyles.monoSmall.copyWith(
                                fontSize: 10.5,
                                color: AppColors.textSecondary,
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
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        res.uploader ?? 'Unknown Channel',
                        style: AppStyles.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Action Indicator
                const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: AppColors.textPrimary,
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
