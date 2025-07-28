import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/star_icon.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StarIcon(
              size: 64,
              color: AppTheme.textSecondary,
            ),
            SizedBox(height: 24),
            Text(
              'Welcome to Nebula!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your email client is ready to use',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: 32),
            Text(
              '📧 Email inbox coming soon...',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
