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

  const HomeView({super.key, this.onNavigateTab});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final List<String> _quickLinks = [
    'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    'https://youtu.be/jNQXAC9IVRw',
  ];

  Future<void> _handleSearch(BuildContext context, SearchFormatController searchCtrl) async {
    final resource = await searchCtrl.inspectUrl();
    if (resource != null && context.mounted) {
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
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 20,
                color: Colors.white,
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
          if (downloadCtrl.activeCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: InkWell(
                onTap: () => widget.onNavigateTab?.call(1),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentMuted,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.accentBright),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.terminal_rounded,
                    color: AppColors.accentBright,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Media Ingestion Engine',
                  style: AppStyles.titleMedium.copyWith(fontSize: 20, letterSpacing: -0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  'Powered by embedded yt-dlp, FFmpeg muxer & aria2c acceleration',
                  style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

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
                const SizedBox(height: 16),
                _buildQuickPresets(searchCtrl),
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

  Widget _buildSearchBox(BuildContext context, SearchFormatController searchCtrl) {
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
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accentBright, size: 20),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (searchCtrl.urlInputController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                  onPressed: () => searchCtrl.clearUrl(),
                ),
              IconButton(
                icon: const Icon(Icons.content_paste_rounded, size: 18, color: AppColors.textSecondary),
                tooltip: 'Paste from clipboard',
                onPressed: () => _pasteFromClipboard(searchCtrl),
              ),
              const SizedBox(width: 4),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildInspectButton(BuildContext context, SearchFormatController searchCtrl) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
        ),
        onPressed: searchCtrl.isLoading ? null : () => _handleSearch(context, searchCtrl),
        child: searchCtrl.isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text('INSPECTING FORMATS...', style: AppStyles.monoLabel.copyWith(color: Colors.white)),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stream_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'INSPECT & PREVIEW',
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
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: AppStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPresets(SearchFormatController searchCtrl) {
    return Column(
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link_rounded, size: 12, color: AppColors.accentBright),
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
        Text(label, style: AppStyles.monoSmall.copyWith(fontSize: 10.5, color: AppColors.textSecondary)),
      ],
    );
  }
}
