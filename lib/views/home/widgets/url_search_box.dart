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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.link_rounded,
            color: AppColors.accent,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller.urlInputController,
              style: AppStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Paste YouTube URL or media link...',
                hintStyle: AppStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (url) {
                if (url.trim().isNotEmpty) {
                  controller.inspectUrl(url.trim());
                }
              },
            ),
          ),
          // Clear Button
          if (controller.urlInputController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
              onPressed: () {
                controller.reset();
              },
            ),
          // Paste Button
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
