import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../controllers/search_format_controller.dart';
import '../../../models/command_template.dart';
import 'command_preview_modal.dart';

class QuickTemplateBar extends StatelessWidget {
  final SearchFormatController controller;
  final List<CommandTemplate> templates;

  const QuickTemplateBar({
    super.key,
    required this.controller,
    required this.templates,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('COMMAND PRESET', style: AppStyles.caption),
            InkWell(
              onTap: () => CommandPreviewModal.show(context, controller),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 14, color: AppColors.accentBright),
                    const SizedBox(width: 4),
                    Text(
                      'Configure CLI',
                      style: AppStyles.monoAccent.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final template = templates[index];
              final isSelected = controller.activeTemplate.id == template.id;

              return ChoiceChip(
                selected: isSelected,
                showCheckmark: false,
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.accentMuted,
                side: BorderSide(
                  color: isSelected ? AppColors.accent : AppColors.border,
                  width: isSelected ? 1.4 : 1.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                label: Text(
                  template.name,
                  style: isSelected
                      ? AppStyles.monoAccent
                      : AppStyles.monoSmall.copyWith(color: AppColors.textSecondary),
                ),
                onSelected: (_) {
                  controller.setActiveTemplate(template);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
