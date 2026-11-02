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
  bool _isIgnoringBatteryOptimizations = true;

  SettingsController() {
    _settings = _storageService.getSettings();
    loadEngineVersions();
    _syncBackgroundConfig();
    refreshBatteryOptimizationStatus();
  }

  AppSettings get settings => _settings;
  Map<String, String> get engineVersions => _engineVersions;
  bool get isUpdating => _isUpdating;
  String? get updateMessage => _updateMessage;
  bool get isIgnoringBatteryOptimizations => _isIgnoringBatteryOptimizations;

  Future<void> _syncBackgroundConfig() async {
    await _nativeBridge.setBackgroundConfig(
      enableBackgroundProcessing: _settings.enableBackgroundProcessing,
      backgroundNotifications: _settings.backgroundNotifications,
    );
  }

  Future<void> refreshBatteryOptimizationStatus() async {
    _isIgnoringBatteryOptimizations = await _nativeBridge
        .isIgnoringBatteryOptimizations();
    notifyListeners();
  }

  Future<void> requestUnrestrictedBattery() async {
    await _nativeBridge.requestIgnoreBatteryOptimizations();
    await Future.delayed(const Duration(seconds: 1));
    await refreshBatteryOptimizationStatus();
  }

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

  void toggleBackgroundProcessing(bool value) {
    _settings.enableBackgroundProcessing = value;
    _syncBackgroundConfig();
    _save();
  }

  void toggleBackgroundNotifications(bool value) {
    _settings.backgroundNotifications = value;
    _syncBackgroundConfig();
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

  void updateSettings(AppSettings newSettings) {
    _settings = newSettings;
    _save();
  }

  void updateFromYtDlpOptions(dynamic opts) {
    _settings = _settings.copyWith(
      useAria2c: opts.useAria2c as bool?,
      aria2Threads: opts.aria2Connections as int?,
      proxy: (opts.proxy as String?) ?? '',
      rateLimit: (opts.rateLimit as String?) ?? '',
      userAgent: (opts.userAgent as String?) ?? '',
      socketTimeout: opts.socketTimeout as int?,
      forceIpv4: opts.forceIpv4 as bool?,
      forceIpv6: opts.forceIpv6 as bool?,
      embedSubtitles: opts.embedSubtitles as bool?,
      writeAutoSubtitles: opts.writeAutoSubtitles as bool?,
      subLangs: opts.subLangs as String?,
      embedThumbnail: opts.embedThumbnail as bool?,
      embedMetadata: opts.embedMetadata as bool?,
      embedChapters: opts.embedChapters as bool?,
      geoBypass: opts.geoBypass as bool?,
      cookiesFilePath: (opts.cookiesFilePath as String?) ?? '',
      enableSponsorBlock: opts.enableSponsorBlock as bool?,
      rawCustomArgs: opts.rawCustomArgs as String?,
    );
    _save();
  }

  void _save() {
    _storageService.saveSettings(_settings);
    notifyListeners();
  }
}
