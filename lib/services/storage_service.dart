import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/running_session.dart';

class StorageService {
  static const String _settingsKey = 'app_settings';
  static const String _activeSessionKey = 'active_session';
  static const String _sessionHistoryKey = 'session_history';

  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  StorageService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<AppSettings> loadSettings() async {
    await init();
    final settingsJson = _prefs!.getString(_settingsKey);
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
    await _prefs!.setString(_settingsKey, settingsJson);
  }

  Future<RunningSession?> loadActiveSession() async {
    await init();
    final sessionJson = _prefs!.getString(_activeSessionKey);
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
    await _prefs!.setString(_activeSessionKey, sessionJson);
  }

  Future<void> clearActiveSession() async {
    await init();
    await _prefs!.remove(_activeSessionKey);
  }

  Future<List<RunningSession>> loadSessionHistory() async {
    await init();
    final historyJson = _prefs!.getString(_sessionHistoryKey);
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
    await _prefs!.setString(_sessionHistoryKey, historyJson);
  }

  Future<void> clearAllData() async {
    await init();
    await _prefs!.clear();
  }
}