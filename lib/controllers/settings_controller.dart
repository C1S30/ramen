import 'package:flutter/material.dart';
import '../../core/di/injection.dart';
import '../../models/app_settings.dart';
import '../../services/native_bridge_service.dart';
import '../../services/storage_service.dart';

class SettingsController extends ChangeNotifier {
  final StorageService _storageService = getIt<StorageService>();
  final NativeBridgeService _nativeBridge = getIt<NativeBridgeService>();

  late AppSettings _settings;
  Map<String, String> _engineVersions = {};
  bool _isUpdating = false;
  String? _updateMessage;

  SettingsController() {
    _settings = _storageService.getSettings();
    loadEngineVersions();
  }

  AppSettings get settings => _settings;
  Map<String, String> get engineVersions => _engineVersions;
  bool get isUpdating => _isUpdating;
  String? get updateMessage => _updateMessage;

  Future<void> loadEngineVersions() async {
    _engineVersions = await _nativeBridge.getEngineVersions();
    notifyListeners();
  }

  Future<void> updateEngine() async {
    _isUpdating = true;
    _updateMessage = null;
    notifyListeners();

    try {
      final msg = await _nativeBridge.updateEngine();
      _updateMessage = msg;
      await loadEngineVersions();
    } catch (e) {
      _updateMessage = 'Update failed: $e';
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  void setDownloadDirectory(String dir) {
    _settings.downloadDirectory = dir;
    _save();
  }

  void setAria2Threads(int threads) {
    _settings.aria2Threads = threads;
    _save();
  }

  void setMaxConcurrent(int count) {
    _settings.maxConcurrentDownloads = count;
    _save();
  }

  void toggleWifiOnly(bool value) {
    _settings.wifiOnly = value;
    _save();
  }

  void toggleUseAria2c(bool value) {
    _settings.useAria2c = value;
    _save();
  }

  void setDefaultAudioFormat(String format) {
    _settings.defaultAudioFormat = format;
    _save();
  }

  void setDefaultVideoContainer(String container) {
    _settings.defaultVideoContainer = container;
    _save();
  }

  void _save() {
    _storageService.saveSettings(_settings);
    notifyListeners();
  }
}
