import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _sessionsKey = 'twist_sessions';
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<List<Map<String, dynamic>>> loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_sessionsKey);
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // Error loading
    }
    return [];
  }

  Future<void> saveSessions(List<Map<String, dynamic>> sessions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionsKey, jsonEncode(sessions));
    } catch (e) {
      // Error saving
    }
  }

  Future<void> addSession(Map<String, dynamic> session) async {
    final sessions = await loadSessions();
    
    // Update if exists
    final index = sessions.indexWhere((s) => s['phone'] == session['phone']);
    if (index >= 0) {
      sessions[index] = session;
    } else {
      sessions.add(session);
    }
    
    await saveSessions(sessions);
  }

  Future<void> removeSession(String phone) async {
    final sessions = await loadSessions();
    sessions.removeWhere((s) => s['phone'] == phone);
    await saveSessions(sessions);
  }

  Future<Map<String, dynamic>?> getSession(String phone) async {
    final sessions = await loadSessions();
    try {
      return sessions.firstWhere((s) => s['phone'] == phone);
    } catch (e) {
      return null;
    }
  }
}
