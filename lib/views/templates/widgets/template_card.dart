import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../models/command_template.dart';

class TemplateCard extends StatelessWidget {
  final CommandTemplate template;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback? onDelete;

  const TemplateCard({
    super.key,
    required this.template,
    required this.isSelected,
    required this.onSelect,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.accent : AppColors.border,
          width: isSelected ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accentMuted
                          : AppColors.chipBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.terminal_rounded,
                      size: 16,
                      color: isSelected
                          ? AppColors.accentBright
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    template.name,
                    style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (template.isBuiltIn)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.chipBackground,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('PRESET', style: AppStyles.caption),
                )
              else if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppColors.textMuted),
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            template.description,
            style: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // CLI Flags preview chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: template.flags.map((flag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  flag,
                  style: AppStyles.monoSmall.copyWith(
                    fontSize: 10,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Selection button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    isSelected ? AppColors.accentBright : AppColors.textPrimary,
                side: BorderSide(
                  color: isSelected ? AppColors.accent : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onSelect,
              child: Text(
                isSelected ? 'ACTIVE TEMPLATE' : 'SET AS ACTIVE',
                style: AppStyles.monoSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.accentBright
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
