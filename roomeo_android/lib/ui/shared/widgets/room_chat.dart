import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../data/models/message.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/message_provider.dart';
import 'message_bubble.dart';

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

  @override
  void initState() {
    super.initState();
    // Build sonrası çağrılacak
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    await context.read<MessageProvider>().loadMessages(widget.roomId);
    _connectWebSocket();
  }

  void _handleWebSocketMessage(dynamic data) {
    if (!mounted) return; // Widget dispose edilmişse işlem yapma

    try {
      if (data is String) {
        if (data.contains('joined the room') ||
            data.contains('left the room')) {
          final username = data.split(' ')[0];
          if (mounted) {
            // Tekrar kontrol et
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
          if (mounted) {
            // Son kez kontrol et
            context.read<MessageProvider>().addWebSocketMessage(
                  widget.roomId,
                  message,
                );
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      print('Error processing WebSocket message: $e');
      print('Raw message data: $data');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    // WebSocket bağlantısını temiz bir şekilde kapat
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }

    super.dispose();
  }

  void _connectWebSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    final wsUrl = Uri.parse(
      'ws://localhost:8081/api/rooms/${widget.roomId}/ws?token=$token',
    );

    _channel = WebSocketChannel.connect(wsUrl);
    _channel?.stream.listen(
      _handleWebSocketMessage,
      onError: (error) {
        print('WebSocket Error: $error');
      },
      onDone: () {
        print('WebSocket connection closed');
        Future.delayed(Duration(seconds: 5), _connectWebSocket);
      },
    );
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
          child: Consumer<MessageProvider>(
            builder: (context, messageProvider, child) {
              if (messageProvider.isLoadingForRoom(widget.roomId)) {
                return Center(child: CircularProgressIndicator());
              }

              final messages =
                  messageProvider.getMessagesForRoom(widget.roomId);

              return ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return MessageBubble(message: message);
                },
              );
            },
          ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -2),
            blurRadius: 4,
            color: Colors.black12,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _sendMessage,
            color: Theme.of(context).primaryColor,
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
}
