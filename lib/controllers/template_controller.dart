import 'package:flutter/material.dart';
import '../../core/di/injection.dart';
import '../../models/command_template.dart';
import '../../services/storage_service.dart';

class TemplateController extends ChangeNotifier {
  final StorageService _storageService = getIt<StorageService>();

  List<CommandTemplate> _templates = [];
  CommandTemplate? _selectedTemplate;

  TemplateController() {
    loadTemplates();
  }

  List<CommandTemplate> get templates => _templates;
  CommandTemplate get selectedTemplate =>
      _selectedTemplate ??
      (_templates.isNotEmpty ? _templates.first : CommandTemplate.defaultPresets.first);

  void loadTemplates() {
    _templates = _storageService.getAllTemplates();
    final settings = _storageService.getSettings();
    _selectedTemplate = _templates.firstWhere(
      (t) => t.id == settings.activeTemplateId,
      orElse: () => _templates.first,
    );
    notifyListeners();
  }

  void selectTemplate(CommandTemplate template) {
    _selectedTemplate = template;
    final settings = _storageService.getSettings();
    settings.activeTemplateId = template.id;
    _storageService.saveSettings(settings);
    notifyListeners();
  }

  Future<void> saveCustomTemplate({
    String? id,
    required String name,
    required String description,
    required List<String> flags,
  }) async {
    final templateId = id ?? 'tpl_${DateTime.now().millisecondsSinceEpoch}';
    final template = CommandTemplate(
      id: templateId,
      name: name,
      description: description,
      flags: flags,
      isBuiltIn: false,
    );

    await _storageService.saveTemplate(template);
    loadTemplates();
  }

  Future<void> deleteTemplate(String id) async {
    await _storageService.deleteTemplate(id);
    loadTemplates();
  }
}
