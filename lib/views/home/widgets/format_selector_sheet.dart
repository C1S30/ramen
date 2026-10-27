import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../controllers/search_format_controller.dart';

class FormatSelectorSheet extends StatelessWidget {
  final SearchFormatController controller;
  final VoidCallback onDownloadStarted;

  const FormatSelectorSheet({
    super.key,
    required this.controller,
    required this.onDownloadStarted,
  });

  @override
  Widget build(BuildContext context) {
    final resource = controller.currentResource;
    if (resource == null) return const SizedBox.shrink();

    final formats = resource.formats;
    final filteredFormats = controller.isAudioOnly
        ? formats.where((f) => f.isAudioOnly).toList()
        : formats.where((f) => !f.isAudioOnly || f.isMerged).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media Header (Thumbnail & Title)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (resource.thumbnail != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      resource.thumbnail!,
                      width: 110,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 110,
                        height: 68,
                        color: AppColors.surfaceElevated,
                        child: const Icon(
                          Icons.movie_outlined,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        resource.uploader ?? 'Unknown Channel',
                        style: AppStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (resource.durationSeconds != null) ...[
                            Text(
                              Formatters.formatDuration(
                                resource.durationSeconds,
                              ),
                              style: AppStyles.monoSmall,
                            ),
                            const Text(
                              ' • ',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                          if (resource.viewCount != null)
                            Text(
                              '${Formatters.formatCompactNumber(resource.viewCount)} views',
                              style: AppStyles.monoSmall,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Audio vs Video Mode Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.setAudioOnly(false),
                      child: Container(
                        decoration: BoxDecoration(
                          color: !controller.isAudioOnly
                              ? AppColors.surfaceHighlight
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.videocam_outlined,
                              size: 16,
                              color: !controller.isAudioOnly
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Video + Audio',
                              style: AppStyles.monoSmall.copyWith(
                                fontWeight: !controller.isAudioOnly
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: !controller.isAudioOnly
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.setAudioOnly(true),
                      child: Container(
                        decoration: BoxDecoration(
                          color: controller.isAudioOnly
                              ? AppColors.surfaceHighlight
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.audiotrack_outlined,
                              size: 16,
                              color: controller.isAudioOnly
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Audio Only',
                              style: AppStyles.monoSmall.copyWith(
                                fontWeight: controller.isAudioOnly
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: controller.isAudioOnly
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
            ),
          ),

          // Available Formats List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              controller.isAudioOnly
                  ? 'AUDIO BITRATES & FORMATS'
                  : 'VIDEO RESOLUTIONS',
              style: AppStyles.caption,
            ),
          ),
          const SizedBox(height: 8),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredFormats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final format = filteredFormats[index];
              final isSelected =
                  controller.selectedFormat?.formatId == format.formatId;

              return InkWell(
                onTap: () => controller.selectFormat(format),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentMuted
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: isSelected ? 1.4 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Radio Indicator
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.textMuted,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.accentBright,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),

                      // Quality Display
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              format.displayQuality,
                              style: AppStyles.monoLabel.copyWith(
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                if (format.ext.isNotEmpty)
                                  format.ext.toUpperCase(),
                                if (format.vcodec != null &&
                                    format.vcodec != 'none')
                                  format.vcodec!.split('.').first,
                                if (format.acodec != null &&
                                    format.acodec != 'none')
                                  format.acodec!.split('.').first,
                              ].join(' • '),
                              style: AppStyles.monoSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Filesize Badge
                      if (format.filesize != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            Formatters.formatBytes(format.filesize),
                            style: AppStyles.monoSmall.copyWith(
                              color: isSelected
                                  ? AppColors.accentBright
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Download CTA Action Button (10% Crimson Rule)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  await controller.startDownload();
                  onDownloadStarted();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.download_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'START DOWNLOAD',
                      style: AppStyles.monoLabel.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
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
