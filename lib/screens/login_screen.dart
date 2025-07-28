import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/star_icon.dart';
import 'email_config_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isButtonPressed = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // reset errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    bool hasErrors = false;

    // email validation
    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'Please enter your email';
      });
      hasErrors = true;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      setState(() {
        _emailError = 'Please enter a valid email';
      });
      hasErrors = true;
    }

    // password validation
    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = 'Please enter your password';
      });
      hasErrors = true;
    }

    if (hasErrors) return;

    // auth service
    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.login(_emailController.text, _passwordController.text);

    if (success && mounted) {
      // Navigate to email configuration screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EmailConfigScreen()),
      );
    } else if (!success && mounted) {
      setState(() {
        _emailError = 'Invalid credentials';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  // logo & title
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: StarIcon(
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'nebula',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your email to continue',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // email field
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _emailError != null 
                          ? AppTheme.borderError
                          : AppTheme.border,
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
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'hi@amicioespyy.eu',
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
                  const SizedBox(height: 16),

                  // password field
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _passwordError != null 
                          ? AppTheme.borderError
                          : AppTheme.border,
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
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••••••',
                        hintStyle: const TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 15,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onFieldSubmitted: (_) {
                        _handleLogin();
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // continue button
                  Consumer<AuthService>(
                    builder: (context, authService, child) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: double.infinity,
                        height: 44,
                        decoration: BoxDecoration(
                          color: authService.isLoading 
                            ? const Color(0xFFE5E7EB) 
                            : _isButtonPressed 
                              ? const Color.fromARGB(255, 60, 60, 60) 
                              : AppTheme.primary,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: !authService.isLoading ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                        child: GestureDetector(
                          onTap: authService.isLoading ? null : _handleLogin,
                          onTapDown: (_) {
                            if (!authService.isLoading) {
                              setState(() {
                                _isButtonPressed = true;
                              });
                            }
                          },
                          onTapUp: (_) {
                            setState(() {
                              _isButtonPressed = false;
                            });
                          },
                          onTapCancel: () {
                            setState(() {
                              _isButtonPressed = false;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: authService.isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppTheme.textSecondary,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // error messages
                  if (_emailError != null || _passwordError != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.errorBorder,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_emailError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                _emailError!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.errorText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (_passwordError != null)
                            Text(
                              _passwordError!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.errorText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                ],
            ),
          ),
        ),
      ),
    );
  }
}
