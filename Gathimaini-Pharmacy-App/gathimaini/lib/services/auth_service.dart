import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

/// Simple in-memory auth service.
/// - Hardcoded admin credentials: admin@pharmacy.com / admin123
/// - Any other credential signs in as a regular user.
class AuthService {
  AuthService._private();
  static final AuthService instance = AuthService._private();

  User? _currentUser;
  bool _isAdmin = false;

  User? get currentUser => _currentUser;
  bool get isAdmin => _isAdmin;

  /// Loads the saved user session from local storage.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isAdmin = prefs.getBool('is_admin') ?? false;
    final userStr = prefs.getString('current_user');
    if (userStr != null) {
      _currentUser = User.fromJson(jsonDecode(userStr) as Map<String, dynamic>);
    }
  }

  /// Attempts to sign in. Returns true on success.
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (email == 'admin@pharmacy.com' && password == 'admin123') {
      _isAdmin = true;
      _currentUser = User(id: 'admin', name: 'Administrator', email: email);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_admin', _isAdmin);
      await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
      return true;
    }

    // Accept other credentials as regular users
    _isAdmin = false;
    final name = email.contains('@') ? email.split('@').first : email;
    _currentUser = User(id: email, name: name, email: email);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_admin', _isAdmin);
    await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    _isAdmin = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    await prefs.remove('is_admin');
  }
}
