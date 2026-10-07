import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../controllers/search_format_controller.dart';

class PlaylistFormatView extends StatelessWidget {
  final SearchFormatController controller;
  final VoidCallback onDownloadStarted;

  const PlaylistFormatView({
    super.key,
    required this.controller,
    required this.onDownloadStarted,
  });

  @override
  Widget build(BuildContext context) {
    final resource = controller.currentResource;
    if (resource == null || !resource.isPlaylist) return const SizedBox.shrink();

    final entries = resource.playlistEntries;
    final selectedCount = controller.selectedPlaylistEntries.length;
    final allSelected = selectedCount == entries.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Playlist Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        resource.isSearchResult ? 'SEARCH RESULTS' : 'PLAYLIST',
                        style: AppStyles.monoAccent.copyWith(fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entries.length} items',
                      style: AppStyles.monoSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  resource.title,
                  style: AppStyles.titleMedium,
                ),
                if (resource.uploader != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    resource.uploader!,
                    style: AppStyles.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          const Divider(),

          // Selection Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected: $selectedCount / ${entries.length}',
                  style: AppStyles.monoSmall.copyWith(color: AppColors.textPrimary),
                ),
                TextButton(
                  onPressed: () {
                    controller.selectAllPlaylistItems(!allSelected);
                  },
                  child: Text(
                    allSelected ? 'Deselect All' : 'Select All',
                    style: AppStyles.monoAccent,
                  ),
                ),
              ],
            ),
          ),

          // Playlist / Search Item Entries Checklist
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final item = entries[index];
              final isChecked = controller.selectedPlaylistEntries.contains(item.id);

              return InkWell(
                onTap: () => controller.togglePlaylistItem(item.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isChecked,
                        activeColor: AppColors.accent,
                        checkColor: AppColors.textPrimary,
                        onChanged: (_) => controller.togglePlaylistItem(item.id),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: item.thumbnail != null
                            ? Image.network(
                                item.thumbnail!,
                                width: 64,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 64,
                                  height: 40,
                                  color: AppColors.surfaceHighlight,
                                  child: const Icon(Icons.music_video, size: 18),
                                ),
                              )
                            : Container(
                                width: 64,
                                height: 40,
                                color: AppColors.surfaceHighlight,
                                child: const Icon(Icons.music_video, size: 18),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.bodyLarge.copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (item.durationSeconds != null)
                                  Text(
                                    Formatters.formatDuration(item.durationSeconds),
                                    style: AppStyles.monoSmall,
                                  ),
                                if (item.uploader != null) ...[
                                  const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                                  Expanded(
                                    child: Text(
                                      item.uploader!,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppStyles.caption,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: AppColors.accentBright,
                        ),
                        tooltip: 'Inspect formats',
                        onPressed: () => controller.inspectUrl(item.url),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Batch Download CTA (10% Crimson)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedCount > 0
                      ? AppColors.accent
                      : AppColors.surfaceElevated,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: selectedCount > 0
                    ? () async {
                        await controller.startDownload();
                        onDownloadStarted();
                      }
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.playlist_play_rounded, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'DOWNLOAD $selectedCount VIDEOS',
                      style: AppStyles.monoLabel.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selectedCount > 0
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
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
}
