// lib/ui/screens/chat/realtime_chat.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart'; // Add this dependency to pubspec.yaml
import '../../../data/models/message.dart';
import '../../../providers/message_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/message_event_bus.dart';
import '../../shared/widgets/modern_message_bubble.dart';
import '../../shared/styles/modern_theme.dart';

/// A model for pending messages with client ID
class PendingMessage {
  final String clientId;
  final Message message;
  final DateTime sentAt;

  PendingMessage(
      {required this.clientId, required this.message, required this.sentAt});
}

class RealtimeChat extends StatefulWidget {
  final int roomId;

  const RealtimeChat({
    Key? key,
    required this.roomId,
  }) : super(key: key);

  @override
  _RealtimeChatState createState() => _RealtimeChatState();
}

class _RealtimeChatState extends State<RealtimeChat>
    with AutomaticKeepAliveClientMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription<MessageEvent>? _eventSubscription;
  Timer? _refreshTimer;
  bool _isInitialized = false;

  // Track pending messages with their client IDs
  final Map<String, PendingMessage> _pendingMessages = {};

  // For generating UUIDs
  final _uuid = Uuid();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Initialize after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    if (_isInitialized) return;

    final messageProvider = context.read<MessageProvider>();

    try {
      // Load existing messages
      await messageProvider.loadAllMessages(widget.roomId);
      print(
          "Messages loaded: ${messageProvider.getSortedMessagesForRoom(widget.roomId).length}");

      // Set up EventBus listener
      final eventBus = MessageEventBus();
      _eventSubscription =
          eventBus.listenForRoom(widget.roomId).listen((event) {
        print(
            'RealtimeChat: Received event ${event.type} for room ${widget.roomId}');

        if (event.type == MessageEventType.received ||
            event.type == MessageEventType.sent) {
          if (mounted && event.message != null) {
            // Mesajı doğrudan kullan, içerik temizlemeye gerek yok
            final message = event.message!;

            // ClientId özelliğinden yararlan, mesaj içeriğini kurcalama
            if (message.clientId != null && _pendingMessages.containsKey(message.clientId)) {
              setState(() {
                _pendingMessages.remove(message.clientId);
                print('Removed pending message with clientId: ${message.clientId}');
              });
            }
          }

          // Update UI and scroll
          if (mounted) {
            setState(() {});
            _scrollToBottom();
          }
        }
      });

      // Initial scroll
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) _scrollToBottom();
      });

      // Set up periodic refresh - every 2 seconds to be more reasonable
      _refreshTimer = Timer.periodic(Duration(seconds: 2), (_) {
        if (!mounted) return;

        messageProvider.refreshMessages(widget.roomId).then((_) {
          if (!mounted) return;

          // Process server messages to find any that match our pending messages
          final messages =
              messageProvider.getSortedMessagesForRoom(widget.roomId);

          // Check for any recently confirmed messages that might match our pending ones
          if (_pendingMessages.isNotEmpty) {
            setState(() {
              // Clean up any pending messages older than 5 minutes
              // This prevents accumulation of "orphaned" pending messages
              final now = DateTime.now();
              _pendingMessages.removeWhere((clientId, pending) =>
                  now.difference(pending.sentAt).inMinutes > 5);
            });
          }

          setState(() {});

          // Auto scroll if needed
          if (_shouldAutoScroll()) {
            _scrollToBottom();
          }
        });
      });

      _isInitialized = true;
    } catch (e) {
      print('Error initializing chat: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _eventSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  bool _shouldAutoScroll() {
    if (!_scrollController.hasClients) return true;

    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;
    return (maxScroll - currentScroll) <= 150.0;
  }

  void _scrollToBottom() {
    if (!mounted || !_scrollController.hasClients) return;

    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      // Clear input field immediately
      _messageController.clear();

      // Get user info
      final currentUser =
          Provider.of<AuthProvider>(context, listen: false).currentUser;
      final userId = currentUser?.id ?? -1;
      final username = currentUser?.username ?? 'Ben';

      // Generate a proper UUID for client ID
      final clientId = _uuid.v4(); // Generates a UUIDv4

      // Create local message with temporary ID
      final localMessage = Message(
        messageId: -DateTime.now().millisecondsSinceEpoch,
        roomId: widget.roomId,
        userId: userId,
        username: username,
        content: content,
        messageType: 'text',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        clientId: clientId, // Doğrudan clientId'yi Message nesnesine ekle
      );

      // Store in pending messages map
      final pendingMessage = PendingMessage(
          clientId: clientId, message: localMessage, sentAt: DateTime.now());

      // Update UI
      setState(() {
        _pendingMessages[clientId] = pendingMessage;
      });

      // Scroll to show new message
      _scrollToBottom();

      // Doğrudan sendMessageWithClientId metodunu kullan
      await context.read<MessageProvider>().sendMessageWithClientId(
            widget.roomId,
            content,
            clientId,
            userId: userId,
            username: username,
          );
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj gönderilemedi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        Expanded(child: _buildMessageList()),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageList() {
    return Container(
      color: ModernTheme.backgroundLight,
      child: Consumer<MessageProvider>(
        builder: (context, messageProvider, child) {
          if (messageProvider.isLoadingForRoom(widget.roomId) &&
              _pendingMessages.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ModernTheme.primary),
              ),
            );
          }

          // Get server messages
          final serverMessages =
              messageProvider.getSortedMessagesForRoom(widget.roomId);

          // Filter out system messages for the current user if needed
          final currentUser =
              Provider.of<AuthProvider>(context, listen: false).currentUser;
          final filteredMessages = serverMessages.where((msg) {
            if (msg.messageType == 'system' && currentUser != null) {
              if ((msg.content.contains("joined the room") ||
                      msg.content.contains("left the room")) &&
                  msg.userId == currentUser.id) {
                return false; // Filter out join/leave messages for current user
              }
            }
            
            return true;
          }).toList();

          // Create list of all messages to display
          final List<Message> displayMessages = [...filteredMessages];

          // Create set of server message IDs to avoid duplicates
          final Set<int> serverIds =
              filteredMessages.map((m) => m.messageId).toSet();
          
          // Create set of clientIds to avoid duplicates
          final Set<String?> serverClientIds = filteredMessages
              .where((m) => m.clientId != null)
              .map((m) => m.clientId)
              .toSet();

          // Add pending messages that don't have matching server IDs or clientIds
          for (final pending in _pendingMessages.values) {
            // Sadece clientId kontrolü yap - daha güvenilir
            if (!serverClientIds.contains(pending.clientId)) {
              displayMessages.add(pending.message);
            }
          }

          // Sort by timestamp
          displayMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

          if (displayMessages.isEmpty) {
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
            itemCount: displayMessages.length,
            itemBuilder: (context, index) {
              final message = displayMessages[index];
              final showDate = index == 0 ||
                  !_isSameDay(
                    displayMessages[index - 1].createdAt,
                    message.createdAt,
                  );

              // Check if message is pending
              final isPending = message.messageId < 0;

              return Column(
                children: [
                  if (showDate) _buildDateDivider(message.createdAt),
                  Stack(
                    children: [
                      ModernMessageBubble(
                        message: message,
                        displayTime: message.createdAt,
                      ),
                      if (isPending)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ModernTheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
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
}
