import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  bool _isLoading = false;
  String? _error;
  String? _currentPhone;
  List<Map<String, dynamic>> _sessions = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentPhone => _currentPhone;
  List<Map<String, dynamic>> get sessions => _sessions;
  bool get isLoggedIn => _api.isLoggedIn;

  Future<void> loadSessions() async {
    _sessions = await _storage.loadSessions();
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> sendOtp(String phone) async {
    setLoading(true);
    clearError();

    // Format phone
    String formattedPhone = phone;
    if (phone.startsWith('01')) {
      formattedPhone = '2$phone';
    } else if (phone.startsWith('+2')) {
      formattedPhone = phone.substring(1);
    } else {
      formattedPhone = phone.replaceAll('+', '').replaceAll(' ', '');
    }

    final result = await _api.sendOtp(formattedPhone);
    setLoading(false);

    if (result['success']) {
      _currentPhone = formattedPhone;
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String code) async {
    if (_currentPhone == null) return false;

    setLoading(true);
    clearError();

    final result = await _api.verifyOtp(_currentPhone!, code);
    setLoading(false);

    if (result['success']) {
      // Save session
      await _storage.addSession({
        'phone': _currentPhone,
        'authToken': _api.sessionId,
        'lastUsed': DateTime.now().toIso8601String(),
      });
      await loadSessions();
      return true;
    } else {
      _error = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithSavedSession(Map<String, dynamic> session) async {
    setLoading(true);
    clearError();

    // Check if session is still valid
    final isValid = await _api.isSessionValid();
    
    if (isValid) {
      _currentPhone = session['phone'];
      setLoading(false);
      notifyListeners();
      return true;
    } else {
      setLoading(false);
      _error = 'انتهت صلاحية الجلسة، يلزم إدخال رمز تحقق جديد';
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _api.clearTokens();
    _currentPhone = null;
    notifyListeners();
  }
}
