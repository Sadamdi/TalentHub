import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String applicationId;

  const ChatScreen({Key? key, required this.applicationId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isSending = false;
  Timer? _pollTimer;
  String? _lastMessageId;

  @override
  void initState() {
    super.initState();
    _loadChat();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    // Poll for new messages every 5 seconds (lebih jarang untuk menghindari konflik)
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_isSending) {
        // Jangan polling saat sedang mengirim pesan
        _loadChatSilently();
      }
    });
  }

  Future<void> _loadChat() async {
    print(
        '🔍 ChatScreen: Loading chat for application: ${widget.applicationId}');
    setState(() {
      _isLoading = true;
    });

    final applicationProvider =
        Provider.of<ApplicationProvider>(context, listen: false);
    await applicationProvider.getChatByApplicationId(widget.applicationId);

    // Update last message ID for comparison
    final chat = applicationProvider.chat;
    if (chat != null &&
        chat['messages'] != null &&
        chat['messages'].isNotEmpty) {
      _lastMessageId = chat['messages'].last['_id'] ?? '';
      print(
          '✅ ChatScreen: Chat loaded with ${chat['messages'].length} messages');
    } else {
      print(
          '⚠️ ChatScreen: No chat or messages found for application: ${widget.applicationId}');
    }

    setState(() {
      _isLoading = false;
    });

    // Auto scroll to bottom after loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _loadChatSilently() async {
    final applicationProvider =
        Provider.of<ApplicationProvider>(context, listen: false);
    await applicationProvider.getChatByApplicationId(widget.applicationId);

    // Check if there are new messages
    final chat = applicationProvider.chat;
    if (chat != null &&
        chat['messages'] != null &&
        chat['messages'].isNotEmpty) {
      final latestMessageId = chat['messages'].last['_id'] ?? '';

      // If there's a new message, scroll to bottom
      if (_lastMessageId != null && _lastMessageId != latestMessageId) {
        _lastMessageId = latestMessageId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else if (_lastMessageId == null) {
        _lastMessageId = latestMessageId;
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      final applicationProvider =
          Provider.of<ApplicationProvider>(context, listen: false);

      await applicationProvider.sendChatMessage(widget.applicationId, message);

      // Update last message ID from the new chat data
      final chat = applicationProvider.chat;
      if (chat != null &&
          chat['messages'] != null &&
          chat['messages'].isNotEmpty) {
        _lastMessageId = chat['messages'].last['_id'] ?? '';
      }

      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chat',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<ApplicationProvider>(
        builder: (context, applicationProvider, child) {
          final chat = applicationProvider.chat;

          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          if (chat?.isEmpty ?? true) {
            return const Center(
              child: Text(
                'Chat tidak ditemukan',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          final messages = chat?['messages'] as List<dynamic>? ?? [];
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          final currentUserId = authProvider.user?.id ?? '';

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMyMessage = message['senderId'] == currentUserId;
                    final senderRole = message['senderRole'] ?? 'unknown';

                    String senderName = 'Unknown';
                    if (isMyMessage) {
                      senderName = 'You';
                    } else {
                      // Get sender name from message data if available
                      if (message['senderName'] != null &&
                          message['senderName'].isNotEmpty) {
                        senderName = message['senderName'];
                      } else {
                        // Fallback to role-based names
                        if (senderRole == 'talent') {
                          senderName = 'Talent';
                        } else if (senderRole == 'company') {
                          senderName = 'Company';
                        } else if (senderRole == 'admin') {
                          senderName = 'Admin';
                        }
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      alignment: isMyMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isMyMessage
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isMyMessage
                                  ? AppColors.primary
                                  : AppColors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMyMessage)
                                  Text(
                                    senderName,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                Text(
                                  message['message'] ?? '',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: isMyMessage
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(message['timestamp']),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: isMyMessage
                                        ? Colors.white70
                                        : AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Ketik pesan...',
                          hintStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.textLight,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: AppColors.grey.withOpacity(0.3),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (value) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: IconButton(
                        onPressed: _isSending ? null : _sendMessage,
                        icon: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                size: 18,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    try {
      DateTime dateTime;
      if (timestamp is String) {
        // Parse as UTC first, then convert to local time
        dateTime = DateTime.parse(timestamp).toLocal();
      } else if (timestamp is DateTime) {
        // Ensure it's in local time
        dateTime = timestamp.toLocal();
      } else {
        return '';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Kemarin ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
