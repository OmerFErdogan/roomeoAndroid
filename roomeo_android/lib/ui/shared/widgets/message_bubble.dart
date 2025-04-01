import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/message.dart';
import '../../../providers/auth_provider.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final DateTime? displayTime; // displayTime parametresi eklendi

  const MessageBubble({
    Key? key,
    required this.message,
    this.displayTime, // Opsiyonel parametre olarak eklendi
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mesaj sahibini kontrol et
    final currentUser = context.read<AuthProvider>().currentUser;
    final isCurrentUser = message.userId == currentUser?.id;

    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? Theme.of(context).primaryColor
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // System mesajları veya diğer kullanıcıların mesajları için kullanıcı adını göster
                if (!isCurrentUser && message.messageType != 'system')
                  Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                Text(
                  message.content,
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : Colors.black,
                    fontStyle: message.messageType == 'system'
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTime(displayTime ??
                        message.createdAt), // displayTime kullanımı
                    style: TextStyle(
                      fontSize: 10,
                      color: isCurrentUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final localTime = dateTime.toLocal(); // Saati yerel saat dilimine çevir
    return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
  }
}
