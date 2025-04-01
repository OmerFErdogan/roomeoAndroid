import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roome_android/ui/shared/widgets/message_bubble.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../data/models/message.dart';
import '../../../providers/message_provider.dart';

class RoomChat extends StatefulWidget {
  final int roomId;

  const RoomChat({Key? key, required this.roomId}) : super(key: key);

  @override
  _RoomChatState createState() => _RoomChatState();
}

class _RoomChatState extends State<RoomChat> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  WebSocketChannel? _channel;
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    final wsUrl = Uri.parse(
      'ws://localhost:8081/api/rooms/${widget.roomId}/ws?token=$token',
    );

    _channel = WebSocketChannel.connect(wsUrl);
    _isConnected = true;

    _channel?.stream.listen(
      _handleWebSocketMessage,
      onError: (error) {
        print('WebSocket Error: $error');
        _isConnected = false;
        Future.delayed(Duration(seconds: 5), _connectWebSocket);
      },
      onDone: () {
        print('WebSocket connection closed');
        _isConnected = false;
        Future.delayed(Duration(seconds: 5), _connectWebSocket);
      },
    );
  }

  void _handleWebSocketMessage(dynamic data) {
    if (!mounted) return;

    try {
      if (data is String) {
        if (data.contains('joined the room') ||
            data.contains('left the room')) {
          final username = data.split(' ')[0];
          // Sadece bağlantı aktifse system mesajı göster
          if (_isConnected) {
            context.read<MessageProvider>().addWebSocketMessage(
                  widget.roomId,
                  Message.system(
                    roomId: widget.roomId,
                    content: data,
                    userId: 0,
                    username: username,
                  ),
                );
          }
          return;
        }

        final jsonData = jsonDecode(data);
        if (jsonData is Map<String, dynamic>) {
          final message = Message.fromJson(jsonData);
          context.read<MessageProvider>().addWebSocketMessage(
                widget.roomId,
                message,
              );
          _scrollToBottom();
        }
      }
    } catch (e) {
      print('Error processing WebSocket message: $e');
    }
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
      ),
      child: Column(
        children: [
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, messageProvider, child) {
                if (messageProvider.isLoadingForRoom(widget.roomId)) {
                  return Center(child: CircularProgressIndicator());
                }

                // Mesajları tarihe göre sırala
                final messages = messageProvider
                    .getMessagesForRoom(widget.roomId)
                  ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final showDate = index == 0 ||
                        !_isSameDay(
                            messages[index - 1].createdAt, message.createdAt);

                    return Column(
                      children: [
                        if (showDate) _buildDateDivider(message.createdAt),
                        MessageBubble(
                          message: message,
                          displayTime: message.createdAt.toLocal(),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
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
            child: Text(
              _formatDate(date),
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(child: Divider()),
        ],
      ),
    );
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
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
    super.dispose();
  }
}
