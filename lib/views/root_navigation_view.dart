import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';
import '../core/di/injection.dart';
import '../controllers/download_controller.dart';
import '../controllers/search_format_controller.dart';
import '../services/native_bridge_service.dart';
import 'downloads/downloads_view.dart';
import 'home/home_view.dart';
import 'preview/preview_view.dart';
import 'settings/settings_view.dart';
import 'templates/template_editor_view.dart';

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
    final activeCount = downloadCtrl.activeCount;
    final isSearching = searchCtrl.isLoading;
    final hasUnreadSearch =
        !isSearching &&
        searchCtrl.currentResource != null &&
        searchCtrl.hasUnreadSearchResult;
    final showBackgroundSearchBanner =
        _currentIndex != 0 && (isSearching || hasUnreadSearch);

    final List<Widget> pages = [
      HomeView(
        onNavigateTab: _onTabSelected,
        isActiveTab: () => _currentIndex == 0,
      ),
      DownloadsView(onNewDownloadRequested: () => _onTabSelected(0)),
      const TemplateEditorView(),
      const SettingsView(),
    ];

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
          ),
          if (showBackgroundSearchBanner)
            _buildBackgroundSearchBanner(
              context,
              searchCtrl,
              isSearching: isSearching,
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.accentMuted,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppStyles.monoAccent.copyWith(fontSize: 11);
              }
              return AppStyles.monoSmall.copyWith(
                fontSize: 11,
                color: AppColors.textMuted,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: AppColors.accentBright, size: 22);
              }
              return const IconThemeData(color: AppColors.textSecondary, size: 22);
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabSelected,
            destinations: [
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: isSearching || hasUnreadSearch,
                  backgroundColor:
                      isSearching ? AppColors.warning : AppColors.success,
                  label: Text(isSearching ? '•••' : '1'),
                  child: const Icon(Icons.search_rounded),
                ),
                selectedIcon: Badge(
                  isLabelVisible: isSearching || hasUnreadSearch,
                  backgroundColor:
                      isSearching ? AppColors.warning : AppColors.success,
                  label: Text(isSearching ? '•••' : '1'),
                  child: const Icon(Icons.search_rounded),
                ),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: activeCount > 0,
                  label: Text('$activeCount'),
                  backgroundColor: AppColors.accent,
                  child: const Icon(Icons.download_rounded),
                ),
                selectedIcon: Badge(
                  isLabelVisible: activeCount > 0,
                  label: Text('$activeCount'),
                  backgroundColor: AppColors.accent,
                  child: const Icon(Icons.download_rounded),
                ),
                label: 'Downloads',
              ),
              const NavigationDestination(
                icon: Icon(Icons.terminal_rounded),
                selectedIcon: Icon(Icons.terminal_rounded),
                label: 'Templates',
              ),
              const NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundSearchBanner(
    BuildContext context,
    SearchFormatController searchCtrl, {
    required bool isSearching,
  }) {
    final query = searchCtrl.activeSearchQuery ??
        searchCtrl.urlInputController.text.trim();
    final resource = searchCtrl.currentResource;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
          top: BorderSide(
            color: isSearching
                ? AppColors.accent.withValues(alpha: 0.6)
                : AppColors.success.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (isSearching)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentBright,
              ),
            )
          else
            const Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: AppColors.success,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSearching
                      ? 'SEARCHING IN BACKGROUND'
                      : 'BACKGROUND SEARCH READY',
                  style: AppStyles.monoSmall.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSearching
                        ? AppColors.accentBright
                        : AppColors.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isSearching
                      ? (query.isNotEmpty ? query : 'Inspecting media stream...')
                      : (resource?.title ?? 'Media ready to preview'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isSearching)
            TextButton(
              onPressed: () => searchCtrl.cancelSearch(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'CANCEL',
                style: AppStyles.monoSmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
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
                  fontSize: 10.5,
                ),
              ),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: () => _openPreviewFromBanner(context, searchCtrl),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
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
                'PREVIEW',
                style: AppStyles.monoSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
