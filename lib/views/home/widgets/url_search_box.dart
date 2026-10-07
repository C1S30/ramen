import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../controllers/search_format_controller.dart';

class UrlSearchBox extends StatelessWidget {
  final SearchFormatController controller;

  const UrlSearchBox({super.key, required this.controller});

  Future<void> _pasteFromClipboard(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      controller.urlInputController.text = data.text!.trim();
      controller.inspectUrl(data.text!.trim());
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clipboard is empty'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = controller.urlInputController.text.trim().isNotEmpty;
    final isUrl = controller.urlInputController.text.trim().startsWith('http://') ||
        controller.urlInputController.text.trim().startsWith('https://') ||
        controller.urlInputController.text.trim().contains('youtube.com') ||
        controller.urlInputController.text.trim().contains('youtu.be');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasText ? AppColors.accent.withValues(alpha: 0.7) : AppColors.border,
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(
            isUrl ? Icons.link_rounded : Icons.search_rounded,
            color: AppColors.accent,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller.urlInputController,
              style: AppStyles.bodyLarge,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search YouTube or paste media URL...',
                hintStyle: AppStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  controller.inspectUrl(val.trim());
                }
              },
            ),
          ),
          // Clear Button
          if (hasText)
            IconButton(
              icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
              tooltip: 'Clear input',
              onPressed: () {
                controller.reset();
              },
            ),
          // Search Trigger Button when text exists
          if (hasText)
            IconButton(
              tooltip: 'Search yt-dlp',
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.accentBright,
                size: 20,
              ),
              onPressed: controller.isLoading
                  ? null
                  : () => controller.inspectUrl(),
            ),
          // Paste Button
          if (!hasText)
            IconButton(
              tooltip: 'Paste from clipboard',
              icon: const Icon(
                Icons.content_paste_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () => _pasteFromClipboard(context),
            ),
        ],
      ),
    );
  }
}
