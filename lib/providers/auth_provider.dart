import 'package:flutter/material.dart';
import 'package:irise/data/services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AuthStatus _status = AuthStatus.unknown;
  String? _username;
  String? _userId;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  String? get username => _username;
  String? get userId => _userId;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (isLoggedIn) {
        // Validate token by checking if it's still valid
        final userData = await _authService.getCurrentUser();
        
        if (userData != null) {
          _username = userData['name'] ?? userData['email'];
          _userId = userData['id']?.toString();
          _status = AuthStatus.authenticated;
        } else {
          // Token exists but user data is missing, clear token
          await _authService.logout();
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      // If there's an error checking auth status, assume unauthenticated
      await _authService.logout();
      _status = AuthStatus.unauthenticated;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.login(
        username: username,
        password: password,
      );

      if (success) {
        final userData = await _authService.getCurrentUser();
        if (userData != null) {
          _username = userData['name'] ?? userData['email'] ?? username;
          _userId = userData['id']?.toString();
        }
        _status = AuthStatus.authenticated;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid credentials';
        _status = AuthStatus.unauthenticated;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during login: $e';
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    
    _username = null;
    _userId = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
