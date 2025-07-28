import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _userEmail;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get userEmail => _userEmail;

  // Simula il controllo dello stato di login all'avvio
  Future<void> checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    // Simula una verifica del token/sessione
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Per ora sempre false, in futuro controlla SharedPreferences/SecureStorage
    _isLoggedIn = false;
    _isLoading = false;
    notifyListeners();
  }

  // Gestisce il login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simula una richiesta di autenticazione
      await Future.delayed(const Duration(seconds: 2));

      // Per ora accetta qualsiasi credenziale valida
      // In futuro qui ci sarà la logica IMAP/SMTP reale
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

  // Gestisce il logout
  Future<void> logout() async {
    _isLoggedIn = false;
    _userEmail = null;
    notifyListeners();
  }
}
