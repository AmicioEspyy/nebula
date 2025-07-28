import 'package:flutter/foundation.dart';
import 'package:enough_mail/enough_mail.dart';
import 'dart:io';

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
  String? _lastTestError;

  bool get isConfigured => _isConfigured;
  EmailConfigData? get config => _config;
  String? get lastTestError => _lastTestError;

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
    if (_config == null) {
      _lastTestError = 'no configuration available';
      return false;
    }
    
    try {
      _lastTestError = null;
      
      // test both smtp and imap connections
      final smtpResult = await _testSmtpConnection(_config!);
      if (!smtpResult) {
        _lastTestError = 'smtp connection failed';
        return false;
      }
      
      final imapResult = await _testImapConnection(_config!);
      if (!imapResult) {
        _lastTestError = 'imap connection failed';
        return false;
      }
      
      return true;
    } catch (e) {
      _lastTestError = 'connection test failed: $e';
      if (kDebugMode) {
        print('connection test failed: $e');
      }
      return false;
    }
  }

  Future<bool> testConnectionWithConfig(EmailConfigData config) async {
    try {
      _lastTestError = null;
      
      // test both smtp and imap connections with provided config
      final smtpResult = await _testSmtpConnection(config);
      if (!smtpResult) {
        _lastTestError = 'smtp connection failed';
        return false;
      }
      
      final imapResult = await _testImapConnection(config);
      if (!imapResult) {
        _lastTestError = 'imap connection failed';
        return false;
      }
      
      return true;
    } catch (e) {
      _lastTestError = 'connection test with config failed: $e';
      if (kDebugMode) {
        print('connection test with config failed: $e');
      }
      return false;
    }
  }

  Future<bool> _testSmtpConnection(EmailConfigData config) async {
    try {
      // test connection by creating a socket connection to smtp server with timeout
      final socket = await Socket.connect(
        config.smtpHost, 
        config.smtpPort,
      ).timeout(const Duration(seconds: 10));
      
      // properly close the socket
      await socket.close();
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('smtp connection test failed: $e');
      }
      return false;
    }
  }

  Future<bool> _testImapConnection(EmailConfigData config) async {
    try {
      final client = ImapClient(isLogEnabled: kDebugMode);
      
      // determine connection security - fix the SSL/TLS detection
      bool isSecure = config.imapSecurity.toLowerCase().contains('ssl') || 
                     config.imapSecurity.toLowerCase().contains('tls');
      
      // connect to imap server with timeout
      await client.connectToServer(
        config.imapHost, 
        config.imapPort, 
        isSecure: isSecure,
        timeout: const Duration(seconds: 10),
      );
      
      // authenticate
      await client.login(config.email, config.password);
      
      // properly close connection
      await client.logout();
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('imap connection test failed: $e');
      }
      return false;
    }
  }

  void clearConfig() {
    _config = null;
    _isConfigured = false;
    _lastTestError = null;
    notifyListeners();
  }

  // separate test methods for debugging
  Future<bool> testSmtpOnly([EmailConfigData? config]) async {
    final testConfig = config ?? _config;
    if (testConfig == null) return false;
    return await _testSmtpConnection(testConfig);
  }

  Future<bool> testImapOnly([EmailConfigData? config]) async {
    final testConfig = config ?? _config;
    if (testConfig == null) return false;
    return await _testImapConnection(testConfig);
  }
}
