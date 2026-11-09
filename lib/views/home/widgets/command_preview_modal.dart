import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../controllers/search_format_controller.dart';

class CommandPreviewModal extends StatefulWidget {
  final SearchFormatController controller;

  const CommandPreviewModal({super.key, required this.controller});

  static void show(BuildContext context, SearchFormatController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: CommandPreviewModal(controller: controller),
      ),
    );
  }

  @override
  State<CommandPreviewModal> createState() => _CommandPreviewModalState();
}

class _CommandPreviewModalState extends State<CommandPreviewModal> {
  final TextEditingController _flagInputCtrl = TextEditingController();

  final List<String> _quickFlagSuggestions = [
    '--limit-rate 5M',
    '--no-playlist',
    '--geo-bypass',
    '--embed-thumbnail',
    '--write-subs',
    '--restrict-filenames',
  ];

  @override
  void dispose() {
    _flagInputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CLI Command Inspector', style: AppStyles.titleMedium),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Synthesized yt-dlp arguments executed by native engine',
            style: AppStyles.bodyMedium,
          ),
          const SizedBox(height: 16),

          // Raw Command Terminal Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SelectableText(
                    controller.previewCommandLine.isNotEmpty
                        ? controller.previewCommandLine
                        : 'yt-dlp ${controller.activeTemplate.flags.join(" ")} [URL]',
                    style: AppStyles.monoLabel.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: AppColors.textSecondary),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: controller.previewCommandLine),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Command copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Custom Flag Input
          Text('Add Custom Arguments / Flags', style: AppStyles.monoSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _flagInputCtrl,
                  style: AppStyles.monoSmall.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. --limit-rate 2M',
                    hintStyle: AppStyles.monoSmall.copyWith(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      controller.addCustomFlag(val.trim());
                      _flagInputCtrl.clear();
                      setState(() {});
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onPressed: () {
                  if (_flagInputCtrl.text.trim().isNotEmpty) {
                    controller.addCustomFlag(_flagInputCtrl.text.trim());
                    _flagInputCtrl.clear();
                    setState(() {});
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick Suggestion Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _quickFlagSuggestions.map((flag) {
              final isAdded = controller.userCustomFlags.contains(flag);
              return ActionChip(
                backgroundColor: isAdded ? AppColors.accentMuted : AppColors.surface,
                side: BorderSide(
                  color: isAdded ? AppColors.accent : AppColors.border,
                ),
                label: Text(
                  flag,
                  style: AppStyles.monoSmall.copyWith(
                    color: isAdded ? AppColors.accentBright : AppColors.textSecondary,
                  ),
                ),
                onPressed: () {
                  if (isAdded) {
                    controller.removeCustomFlag(flag);
                  } else {
                    controller.addCustomFlag(flag);
                  }
                  setState(() {});
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          if (controller.userCustomFlags.isNotEmpty) ...[
            Text('Active Custom Overrides:', style: AppStyles.caption),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: controller.userCustomFlags.map((flag) {
                return Chip(
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.accent),
                  label: Text(flag, style: AppStyles.monoSmall),
                  deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.accentBright),
                  onDeleted: () {
                    controller.removeCustomFlag(flag);
                    setState(() {});
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
