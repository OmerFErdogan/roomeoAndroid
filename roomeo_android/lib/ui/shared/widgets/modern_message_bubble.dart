// lib/ui/shared/widgets/modern_message_bubble.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/message.dart';
import '../../../providers/auth_provider.dart';
import '../styles/modern_theme.dart';

class ModernMessageBubble extends StatelessWidget {
  final Message message;
  final DateTime? displayTime;

  const ModernMessageBubble({
    Key? key,
    required this.message,
    this.displayTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mesaj içeriği boşsa veya "joined the room" veya "left the room" içeriyorsa gösterme
    if (message.content.trim().isEmpty ||
        (message.messageType == 'system' &&
            (message.content.contains('joined the room') ||
                message.content.contains('left the room')))) {
      return SizedBox.shrink(); // Hiçbir şey gösterme
    }

    final currentUser = context.read<AuthProvider>().currentUser;
    final isCurrentUser = message.userId == currentUser?.id;
    final isSystemMessage = message.messageType == 'system';

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser && !isSystemMessage) _buildAvatar(),
          SizedBox(width: !isCurrentUser && !isSystemMessage ? 8 : 0),
          _buildMessageContent(context, isCurrentUser, isSystemMessage),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: ModernTheme.primary.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        message.username.isNotEmpty ? message.username[0].toUpperCase() : '?',
        style: TextStyle(
          color: ModernTheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildMessageContent(
      BuildContext context, bool isCurrentUser, bool isSystemMessage) {
    if (isSystemMessage) {
      return _buildSystemMessage(context);
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isCurrentUser ? ModernTheme.primary : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isCurrentUser ? 16 : 4),
          topRight: Radius.circular(isCurrentUser ? 4 : 16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            Text(
              message.username,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: isCurrentUser
                    ? Colors.white.withOpacity(0.9)
                    : ModernTheme.primary,
              ),
            ),
            SizedBox(height: 4),
          ],
          // Client ID işaretlerini temizleyerek mesaj içeriğini göster
          Text(
            _cleanMessageContent(message.content),
            style: TextStyle(
              color: isCurrentUser ? Colors.white : ModernTheme.textPrimary,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 4),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              _formatTime(displayTime ?? message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isCurrentUser
                    ? Colors.white.withOpacity(0.7)
                    : ModernTheme.textSecondary.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: ModernTheme.borderColor),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: ModernTheme.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: ModernTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: ModernTheme.borderColor),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
  }

  // Client ID işaretlerini mesaj içeriğinden temizleyen yardımcı metod
  String _cleanMessageContent(String content) {
    if (content.contains('__CLIENT_ID:')) {
      return content.replaceAll(RegExp(r'__CLIENT_ID:[a-f0-9-]+__'), '').trim();
    }
    return content;
  }
}
