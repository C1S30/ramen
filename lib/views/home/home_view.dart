import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/formatters.dart';
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
            widget.onNavigateTab?.call(1);
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
    final hasResource = searchCtrl.currentResource != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 22,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Image.asset(
                'assets/icons/ramen_icon.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'RAMEN',
              style: AppStyles.monoHeadline.copyWith(
                fontSize: 15,
                letterSpacing: 3.0,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: searchCtrl.isLoading
                          ? AppColors.warning
                          : AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    searchCtrl.isLoading ? 'RESOLVING' : 'YT-DLP // READY',
                    style: AppStyles.monoSmall.copyWith(
                      fontSize: 9.5,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!hasResource) ...[
                    const SizedBox(height: 12),
                    Text(
                      'UNIVERSAL STREAM ENGINE',
                      style: AppStyles.caption.copyWith(
                        letterSpacing: 2.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Extract Video, Audio,\nPlaylists & Live Streams.',
                      style: AppStyles.monoDisplay.copyWith(
                        fontSize: 24,
                        height: 1.25,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  _buildSearchCommandCard(context, searchCtrl),
                  const SizedBox(height: 16),

                  if (searchCtrl.errorMessage != null) ...[
                    _buildErrorCard(context, searchCtrl),
                    const SizedBox(height: 16),
                  ],

                  if (hasResource) ...[
                    _buildBigPreviewCard(context, searchCtrl),
                    const SizedBox(height: 16),
                  ] else ...[
                    const SizedBox(height: 8),
                    _buildCapabilitiesGrid(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCommandCard(
    BuildContext context,
    SearchFormatController searchCtrl,
  ) {
    final hasText = searchCtrl.urlInputController.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SOURCE URL / SEARCH QUERY',
                style: AppStyles.caption.copyWith(letterSpacing: 1.2),
              ),
              Row(
                children: [
                  if (hasText) ...[
                    InkWell(
                      onTap: searchCtrl.clearUrl,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'CLEAR',
                          style: AppStyles.monoSmall.copyWith(
                            fontSize: 9.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  InkWell(
                    onTap: () => _pasteFromClipboard(searchCtrl),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.content_paste_rounded,
                            size: 11,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PASTE',
                            style: AppStyles.monoSmall.copyWith(
                              fontSize: 9.5,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: TextField(
              controller: searchCtrl.urlInputController,
              style: AppStyles.monoLabel.copyWith(
                fontSize: 13.5,
                color: AppColors.textPrimary,
              ),
              cursorColor: AppColors.accent,
              onSubmitted: (_) => _handleSearch(context, searchCtrl),
              decoration: InputDecoration(
                hintText: 'https://... or search keywords',
                hintStyle: AppStyles.monoSmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.terminal_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: searchCtrl.isLoading
                ? OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surfaceElevated,
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: searchCtrl.cancelSearch,
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
                          'INSPECTING STREAM  •  TAP TO CANCEL',
                          style: AppStyles.monoLabel.copyWith(
                            fontSize: 11.5,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => _handleSearch(context, searchCtrl),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'EXTRACT MEDIA',
                          style: AppStyles.monoHeadline.copyWith(
                            color: AppColors.onAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.north_east_rounded,
                          size: 18,
                          color: AppColors.onAccent,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigPreviewCard(
    BuildContext context,
    SearchFormatController searchCtrl,
  ) {
    final res = searchCtrl.currentResource!;
    final badgeText = res.isPlaylist
        ? (res.isSearchResult ? 'SEARCH RESULTS' : 'PLAYLIST')
        : res.liveStatus.badgeLabel;

    final metaRight = res.isPlaylist
        ? '${searchCtrl.selectedPlaylistEntries.length}/${res.playlistEntries.length} ITEMS'
        : (res.durationSeconds != null
              ? Formatters.formatDuration(res.durationSeconds)
              : (searchCtrl.selectedFormat?.displayQuality ?? 'STREAM'));

    return GestureDetector(
      onTap: () => _navigateToPreview(context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large 16:9 Media Showcase Header
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (res.thumbnail != null)
                    Image.network(
                      res.thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceElevated,
                        child: const Center(
                          child: Icon(
                            Icons.movie_outlined,
                            size: 40,
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
                          size: 40,
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
                          Colors.black.withValues(alpha: 0.88),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: AppStyles.monoSmall.copyWith(
                          color: AppColors.onAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        metaRight,
                        style: AppStyles.monoSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          res.uploader?.toUpperCase() ?? 'MEDIA STREAM',
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
                          res.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.monoTitle.copyWith(
                            fontSize: 14.5,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    searchCtrl.selectedFormat != null && !res.isPlaylist
                        ? 'FORMAT // ${searchCtrl.selectedFormat!.displayQuality.toUpperCase()}'
                        : 'ACTIVE SESSION READY',
                    style: AppStyles.monoSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'CONFIGURE & DOWNLOAD',
                        style: AppStyles.monoAccent.copyWith(
                          fontSize: 11,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(
    BuildContext context,
    SearchFormatController searchCtrl,
  ) {
    final err = searchCtrl.errorMessage!;
    final codeLabel = Formatters.errorCodeLabel(err);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  codeLabel,
                  style: AppStyles.monoSmall.copyWith(
                    color: AppColors.error,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _handleSearch(context, searchCtrl),
                child: Text(
                  'RETRY ↻',
                  style: AppStyles.monoSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            err,
            style: AppStyles.monoSmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilitiesGrid() {
    const specs = [
      ('4K / 8K MUX', 'Lossless FFmpeg stream merge'),
      ('PLAYLISTS', 'Batch & selective index queue'),
      ('LIVE & DVR', 'HLS MPEG-TS & --live-from-start'),
      ('ARIA2C 16X', 'Parallel multi-socket engine'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: specs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.25,
      ),
      itemBuilder: (context, index) {
        final item = specs[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.$1,
                style: AppStyles.monoLabel.copyWith(
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppStyles.monoSmall.copyWith(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
