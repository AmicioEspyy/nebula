import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'services/auth_service.dart';
import 'services/email_config_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/email_config_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const NebulaApp());
  
  doWhenWindowReady(() {
    const initialSize = Size(1266, 732);
    appWindow.minSize = const Size(1266, 732);
    appWindow.size = initialSize;
    appWindow.show();
  });
}

class NebulaApp extends StatelessWidget {
  const NebulaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => EmailConfigService()),
      ],
      child: MaterialApp(
        title: 'nebula',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/email-config': (context) => const EmailConfigScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // check login status on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthService>(context, listen: false).checkLoginStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, EmailConfigService>(
      builder: (context, authService, emailConfigService, child) {
        // show splash while checking login
        if (authService.isLoading) {
          return const SplashScreen();
        }
        
        // navigate based on login status and config status
        if (!authService.isLoggedIn) {
          return const LoginScreen();
        } else if (!emailConfigService.isConfigured) {
          return const EmailConfigScreen();
        } else {
          return const HomeScreen();
        }
      },
    );
  }
}
