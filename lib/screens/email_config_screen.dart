import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/email_config_service.dart';
import '../theme/app_theme.dart';
import '../widgets/star_icon.dart';

class EmailConfigScreen extends StatefulWidget {
  const EmailConfigScreen({super.key});

  @override
  State<EmailConfigScreen> createState() => _EmailConfigScreenState();
}

class _EmailConfigScreenState extends State<EmailConfigScreen> {
  // smtp server fields (outgoing)
  final _smtpHostController = TextEditingController();
  final _smtpPortController = TextEditingController();
  String _smtpSecurity = 'SSL/TLS';
  
  // imap server fields (incoming)
  final _imapHostController = TextEditingController();
  final _imapPortController = TextEditingController();
  String _imapSecurity = 'SSL/TLS';
  
  bool _isLoading = false;
  bool _isTesting = false;
  String? _errorMessage;
  bool _hasTestedConnection = false;
  bool _connectionSuccessful = false;

  final List<String> _securityOptions = ['SSL/TLS', 'STARTTLS', 'None'];

  @override
  void initState() {
    super.initState();
    // set default ports
    _smtpPortController.text = '587';
    _imapPortController.text = '993';
    
    // auto-detect settings based on email domain
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoDetectSettings();
    });
  }

  void _autoDetectSettings() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.userEmail != null) {
      final email = authService.userEmail!;
      final domain = email.split('@').last.toLowerCase();
      
      // common email provider settings
      switch (domain) {
        case 'gmail.com':
          _smtpHostController.text = 'smtp.gmail.com';
          _smtpPortController.text = '587';
          _smtpSecurity = 'STARTTLS';
          _imapHostController.text = 'imap.gmail.com';
          _imapPortController.text = '993';
          _imapSecurity = 'SSL/TLS';
          break;
        case 'outlook.com':
        case 'hotmail.com':
        case 'live.com':
          _smtpHostController.text = 'smtp-mail.outlook.com';
          _smtpPortController.text = '587';
          _smtpSecurity = 'STARTTLS';
          _imapHostController.text = 'outlook.office365.com';
          _imapPortController.text = '993';
          _imapSecurity = 'SSL/TLS';
          break;
        case 'yahoo.com':
          _smtpHostController.text = 'smtp.mail.yahoo.com';
          _smtpPortController.text = '587';
          _smtpSecurity = 'STARTTLS';
          _imapHostController.text = 'imap.mail.yahoo.com';
          _imapPortController.text = '993';
          _imapSecurity = 'SSL/TLS';
          break;
        default:
          // try to guess based on domain
          _smtpHostController.text = 'smtp.$domain';
          _imapHostController.text = 'imap.$domain';
          break;
      }
      setState(() {});
    }
  }

  bool _validateFields() {
    return _smtpHostController.text.isNotEmpty &&
           _smtpPortController.text.isNotEmpty &&
           _imapHostController.text.isNotEmpty &&
           _imapPortController.text.isNotEmpty;
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _errorMessage = null;
    });

    // basic validation
    if (!_validateFields()) {
      setState(() {
        _isTesting = false;
        _hasTestedConnection = true;
        _connectionSuccessful = false;
      });
      return;
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final emailConfigService = Provider.of<EmailConfigService>(context, listen: false);
      
      // create temporary config data for testing without saving
      final tempConfig = EmailConfigData(
        smtpHost: _smtpHostController.text,
        smtpPort: int.parse(_smtpPortController.text),
        smtpSecurity: _smtpSecurity,
        imapHost: _imapHostController.text,
        imapPort: int.parse(_imapPortController.text),
        imapSecurity: _imapSecurity,
        email: authService.userEmail!,
        password: authService.userPassword!,
      );
      
      // test connection with temporary config
      final result = await emailConfigService.testConnectionWithConfig(tempConfig);
      
      setState(() {
        _isTesting = false;
        _hasTestedConnection = true;
        _connectionSuccessful = result;
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _hasTestedConnection = true;
        _connectionSuccessful = false;
      });
    }
  }

  @override
  void dispose() {
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _imapHostController.dispose();
    _imapPortController.dispose();
    super.dispose();
  }

  Future<void> _handleConfigSave() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // basic validation
    if (!_validateFields()) {
      setState(() {
        _errorMessage = 'Please fill in all required fields';
        _isLoading = false;
      });
      return;
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final emailConfigService = Provider.of<EmailConfigService>(context, listen: false);
      
      // save configuration
      await emailConfigService.saveConfig(
        smtpHost: _smtpHostController.text,
        smtpPort: int.parse(_smtpPortController.text),
        smtpSecurity: _smtpSecurity,
        imapHost: _imapHostController.text,
        imapPort: int.parse(_imapPortController.text),
        imapSecurity: _imapSecurity,
        email: authService.userEmail!,
        password: authService.userPassword!,
      );
      
      // navigate to home
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Configuration failed. Please check your settings.';
        _isLoading = false;
      });
    }
  }

  Widget _buildCompactConnectionStatus() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (!_hasTestedConnection) {
      statusColor = const Color(0xFFEF4444); // red
      statusIcon = Icons.radio_button_unchecked;
      statusText = 'No connection';
    } else if (_connectionSuccessful) {
      statusColor = const Color(0xFF22C55E); // green
      statusIcon = Icons.check_circle;
      statusText = 'Connected';
    } else {
      statusColor = const Color(0xFFEF4444); // red
      statusIcon = Icons.error;
      statusText = 'Failed';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerCard({
    required String title,
    required String subtitle,
    required TextEditingController hostController,
    required TextEditingController portController,
    required String selectedSecurity,
    required Function(String?) onSecurityChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          // host field
          const Text(
            'Host',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.border,
                width: 1,
              ),
            ),
            child: TextFormField(
              controller: hostController,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'mail.example.com',
                hintStyle: TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // port field
          const Text(
            'Port',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.border,
                width: 1,
              ),
            ),
            child: TextFormField(
              controller: portController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: '587',
                hintStyle: TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // security dropdown
          const Text(
            'Security',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.border,
                width: 1,
              ),
            ),
            child: DropdownButton<String>(
              value: selectedSecurity,
              onChanged: onSecurityChanged,
              underline: const SizedBox(),
              isExpanded: true,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
              items: _securityOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Container(
            width: 1000,
            padding: const EdgeInsets.all(40.0),
            child: Column(
              children: [
                // header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: StarIcon(
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email Configuration',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Configure your email servers',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // connection status indicator in header
                    _buildCompactConnectionStatus(),
                  ],
                ),
                const SizedBox(height: 40),
                
                // desktop layout - side by side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildServerCard(
                        title: 'SMTP Server',
                        subtitle: 'Outgoing mail server',
                        hostController: _smtpHostController,
                        portController: _smtpPortController,
                        selectedSecurity: _smtpSecurity,
                        onSecurityChanged: (value) {
                          setState(() {
                            _smtpSecurity = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: _buildServerCard(
                        title: 'IMAP Server',
                        subtitle: 'Incoming mail server',
                        hostController: _imapHostController,
                        portController: _imapPortController,
                        selectedSecurity: _imapSecurity,
                        onSecurityChanged: (value) {
                          setState(() {
                            _imapSecurity = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                
                // action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // test connection button
                    SizedBox(
                      width: 180,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _isTesting ? null : _testConnection,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isTesting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primary,
                                  ),
                                ),
                              )
                            : const Text(
                                'Test Connection',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // save configuration button
                    SizedBox(
                      width: 180,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleConfigSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Save Configuration',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                
                // error message (only for save errors, not connection test)
                if (_errorMessage != null)
                  Container(
                    width: 400,
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.errorBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.errorBorder,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.errorText,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
