import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/run_screen_layout.dart';
import '../models/running_session.dart';
import '../models/tts_settings.dart';
import '../models/distance_history.dart';

/// The SharedPreferences keys used by [StorageService]. Public so the
/// settings export/import envelope reuses the exact same names.
class StorageKeys {
  StorageKeys._();

  static const String appSettings = 'app_settings';
  static const String ttsSettings = 'tts_settings';
  static const String activeSession = 'active_session';
  static const String sessionHistory = 'session_history';
  static const String distanceHistory = 'distance_history';
  static const String screenLayouts = 'screen_layouts';
}

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  StorageService._();

  /// Test-only: drops the singleton so a fresh SharedPreferences mock applies.
  @visibleForTesting
  static void resetInstance() => _instance = null;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<AppSettings> loadSettings() async {
    await init();
    final settingsJson = _prefs!.getString(StorageKeys.appSettings);
    if (settingsJson == null) {
      return const AppSettings();
    }
    try {
      final json = jsonDecode(settingsJson) as Map<String, dynamic>;
      return AppSettings.fromJson(json);
    } catch (e) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    await init();
    final settingsJson = jsonEncode(settings.toJson());
    await _prefs!.setString(StorageKeys.appSettings, settingsJson);
  }

  Future<TtsSettings> loadTtsSettings() async {
    await init();
    final settingsJson = _prefs!.getString(StorageKeys.ttsSettings);
    if (settingsJson == null) {
      return const TtsSettings();
    }
    try {
      final json = jsonDecode(settingsJson) as Map<String, dynamic>;
      return TtsSettings.fromJson(json);
    } catch (e) {
      return const TtsSettings();
    }
  }

  Future<void> saveTtsSettings(TtsSettings settings) async {
    await init();
    final settingsJson = jsonEncode(settings.toJson());
    await _prefs!.setString(StorageKeys.ttsSettings, settingsJson);
  }

  Future<RunningSession?> loadActiveSession() async {
    await init();
    final sessionJson = _prefs!.getString(StorageKeys.activeSession);
    if (sessionJson == null) return null;

    try {
      final json = jsonDecode(sessionJson) as Map<String, dynamic>;
      return RunningSession.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveActiveSession(RunningSession session) async {
    await init();
    final sessionJson = jsonEncode(session.toJson());
    await _prefs!.setString(StorageKeys.activeSession, sessionJson);
  }

  Future<void> clearActiveSession() async {
    await init();
    await _prefs!.remove(StorageKeys.activeSession);
  }

  Future<List<RunningSession>> loadSessionHistory() async {
    await init();
    final historyJson = _prefs!.getString(StorageKeys.sessionHistory);
    if (historyJson == null) return [];

    try {
      final jsonList = jsonDecode(historyJson) as List;
      return jsonList
          .map((json) => RunningSession.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveSessionToHistory(RunningSession session) async {
    await init();
    final history = await loadSessionHistory();
    history.add(session);

    final historyJson = jsonEncode(history.map((s) => s.toJson()).toList());
    await _prefs!.setString(StorageKeys.sessionHistory, historyJson);
  }

  Future<void> deleteSession(String sessionId) async {
    await init();
    final history = await loadSessionHistory();
    history.removeWhere((session) => session.id == sessionId);

    final historyJson = jsonEncode(history.map((s) => s.toJson()).toList());
    await _prefs!.setString(StorageKeys.sessionHistory, historyJson);
  }

  Future<DistanceHistory> loadDistanceHistory() async {
    await init();
    final historyJson = _prefs!.getString(StorageKeys.distanceHistory);
    if (historyJson == null) return const DistanceHistory();

    try {
      final json = jsonDecode(historyJson) as Map<String, dynamic>;
      return DistanceHistory.fromJson(json);
    } catch (e) {
      return const DistanceHistory();
    }
  }

  Future<void> saveDistanceHistory(DistanceHistory history) async {
    await init();
    final historyJson = jsonEncode(history.toJson());
    await _prefs!.setString(StorageKeys.distanceHistory, historyJson);
  }

  Future<void> addDistanceToHistory(double distance) async {
    final history = await loadDistanceHistory();
    final updatedHistory = history.addDistance(distance).cleanup();
    await saveDistanceHistory(updatedHistory);
  }

  Future<List<double>> getDistanceSuggestions({int limit = 8}) async {
    final history = await loadDistanceHistory();
    return history.getSuggestions(limit: limit);
  }

  /// Loads the configured run screens; a missing, corrupt, or empty
  /// configuration falls back to [RunScreenLayouts.defaults].
  Future<RunScreenLayouts> loadScreenLayouts() async {
    await init();
    final layoutsJson = _prefs!.getString(StorageKeys.screenLayouts);
    if (layoutsJson == null) return RunScreenLayouts.defaults();

    try {
      final json = jsonDecode(layoutsJson) as Map<String, dynamic>;
      final layouts = RunScreenLayouts.fromJson(json);
      return layouts.screens.isEmpty ? RunScreenLayouts.defaults() : layouts;
    } catch (e) {
      return RunScreenLayouts.defaults();
    }
  }

  Future<void> saveScreenLayouts(RunScreenLayouts layouts) async {
    await init();
    await _prefs!.setString(
      StorageKeys.screenLayouts,
      jsonEncode(layouts.toJson()),
    );
  }

  Future<void> clearAllData() async {
    await init();
    await _prefs!.clear();
  }
}
