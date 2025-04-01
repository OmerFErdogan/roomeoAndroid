// lib/ui/screens/chat/chat_screen.dart - mesaj sıralama düzeltmesi

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/message.dart';
import '../../../providers/message_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../shared/styles/modern_theme.dart';
import '../../shared/widgets/modern_message_bubble.dart';

class RoomChat extends StatefulWidget {
  final int roomId;

  const RoomChat({Key? key, required this.roomId}) : super(key: key);

  @override
  _RoomChatState createState() => _RoomChatState();
}

class _RoomChatState extends State<RoomChat> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    await context.read<MessageProvider>().loadMessages(widget.roomId);
    _connectWebSocket();
  }

  void _connectWebSocket() async {
    // WebSocket bağlantı kodu
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _buildMessageList(),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageList() {
    return Container(
      color: ModernTheme.backgroundLight,
      child: Consumer<MessageProvider>(
        builder: (context, messageProvider, child) {
          if (messageProvider.isLoadingForRoom(widget.roomId)) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ModernTheme.primary),
              ),
            );
          }

          final messages = messageProvider.getMessagesForRoom(widget.roomId);

          if (messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: ModernTheme.textSecondary.withOpacity(0.5),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Henüz mesaj yok',
                    style: ModernTheme.bodyStyle.copyWith(
                      color: ModernTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'İlk mesajı sen gönder!',
                    style: ModernTheme.captionStyle,
                  ),
                ],
              ),
            );
          }

          // Mesajları tarihe göre sırala
          final sortedMessages = List<Message>.from(messages)
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

          return ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(16),
            itemCount: sortedMessages.length,
            itemBuilder: (context, index) {
              final message = sortedMessages[index];
              final showDate = index == 0 ||
                  !_isSameDay(
                    sortedMessages[index - 1].createdAt,
                    message.createdAt,
                  );

              return Column(
                children: [
                  if (showDate) _buildDateDivider(message.createdAt),
                  ModernMessageBubble(
                    message: message,
                    displayTime: message.createdAt,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: ModernTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatFullDate(date),
                style: ModernTheme.captionStyle.copyWith(
                  color: ModernTheme.primary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(child: Divider()),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Bugün';
    }
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Dün';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: ModernTheme.backgroundLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: ModernTheme.borderColor,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Icon(
                      Icons.emoji_emotions_outlined,
                      color: ModernTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Mesajınızı yazın...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.attach_file,
                      color: ModernTheme.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      // Dosya ekleme fonksiyonu
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: ModernTheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      await context.read<MessageProvider>().sendMessage(
            widget.roomId,
            content,
          );
      _messageController.clear();

      // Mesaj gönderildikten sonra otomatik olarak aşağı kaydır
      Future.delayed(Duration(milliseconds: 300), _scrollToBottom);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mesaj gönderilemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
