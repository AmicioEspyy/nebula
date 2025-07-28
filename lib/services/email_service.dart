import 'package:flutter/foundation.dart';
import 'package:enough_mail/enough_mail.dart';
import 'email_config_service.dart';

class EmailMessage {
  final String id;
  final String from;
  final String subject;
  final String preview;
  final DateTime date;
  final bool isRead;
  final bool isStarred;
  final String? body;
  final MimeMessage? mimeMessage;

  EmailMessage({
    required this.id,
    required this.from,
    required this.subject,
    required this.preview,
    required this.date,
    this.isRead = false,
    this.isStarred = false,
    this.body,
    this.mimeMessage,
  });

  EmailMessage copyWith({
    String? id,
    String? from,
    String? subject,
    String? preview,
    DateTime? date,
    bool? isRead,
    bool? isStarred,
    String? body,
    MimeMessage? mimeMessage,
  }) {
    return EmailMessage(
      id: id ?? this.id,
      from: from ?? this.from,
      subject: subject ?? this.subject,
      preview: preview ?? this.preview,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      isStarred: isStarred ?? this.isStarred,
      body: body ?? this.body,
      mimeMessage: mimeMessage ?? this.mimeMessage,
    );
  }
}

class EmailService extends ChangeNotifier {
  ImapClient? _imapClient;
  List<EmailMessage> _emails = [];
  bool _isLoading = false;
  String? _error;
  EmailMessage? _selectedEmail;

  List<EmailMessage> get emails => _emails;
  bool get isLoading => _isLoading;
  String? get error => _error;
  EmailMessage? get selectedEmail => _selectedEmail;
  bool get isConnected => _imapClient != null;

  Future<bool> connect(EmailConfigData config) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _imapClient = ImapClient(isLogEnabled: kDebugMode);
      
      // determine connection security
      bool isSecure = config.imapSecurity.toLowerCase().contains('ssl') || 
                     config.imapSecurity.toLowerCase().contains('tls');
      
      // connect to imap server
      await _imapClient!.connectToServer(
        config.imapHost, 
        config.imapPort, 
        isSecure: isSecure,
        timeout: const Duration(seconds: 30),
      );
      
      // authenticate
      await _imapClient!.login(config.email, config.password);
      
      // select inbox
      await _imapClient!.selectInbox();
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = 'failed to connect: $e';
      _isLoading = false;
      if (kDebugMode) {
        print('email service connection failed: $e');
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchEmails({int count = 50}) async {
    if (_imapClient == null) {
      _error = 'not connected to email server';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // fetch recent messages
      final fetchResult = await _imapClient!.fetchRecentMessages(
        messageCount: count,
        criteria: 'BODY.PEEK[HEADER.FIELDS (FROM SUBJECT DATE)]',
      );

      final List<EmailMessage> emails = [];
      
      for (final message in fetchResult.messages) {
        final from = message.from?.isNotEmpty == true 
            ? message.from!.first.toString() 
            : 'unknown sender';
        
        final subject = message.decodeSubject() ?? '(no subject)';
        
        // create preview from subject or first line of text
        String preview = subject;
        if (subject.isEmpty || subject == '(no subject)') {
          // try to get preview from message parts
          final bodyText = message.decodeTextPlainPart() ?? message.decodeTextHtmlPart() ?? '';
          if (bodyText.isNotEmpty) {
            preview = bodyText.length > 100 ? '${bodyText.substring(0, 100)}...' : bodyText;
          }
        }

        emails.add(EmailMessage(
          id: message.uid?.toString() ?? message.sequenceId.toString(),
          from: from,
          subject: subject,
          preview: preview,
          date: message.decodeDate() ?? DateTime.now(),
          isRead: message.isSeen,
          isStarred: message.isFlagged,
          mimeMessage: message,
        ));
      }

      // sort by date (newest first)
      emails.sort((a, b) => b.date.compareTo(a.date));
      
      _emails = emails;
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      _error = 'failed to fetch emails: $e';
      _isLoading = false;
      if (kDebugMode) {
        print('email fetch failed: $e');
      }
      notifyListeners();
    }
  }

  Future<void> loadEmailBody(EmailMessage email) async {
    if (_imapClient == null) return;
    
    try {
      // if body is already loaded, don't reload
      if (email.body != null) {
        _selectedEmail = email;
        notifyListeners();
        return;
      }

      // fetch full message
      final uid = int.tryParse(email.id);
      if (uid == null) return;

      final fetchResult = await _imapClient!.uidFetchMessage(uid, 'BODY[]');
      final fullMessage = fetchResult.messages.isNotEmpty 
          ? fetchResult.messages.first 
          : null;

      if (fullMessage != null) {
        // extract body text
        String body = '';
        
        // try html first, then plain text
        body = fullMessage.decodeTextHtmlPart() ?? 
               fullMessage.decodeTextPlainPart() ?? 
               '(no content)';

        // update the email in the list
        final updatedEmail = email.copyWith(
          body: body,
          mimeMessage: fullMessage,
        );
        
        // update in the emails list
        final emailIndex = _emails.indexWhere((e) => e.id == email.id);
        if (emailIndex >= 0) {
          _emails[emailIndex] = updatedEmail;
        }
        
        _selectedEmail = updatedEmail;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('failed to load email body: $e');
      }
    }
  }

  void selectEmail(EmailMessage email) {
    _selectedEmail = email;
    notifyListeners();
    
    // load full body in background
    loadEmailBody(email);
  }

  void clearSelection() {
    _selectedEmail = null;
    notifyListeners();
  }

  Future<void> markAsRead(EmailMessage email) async {
    if (_imapClient == null) return;
    
    try {
      final uid = int.tryParse(email.id);
      if (uid == null) return;

      await _imapClient!.uidStore(
        MessageSequence.fromId(uid), 
        [MessageFlags.seen],
        action: StoreAction.add,
      );
      
      // update local state
      final emailIndex = _emails.indexWhere((e) => e.id == email.id);
      if (emailIndex >= 0) {
        _emails[emailIndex] = _emails[emailIndex].copyWith(isRead: true);
        if (_selectedEmail?.id == email.id) {
          _selectedEmail = _emails[emailIndex];
        }
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('failed to mark email as read: $e');
      }
    }
  }

  Future<void> toggleStar(EmailMessage email) async {
    if (_imapClient == null) return;
    
    try {
      final uid = int.tryParse(email.id);
      if (uid == null) return;

      final action = email.isStarred ? StoreAction.remove : StoreAction.add;
      await _imapClient!.uidStore(
        MessageSequence.fromId(uid), 
        [MessageFlags.flagged], 
        action: action,
      );
      
      // update local state
      final emailIndex = _emails.indexWhere((e) => e.id == email.id);
      if (emailIndex >= 0) {
        _emails[emailIndex] = _emails[emailIndex].copyWith(isStarred: !email.isStarred);
        if (_selectedEmail?.id == email.id) {
          _selectedEmail = _emails[emailIndex];
        }
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('failed to toggle star: $e');
      }
    }
  }

  Future<void> disconnect() async {
    try {
      await _imapClient?.logout();
      _imapClient = null;
      _emails.clear();
      _selectedEmail = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('disconnect failed: $e');
      }
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
