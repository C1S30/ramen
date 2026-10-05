import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/di/injection.dart';
import '../../controllers/template_controller.dart';
import '../../services/template_engine_service.dart';
import 'widgets/template_card.dart';

class TemplateEditorView extends StatefulWidget {
  const TemplateEditorView({super.key});

  @override
  State<TemplateEditorView> createState() => _TemplateEditorViewState();
}

class _TemplateEditorViewState extends State<TemplateEditorView> {
  final TemplateEngineService _engineService = getIt<TemplateEngineService>();

  void _showAddTemplateDialog(BuildContext context, TemplateController controller) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final flagsCtrl = TextEditingController(text: '--limit-rate 5M --no-playlist');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('New Custom Template', style: AppStyles.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                style: AppStyles.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Template Name',
                  labelStyle: AppStyles.caption,
                  hintText: 'e.g. Night Bandwidth Saver',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: AppStyles.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: AppStyles.caption,
                  hintText: 'e.g. 5MB/s limit, single file extraction',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: flagsCtrl,
                maxLines: 3,
                style: AppStyles.monoSmall.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'CLI Flags (yt-dlp syntax)',
                  labelStyle: AppStyles.caption,
                  hintText: 'e.g. -N 8 --downloader aria2c --limit-rate 3M',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final desc = descCtrl.text.trim();
                    final rawFlags = flagsCtrl.text.trim();

                    if (name.isNotEmpty && rawFlags.isNotEmpty) {
                      final tokenized = _engineService.parseFlagsFromString(rawFlags);
                      controller.saveCustomTemplate(
                        name: name,
                        description: desc.isNotEmpty ? desc : 'Custom CLI template',
                        flags: tokenized,
                      );
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(
                    'CREATE TEMPLATE',
                    style: AppStyles.monoLabel.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templateCtrl = context.watch<TemplateController>();
    final templates = templateCtrl.templates;
    final activeId = templateCtrl.selectedTemplate.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'CLI TEMPLATES',
          style: AppStyles.titleMedium.copyWith(letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.accentBright),
            tooltip: 'Create Custom Template',
            onPressed: () => _showAddTemplateDialog(context, templateCtrl),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: templates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final template = templates[index];
          final isSelected = template.id == activeId;

          return TemplateCard(
            template: template,
            isSelected: isSelected,
            onSelect: () => templateCtrl.selectTemplate(template),
            onDelete: template.isBuiltIn
                ? null
                : () => templateCtrl.deleteTemplate(template.id),
          );
        },
      ),
    );
  }
}
