import 'package:flutter/material.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unauthenticated;
  String? _token;
  String? _userId;
  String? _tenantId;
  String? _errorMessage;

  AuthStatus get status => _status;
  String? get token => _token;
  String? get userId => _userId;
  String? get tenantId => _tenantId;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAuthenticating => _status == AuthStatus.authenticating;

  // Mock login process imitating FastAPI JWT auth endpoint
  Future<bool> login({
    required String tenantId,
    required String userId,
    required String password,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    // Simulate network delay to backend
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      // Mock validation logic based on the schema and mock validation requirements
      if (tenantId.isEmpty || userId.isEmpty || password.isEmpty) {
        throw Exception("모든 필드를 입력해 주세요.");
      }

      // Simple mock credential check
      if (userId == 'admin' && password == 'admin123') {
        _status = AuthStatus.authenticated;
        _token = "mock_jwt_access_token_value_for_${userId}";
        _userId = userId;
        _tenantId = tenantId;
        notifyListeners();
        return true;
      } else {
        throw Exception("사용자 ID 또는 비밀번호가 올바르지 않습니다.");
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return false;
    }
  }

  // Logout reset session
  void logout() {
    _status = AuthStatus.unauthenticated;
    _token = null;
    _userId = null;
    _tenantId = null;
    _errorMessage = null;
    notifyListeners();
  }
}
