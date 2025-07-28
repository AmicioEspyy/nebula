import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _userEmail;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get userEmail => _userEmail;

  // check login status on startup
  Future<void> checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    // simulate token/session check
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // always false for now, later check
    _isLoggedIn = false;
    _isLoading = false;
    notifyListeners();
  }

  // handle login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // simulate auth request
      await Future.delayed(const Duration(seconds: 2));

      // accept any valid credentials for now
      // real IMAP/SMTP logic will go here later
      if (email.isNotEmpty && password.length >= 6) {
        _isLoggedIn = true;
        _userEmail = email;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // handle logout
  Future<void> logout() async {
    _isLoggedIn = false;
    _userEmail = null;
    notifyListeners();
  }
}
