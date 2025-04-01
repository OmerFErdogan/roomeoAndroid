// lib/ui/screens/chat/realtime_chat.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/message.dart';
import '../../../providers/message_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/message_event_bus.dart';
import '../../shared/widgets/modern_message_bubble.dart';
import '../../shared/styles/modern_theme.dart';

class RealtimeChat extends StatefulWidget {
  final int roomId;

  const RealtimeChat({
    Key? key,
    required this.roomId,
  }) : super(key: key);

  @override
  _RealtimeChatState createState() => _RealtimeChatState();
}

class _RealtimeChatState extends State<RealtimeChat> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late StreamSubscription<MessageEvent> _eventSubscription;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Mesajları yükledikten sonra initialize et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    if (_isInitialized) return;

    final messageProvider = context.read<MessageProvider>();

    try {
      // İlk mesajları yükle (MessageProvider içerisinde listenize eklenen notifyListeners() olduğundan emin olun)
      await messageProvider.loadMessages(widget.roomId);
      print(
          "Initial messages loaded. Count: ${messageProvider.getSortedMessagesForRoom(widget.roomId).length}");

      // Event Bus'tan gelen mesaj eventlerini dinle
      final eventBus = MessageEventBus();
      _eventSubscription =
          eventBus.listenForRoom(widget.roomId).listen((event) {
        print('RealtimeChat: Received event ${event.type}');
        if (event.type == MessageEventType.received ||
            event.type == MessageEventType.sent) {
          // Yeni mesaj geldiğinde UI'ın güncellendiğinden emin olmak için (provider notifyListeners() çağrısı varsa Consumer otomatik rebuild olur)
          if (mounted) {
            _scrollToBottom();
          }
        }
      });

      // İlk yüklemeden sonra da aşağı kaydır
      if (mounted) {
        _scrollToBottom();
      }

      _isInitialized = true;
    } catch (e) {
      print('Error initializing chat: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _eventSubscription.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!mounted) return;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      print("Scrolled to bottom");
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      _messageController.clear();

      // Kullanıcı bilgilerini al
      final currentUser =
          Provider.of<AuthProvider>(context, listen: false).currentUser;
      int userId = currentUser?.id ?? -1;
      String username = currentUser?.username ?? 'Ben';

      // Yerel mesaj nesnesi oluşturuluyor
      final localMessage = Message(
        messageId: -999, // Geçici ID
        roomId: widget.roomId,
        userId: userId,
        username: username,
        content: content,
        messageType: 'text',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Yerel mesajı event bus üzerinden yayınla (MessageProvider'ın _addMessageToRoom() çağırıp notifyListeners yapması gerekiyor)
      final eventBus = MessageEventBus();
      eventBus.publish(MessageEvent(
        type: MessageEventType.sent,
        roomId: widget.roomId,
        message: localMessage,
      ));
      print("Local message published via event bus");

      // MessageProvider üzerinden mesajı gönder (bu işlem içinde provider listeneleri güncellemeli)
      await context.read<MessageProvider>().sendMessage(widget.roomId, content);
      print("sendMessage() completed");

      if (mounted) {
        _scrollToBottom();
      }
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mesaj gönderilemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

          final messages =
              messageProvider.getSortedMessagesForRoom(widget.roomId);
          print("UI Message count: ${messages.length}");

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

          return ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final showDate = index == 0 ||
                  !_isSameDay(
                    messages[index - 1].createdAt,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildMessageList()),
        _buildMessageInput(),
      ],
    );
  }
}
