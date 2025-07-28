import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_html/flutter_html.dart';
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

  String _extractSenderName(String from) {
    final match = RegExp(r'(.*?)\s*<.*>').firstMatch(from);
    if (match != null) {
      return match.group(1)?.trim() ?? from;
    }
    return from.split('@')[0];
  }

  String _extractSenderEmail(String from) {
    final match = RegExp(r'<(.+)>').firstMatch(from);
    if (match != null) {
      return match.group(1) ?? from;
    }
    return from;
  }

  bool _isHtmlContent(String content) {
    return content.toLowerCase().contains('<html') || 
           content.toLowerCase().contains('<body') ||
           content.toLowerCase().contains('<p>') ||
           content.toLowerCase().contains('<div>') ||
           content.toLowerCase().contains('<br>') ||
           content.toLowerCase().contains('<a ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            const Color(0xFFFCFCFD),
          ],
        ),
      ),
      child: Column(
        children: [
          // elegant header with floating actions
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFE8E9F3),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // top actions row - minimal and clean
                Row(
                  children: [
                    // back button with subtle styling
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE8E9F3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.arrow_back_rounded, size: 20),
                        color: AppTheme.textSecondary,
                        splashRadius: 20,
                      ),
                    ),
                    const Spacer(),
                    // floating action buttons
                    Row(
                      children: [
                        // star button
                        Container(
                          decoration: BoxDecoration(
                            color: email.isStarred 
                                ? Colors.amber.withValues(alpha: 0.08)
                                : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: email.isStarred 
                                  ? Colors.amber.withValues(alpha: 0.2)
                                  : const Color(0xFFE8E9F3),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: onStar,
                            icon: Icon(
                              email.isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 20,
                            ),
                            color: email.isStarred ? Colors.amber[700] : AppTheme.textSecondary,
                            splashRadius: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // mark read button
                        if (!email.isRead)
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              onPressed: onMarkRead,
                              icon: const Icon(Icons.mark_email_read_rounded, size: 20),
                              color: AppTheme.primary,
                              splashRadius: 20,
                            ),
                          ),
                        const SizedBox(width: 8),
                        // more actions
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFE8E9F3),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () {}, // TODO: implement more actions
                            icon: const Icon(Icons.more_vert_rounded, size: 20),
                            color: AppTheme.textSecondary,
                            splashRadius: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // beautiful subject line
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFFAFBFF),
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE8E9F3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (!email.isRead) ...[
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.4),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          email.subject.isEmpty ? '(No Subject)' : email.subject,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.4,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // sender info with elegant styling
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFCFD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF0F1F5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // sender avatar
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primary.withValues(alpha: 0.8),
                              AppTheme.primary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _extractSenderName(email.from).isNotEmpty 
                                ? _extractSenderName(email.from)[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // sender details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _extractSenderName(email.from),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _extractSenderEmail(email.from),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // elegant timestamp
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE8E9F3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          DateFormat('MMM d, HH:mm').format(email.date),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // email content with beautiful typography
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: email.body != null
                  ? Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFF0F1F5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isHtmlContent(email.body!)
                          ? Html(
                              data: email.body!,
                              style: {
                                "body": Style(
                                  fontSize: FontSize(15),
                                  lineHeight: LineHeight(1.6),
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w400,
                                  padding: HtmlPaddings.zero,
                                  margin: Margins.zero,
                                ),
                                "p": Style(
                                  margin: Margins.only(bottom: 12),
                                  fontSize: FontSize(15),
                                  lineHeight: LineHeight(1.6),
                                ),
                                "a": Style(
                                  color: AppTheme.primary,
                                  textDecoration: TextDecoration.underline,
                                ),
                                "h1, h2, h3, h4, h5, h6": Style(
                                  fontWeight: FontWeight.w600,
                                  margin: Margins.only(top: 16, bottom: 8),
                                ),
                                "ul, ol": Style(
                                  margin: Margins.only(bottom: 12),
                                  padding: HtmlPaddings.only(left: 20),
                                ),
                                "li": Style(
                                  margin: Margins.only(bottom: 4),
                                ),
                                "blockquote": Style(
                                  border: Border(left: BorderSide(color: AppTheme.primary, width: 3)),
                                  padding: HtmlPaddings.only(left: 16),
                                  margin: Margins.only(bottom: 12),
                                  fontStyle: FontStyle.italic,
                                ),
                                "code": Style(
                                  backgroundColor: const Color(0xFFF5F5F5),
                                  padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
                                  fontSize: FontSize(14),
                                  fontFamily: 'monospace',
                                ),
                                "pre": Style(
                                  backgroundColor: const Color(0xFFF8F9FA),
                                  padding: HtmlPaddings.all(12),
                                  margin: Margins.only(bottom: 12),
                                  fontSize: FontSize(14),
                                  fontFamily: 'monospace',
                                ),
                              },
                            )
                          : SelectableText(
                              email.body!,
                              style: TextStyle(
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.1,
                              ),
                            ),
                    )
                  : Center(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFF0F1F5),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                Icons.mail_outline_rounded,
                                color: AppTheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'Loading email content...',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
