import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/star_icon.dart';
import '../services/email_service.dart';
import '../services/email_config_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late EmailService _emailService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _emailService = EmailService();
    _initializeEmailService();
  }

  Future<void> _initializeEmailService() async {
    final emailConfigService = Provider.of<EmailConfigService>(context, listen: false);
    
    if (emailConfigService.config != null) {
      final success = await _emailService.connect(emailConfigService.config!);
      if (success) {
        await _emailService.fetchEmails();
      }
    }
    
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _emailService.dispose();
    super.dispose();
  }

  Widget _buildEmailList() {
    return ChangeNotifierProvider.value(
      value: _emailService,
      child: Consumer<EmailService>(
        builder: (context, emailService, child) {
          if (emailService.isLoading && emailService.emails.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (emailService.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading emails',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    emailService.error!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _initializeEmailService(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (emailService.emails.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No emails found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your inbox is empty',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => emailService.fetchEmails(),
            child: ListView.builder(
              itemCount: emailService.emails.length,
              itemBuilder: (context, index) {
                final email = emailService.emails[index];
                final isSelected = emailService.selectedEmail?.id == email.id;
                
                return _EmailListItem(
                  email: email,
                  isSelected: isSelected,
                  onTap: () => emailService.selectEmail(email),
                  onStar: () => emailService.toggleStar(email),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmailViewer() {
    return ChangeNotifierProvider.value(
      value: _emailService,
      child: Consumer<EmailService>(
        builder: (context, emailService, child) {
          if (emailService.selectedEmail == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 64,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Select an email to view',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Choose an email from the list to read its content',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return _EmailViewer(
            email: emailService.selectedEmail!,
            onClose: () => emailService.clearSelection(),
            onStar: () => emailService.toggleStar(emailService.selectedEmail!),
            onMarkRead: () => emailService.markAsRead(emailService.selectedEmail!),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // email list on the left
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: AppTheme.border,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // header with refresh
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.border,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const StarIcon(
                          size: 24,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Inbox',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => _emailService.fetchEmails(),
                          icon: const Icon(Icons.refresh),
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  // email list
                  Expanded(child: _buildEmailList()),
                ],
              ),
            ),
          ),
          // email viewer on the right
          Expanded(
            flex: 3,
            child: _buildEmailViewer(),
          ),
        ],
      ),
    );
  }
}

class _EmailListItem extends StatelessWidget {
  final EmailMessage email;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onStar;

  const _EmailListItem({
    required this.email,
    required this.isSelected,
    required this.onTap,
    required this.onStar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.border,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                email.from,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: email.isRead ? FontWeight.w400 : FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('MMM d').format(email.date),
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onStar,
              child: Icon(
                email.isStarred ? Icons.star : Icons.star_border,
                size: 16,
                color: email.isStarred ? Colors.amber : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              email.subject,
              style: TextStyle(
                fontSize: 13,
                fontWeight: email.isRead ? FontWeight.w400 : FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              email.preview,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailViewer extends StatelessWidget {
  final EmailMessage email;
  final VoidCallback onClose;
  final VoidCallback onStar;
  final VoidCallback onMarkRead;

  const _EmailViewer({
    required this.email,
    required this.onClose,
    required this.onStar,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppTheme.border,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.arrow_back),
                    color: AppTheme.textSecondary,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onStar,
                    icon: Icon(
                      email.isStarred ? Icons.star : Icons.star_border,
                    ),
                    color: email.isStarred ? Colors.amber : AppTheme.textSecondary,
                  ),
                  if (!email.isRead)
                    IconButton(
                      onPressed: onMarkRead,
                      icon: const Icon(Icons.mark_email_read),
                      color: AppTheme.textSecondary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                email.subject,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'From: ${email.from}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM d, yyyy - HH:mm').format(email.date),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // email body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: email.body != null
                ? SelectableText(
                    email.body!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      height: 1.5,
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
        ),
      ],
    );
  }
}
