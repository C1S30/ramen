import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';
import '../core/di/injection.dart';
import '../controllers/download_controller.dart';
import '../controllers/search_format_controller.dart';
import '../models/download_task.dart';
import '../services/native_bridge_service.dart';
import 'downloads/downloads_view.dart';
import 'home/home_view.dart';
import 'preview/preview_view.dart';
import 'settings/settings_view.dart';

class RootNavigationView extends StatefulWidget {
  const RootNavigationView({super.key});

  @override
  State<RootNavigationView> createState() => _RootNavigationViewState();
}

class _RootNavigationViewState extends State<RootNavigationView>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSharedUrl();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSharedUrl();
    }
  }

  Future<void> _checkSharedUrl() async {
    final nativeBridge = getIt<NativeBridgeService>();
    final sharedUrl = await nativeBridge.getSharedUrl();
    if (sharedUrl != null && sharedUrl.isNotEmpty && mounted) {
      final searchCtrl = context.read<SearchFormatController>();
      searchCtrl.urlInputController.text = sharedUrl;
      setState(() {
        _currentIndex = 0; // Navigate to Home
      });
      searchCtrl.inspectUrl(sharedUrl);
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openPreviewFromBanner(
    BuildContext context,
    SearchFormatController searchCtrl,
  ) {
    searchCtrl.markSearchResultRead();
    setState(() {
      _currentIndex = 0;
    });
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreviewView(
          onDownloadCompletedNavigation: () {
            _onTabSelected(1);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloadCtrl = context.watch<DownloadController>();
    final searchCtrl = context.watch<SearchFormatController>();
    final activeDownloads = downloadCtrl.allTasks
        .where((t) => t.isActive)
        .toList();
    final activeCount = activeDownloads.length;
    final isDownloading = activeCount > 0;
    final isSearching = searchCtrl.isLoading;
    final hasUnreadSearch =
        !isSearching &&
        searchCtrl.currentResource != null &&
        searchCtrl.hasUnreadSearchResult;
    final showSearchBanner =
        _currentIndex != 0 && (isSearching || hasUnreadSearch);
    final showActivityBanner = isDownloading || showSearchBanner;

    final List<Widget> pages = [
      HomeView(
        onNavigateTab: _onTabSelected,
        isActiveTab: () => _currentIndex == 0,
      ),
      DownloadsView(onNewDownloadRequested: () => _onTabSelected(0)),
      // const TemplateEditorView(),
      const SettingsView(),
    ];

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(index: _currentIndex, children: pages),
          ),
          if (showActivityBanner)
            _buildBackgroundActivityBanner(
              context,
              searchCtrl,
              downloadCtrl,
              activeDownloads: activeDownloads,
              isSearching: isSearching,
              showSearchBanner: showSearchBanner,
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: GNav(
              selectedIndex: _currentIndex,
              onTabChange: _onTabSelected,
              backgroundColor: AppColors.background,
              color: AppColors.textMuted,
              activeColor: AppColors.onAccent,
              tabBackgroundColor: AppColors.accent,
              tabBorderRadius: 12,
              gap: 8,
              iconSize: 20,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 220),
              textStyle: AppStyles.monoLabel.copyWith(
                color: AppColors.onAccent,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
              tabs: [
                const GButton(
                  icon: Icons.north_east_rounded,
                  text: 'EXTRACT',
                ),
                GButton(
                  icon: Icons.south_rounded,
                  text: activeCount > 0 ? 'QUEUE ($activeCount)' : 'QUEUE',
                ),
                const GButton(
                  icon: Icons.tune_rounded,
                  text: 'SYSTEM',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundActivityBanner(
    BuildContext context,
    SearchFormatController searchCtrl,
    DownloadController downloadCtrl, {
    required List<DownloadTask> activeDownloads,
    required bool isSearching,
    required bool showSearchBanner,
  }) {
    final isDownloading = activeDownloads.isNotEmpty;
    final primaryTask = isDownloading ? activeDownloads.first : null;
    final downloadProgress = primaryTask != null
        ? primaryTask.progress.clamp(0.0, 100.0)
        : 0.0;
    final query =
        searchCtrl.activeSearchQuery ??
        searchCtrl.urlInputController.text.trim();
    final resource = searchCtrl.currentResource;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      child: Row(
        children: [
          if (isDownloading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                value: downloadProgress > 0 && downloadProgress < 100
                    ? downloadProgress / 100.0
                    : null,
                strokeWidth: 1.8,
                color: AppColors.accent,
                backgroundColor: AppColors.borderLight,
              ),
            )
          else if (isSearching)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: AppColors.accent,
              ),
            )
          else
            const Icon(
              Icons.check_circle_outline_rounded,
              size: 17,
              color: AppColors.textPrimary,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isDownloading
                      ? 'DOWNLOADING${activeDownloads.length > 1 ? ' (${activeDownloads.length})' : ''}  •  ${downloadProgress.toStringAsFixed(1)}%${primaryTask!.speed.isNotEmpty ? '  •  ${primaryTask.speed}' : ''}'
                      : (isSearching ? 'SEARCHING...' : 'READY'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.monoSmall.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isDownloading
                      ? primaryTask!.title
                      : (isSearching
                            ? (query.isNotEmpty
                                  ? query
                                  : 'Resolving media metadata...')
                            : (resource?.title ?? 'Media ready to preview')),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (isDownloading) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(1),
                    child: LinearProgressIndicator(
                      value: downloadProgress > 0 && downloadProgress < 100
                          ? downloadProgress / 100.0
                          : null,
                      minHeight: 2,
                      backgroundColor: AppColors.border,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isDownloading) ...[
            OutlinedButton(
              onPressed: () => downloadCtrl.cancelTask(primaryTask!.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.borderLight),
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
                'CANCEL',
                style: AppStyles.monoSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ] else if (isSearching)
            OutlinedButton(
              onPressed: () => searchCtrl.cancelSearch(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.borderLight),
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
                'CANCEL',
                style: AppStyles.monoSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  letterSpacing: 0.6,
                ),
              ),
            )
          else ...[
            TextButton(
              onPressed: () => searchCtrl.markSearchResultRead(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'DISMISS',
                style: AppStyles.monoSmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: () => _openPreviewFromBanner(context, searchCtrl),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                'OPEN',
                style: AppStyles.monoSmall.copyWith(
                  color: AppColors.onAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
