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

  @override
  Widget build(BuildContext context) {
    final downloadCtrl = context.watch<DownloadController>();
    final activeCount = downloadCtrl.activeCount;

    final List<Widget> pages = [
      HomeView(onNavigateTab: _onTabSelected),
      DownloadsView(onNewDownloadRequested: () => _onTabSelected(0)),
      const TemplateEditorView(),
      const SettingsView(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
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
              const NavigationDestination(
                icon: Icon(Icons.search_rounded),
                selectedIcon: Icon(Icons.search_rounded),
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
}
