// lib/ui/screens/rooms/room_detail_screen.dart
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../data/models/room.dart';
import '../../../data/models/room_participant.dart';
import '../../../data/models/message.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../providers/message_provider.dart';
import '../../shared/styles/modern_theme.dart';
import '../../shared/widgets/modern_button.dart';

class RoomDetailScreen extends StatefulWidget {
  final Room room;

  const RoomDetailScreen({
    Key? key,
    required this.room,
  }) : super(key: key);

  @override
  _RoomDetailScreenState createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isExpanded = false;
  bool _isExiting = false;
  late TabController _tabController;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // İlk yüklemede odaya giriş yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRoom();
    });

    // Periyodik olarak oda bilgilerini güncelle (özellikle katılımcı sayısı için)
    _autoRefreshTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (mounted) {
        _refreshRoomData();
      }
    });
  }

  Future<void> _initializeRoom() async {
    try {
      // Odaya giriş yap
      await context.read<RoomProvider>().enterRoom(widget.room.roomId);

      // Mesajları yükle
      await context.read<MessageProvider>().loadMessages(widget.room.roomId);

      // Sayfa yüklendikten sonra otomatik olarak aşağı kaydır
      Future.delayed(Duration(milliseconds: 500), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Odaya bağlanırken hata oluştu: $e'),
            backgroundColor: ModernTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _refreshRoomData() async {
    try {
      // Katılımcı listesini güncelle
      await context
          .read<RoomProvider>()
          .fetchRoomParticipants(widget.room.roomId);
    } catch (e) {
      print('Oda verileri güncellenemedi: $e');
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
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    _autoRefreshTimer?.cancel();

    // Sayfa kapanırken odadan çık
    if (!_isExiting) {
      context.read<RoomProvider>().exitRoom(widget.room.roomId);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildRoomHeader(),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(ModernTheme.borderRadius * 2),
                    topRight: Radius.circular(ModernTheme.borderRadius * 2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: Offset(0, -2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(ModernTheme.borderRadius * 2),
                    topRight: Radius.circular(ModernTheme.borderRadius * 2),
                  ),
                  child: Column(
                    children: [
                      // Tab Bar
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: ModernTheme.primary,
                          labelColor: ModernTheme.primary,
                          unselectedLabelColor: ModernTheme.textSecondary,
                          tabs: [
                            Tab(text: 'Sohbet'),
                            Tab(text: 'Katılımcılar'),
                          ],
                        ),
                      ),

                      // Tab İçerikleri
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Sohbet Sekmesi
                            Column(
                              children: [
                                Expanded(
                                  child: _buildChatSection(),
                                ),
                                _buildMessageInput(),
                              ],
                            ),

                            // Katılımcılar Sekmesi
                            _buildParticipantsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomHeader() {
    // RoomProvider'dan güncel oda bilgisini al
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, _) {
        // Odayı bul - ya aktif oda, ya da oda listesinden
        final currentRoom =
            roomProvider.activeRoom?.roomId == widget.room.roomId
                ? roomProvider.activeRoom
                : roomProvider.userRooms.firstWhereOrNull(
                      (r) => r.roomId == widget.room.roomId,
                    ) ??
                    widget.room;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon:
                        Icon(Icons.arrow_back_ios, color: ModernTheme.primary),
                    onPressed: () {
                      _isExiting = true;
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentRoom!.name,
                          style: ModernTheme.titleStyle.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentRoom.description,
                          style: ModernTheme.captionStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: currentRoom.isPremium
                          ? ModernTheme.warning.withOpacity(0.1)
                          : ModernTheme.primary.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(ModernTheme.smallBorderRadius),
                    ),
                    child: Text(
                      currentRoom.roomType.toUpperCase(),
                      style: ModernTheme.chipTextStyle.copyWith(
                        color: currentRoom.isPremium
                            ? ModernTheme.warning
                            : ModernTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoItem(
                    icon: Icons.people,
                    label: 'Katılımcılar',
                    value:
                        '${currentRoom.currentParticipants}/${currentRoom.maxParticipants}',
                  ),
                  _buildInfoItem(
                    icon: Icons.access_time,
                    label: 'Oluşturulma',
                    value: _formatDate(currentRoom.createdAt),
                  ),
                  _buildInfoItem(
                    icon: currentRoom.isPrivate ? Icons.lock : Icons.public,
                    label: 'Oda Tipi',
                    value: currentRoom.isPrivate ? 'Özel' : 'Genel',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ModernTheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: ModernTheme.primary, size: 20),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: ModernTheme.bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: ModernTheme.captionStyle.copyWith(
            color: ModernTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsTab() {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, _) {
        final participants =
            roomProvider.getParticipantsForRoom(widget.room.roomId);

        if (participants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: ModernTheme.textSecondary.withOpacity(0.5),
                ),
                SizedBox(height: 16),
                Text(
                  'Henüz aktif katılımcı yok',
                  style: ModernTheme.titleStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Oda Katılımcıları (${participants.length})',
                style: ModernTheme.titleStyle.copyWith(fontSize: 18),
              ),
              SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final participant = participants[index];
                    return _buildParticipantItem(participant);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticipantItem(RoomParticipant participant) {
    final currentUser = context.read<AuthProvider>().currentUser;
    final isCurrentUser = participant.userId == currentUser?.id;

    // Rol için renk belirle
    final Color roleColor = _getRoleColor(participant.role);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ModernTheme.borderRadius),
        boxShadow:
            isCurrentUser ? ModernTheme.defaultShadow : ModernTheme.lightShadow,
        border: isCurrentUser
            ? Border.all(color: ModernTheme.primary, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: ModernTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    participant.username[0].toUpperCase(),
                    style: TextStyle(
                      color: ModernTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),

              // Rol göstergesi
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: roleColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            participant.username,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatRole(participant.role),
              style: TextStyle(
                fontSize: 10,
                color: roleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return ModernTheme.warning;
      case 'admin':
        return ModernTheme.accent;
      default:
        return ModernTheme.primary;
    }
  }

  String _formatRole(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return 'Oda Sahibi';
      case 'admin':
        return 'Yönetici';
      default:
        return 'Üye';
    }
  }

  Widget _buildChatSection() {
    return Container(
      color: ModernTheme.backgroundLight,
      child: Consumer<MessageProvider>(
        builder: (context, messageProvider, child) {
          if (messageProvider.isLoadingForRoom(widget.room.roomId)) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ModernTheme.primary),
              ),
            );
          }

          final messages =
              messageProvider.getMessagesForRoom(widget.room.roomId);

          if (messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: ModernTheme.textSecondary.withOpacity(0.5),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Henüz mesaj yok',
                    style: ModernTheme.titleStyle,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'İlk mesajı sen gönder!',
                    style: ModernTheme.captionStyle,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Mesajları tarihe göre sırala - ÖNEMLİ!
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
                  _buildMessageBubble(message),
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

  Widget _buildMessageBubble(Message message) {
    // Mesaj sahibini kontrol et
    final currentUser = context.read<AuthProvider>().currentUser;
    final isCurrentUser = message.userId == currentUser?.id;
    final isSystemMessage = message.messageType == 'system';

    if (isSystemMessage) {
      return _buildSystemMessage(message);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) _buildMessageAvatar(message),
          SizedBox(width: !isCurrentUser ? 8 : 0),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
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
                Text(
                  message.content,
                  style: TextStyle(
                    color:
                        isCurrentUser ? Colors.white : ModernTheme.textPrimary,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    _formatTime(message.createdAt),
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
          ),
        ],
      ),
    );
  }

  Widget _buildMessageAvatar(Message message) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: ModernTheme.primary.withOpacity(0.1),
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

  Widget _buildSystemMessage(Message message) {
    return Container(
      width: double.infinity,
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
      child: SafeArea(
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
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ModernTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      await context.read<MessageProvider>().sendMessage(
            widget.room.roomId,
            content,
          );
      _messageController.clear();

      // Mesaj gönderildikten sonra otomatik olarak aşağı kaydır
      Future.delayed(Duration(milliseconds: 300), _scrollToBottom);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mesaj gönderilemedi: $e'),
          backgroundColor: ModernTheme.error,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
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
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatTime(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
