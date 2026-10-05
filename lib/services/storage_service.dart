import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_settings.dart';
import '../models/command_template.dart';
import '../models/download_task.dart';

class StorageService {
  static const String _tasksBoxName = 'ramen_tasks';
  static const String _templatesBoxName = 'ramen_templates';
  static const String _settingsBoxName = 'ramen_settings';

  late Box _tasksBox;
  late Box _templatesBox;
  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _tasksBox = await Hive.openBox(_tasksBoxName);
    _templatesBox = await Hive.openBox(_templatesBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);

    // Seed default presets if templates box is empty
    if (_templatesBox.isEmpty) {
      for (final template in CommandTemplate.defaultPresets) {
        await _templatesBox.put(template.id, template.toJson());
      }
    }
  }

  // --- Task Methods ---

  List<DownloadTask> getAllTasks() {
    try {
      final List<DownloadTask> tasks = [];
      for (final key in _tasksBox.keys) {
        final val = _tasksBox.get(key);
        if (val is Map) {
          tasks.add(DownloadTask.fromJson(val));
        }
      }
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    } catch (e) {
      debugPrint('Error loading tasks from Hive: $e');
      return [];
    }
  }

  Future<void> saveTask(DownloadTask task) async {
    await _tasksBox.put(task.id, task.toJson());
  }

  Future<void> deleteTask(String id) async {
    await _tasksBox.delete(id);
  }

  Future<void> clearCompletedTasks() async {
    final toDelete = <dynamic>[];
    for (final key in _tasksBox.keys) {
      final val = _tasksBox.get(key);
      if (val is Map && val['status'] == DownloadStatus.completed.name) {
        toDelete.add(key);
      }
    }
    await _tasksBox.deleteAll(toDelete);
  }

  // --- Template Methods ---

  List<CommandTemplate> getAllTemplates() {
    try {
      final List<CommandTemplate> templates = [];
      for (final key in _templatesBox.keys) {
        final val = _templatesBox.get(key);
        if (val is Map) {
          templates.add(CommandTemplate.fromJson(val));
        }
      }
      if (templates.isEmpty) {
        return CommandTemplate.defaultPresets;
      }
      return templates;
    } catch (e) {
      debugPrint('Error loading templates: $e');
      return CommandTemplate.defaultPresets;
    }
  }

  Future<void> saveTemplate(CommandTemplate template) async {
    await _templatesBox.put(template.id, template.toJson());
  }

  Future<void> deleteTemplate(String id) async {
    await _templatesBox.delete(id);
  }

  // --- Settings Methods ---

  AppSettings getSettings() {
    try {
      final val = _settingsBox.get('current_settings');
      if (val is Map) {
        return AppSettings.fromJson(val);
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
    return AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put('current_settings', settings.toJson());
  }
}
