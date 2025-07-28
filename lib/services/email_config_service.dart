import 'package:flutter/foundation.dart';

class EmailConfigData {
  final String smtpHost;
  final int smtpPort;
  final String smtpSecurity;
  final String imapHost;
  final int imapPort;
  final String imapSecurity;
  final String email;
  final String password;

  EmailConfigData({
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpSecurity,
    required this.imapHost,
    required this.imapPort,
    required this.imapSecurity,
    required this.email,
    required this.password,
  });
}

class EmailConfigService extends ChangeNotifier {
  EmailConfigData? _config;
  bool _isConfigured = false;

  bool get isConfigured => _isConfigured;
  EmailConfigData? get config => _config;

  Future<void> saveConfig({
    required String smtpHost,
    required int smtpPort,
    required String smtpSecurity,
    required String imapHost,
    required int imapPort,
    required String imapSecurity,
    required String email,
    required String password,
  }) async {
    _config = EmailConfigData(
      smtpHost: smtpHost,
      smtpPort: smtpPort,
      smtpSecurity: smtpSecurity,
      imapHost: imapHost,
      imapPort: imapPort,
      imapSecurity: imapSecurity,
      email: email,
      password: password,
    );
    
    _isConfigured = true;
    notifyListeners();

    // later save configuration persistently
    // (SharedPreferences, SecureStorage, etc.)
  }

  Future<bool> testConnection() async {
    if (_config == null) return false;
    
    try {
      // simulate connection test
      await Future.delayed(const Duration(seconds: 1));
      
      // later implement real SMTP and IMAP connection testing
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> testConnectionWithConfig(EmailConfigData config) async {
    try {
      // simulate connection test with provided config
      await Future.delayed(const Duration(seconds: 1));
      
      // later implement real SMTP and IMAP connection testing
      // using the provided config instead of saved one
      return true;
    } catch (e) {
      return false;
    }
  }

  void clearConfig() {
    _config = null;
    _isConfigured = false;
    notifyListeners();
  }
}
