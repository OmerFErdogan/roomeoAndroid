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
import '../../../core/utils/message_event_bus.dart';
import '../../shared/styles/modern_theme.dart';
import '../../shared/widgets/modern_button.dart';
import '../chat/realtime_chat.dart';

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
  late TabController _tabController;
  Timer? _autoRefreshTimer;
  bool _isExiting = false;
  bool _isLoading = false;
  StreamSubscription<MessageEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // İlk yüklemede odaya giriş yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRoom();
    });

    // Event Bus'ı dinle - sadece katılımcı güncellemeleri için
    final eventBus = MessageEventBus();
    _eventSubscription =
        eventBus.listenForRoom(widget.room.roomId).listen((event) {
      if (mounted) {
        // Katılımcı güncellemesi gerektiğinde
        if (event.type == MessageEventType.userJoined ||
            event.type == MessageEventType.userLeft ||
            event.type == MessageEventType.roomUpdated) {
          _refreshRoomData();
        }

        // NOT: Mesaj olaylarıyla ilgili işlemler RealtimeChat widget'ında yapılıyor!
        // Mesaj scroll işlemlerini burada yapmıyoruz.
      }
    });

    // Periyodik olarak oda bilgilerini güncelle (özellikle katılımcı sayısı için)
    _autoRefreshTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (mounted) {
        _refreshRoomData();
      }
    });
  }

  Future<void> _initializeRoom() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Odaya giriş yap
      await context.read<RoomProvider>().enterRoom(widget.room.roomId);

      // Mesajları yükle
      await context.read<MessageProvider>().loadMessages(widget.room.roomId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Odaya bağlanırken hata oluştu: $e'),
            backgroundColor: ModernTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

  @override
  void dispose() {
    _tabController.dispose();
    _autoRefreshTimer?.cancel();
    _eventSubscription?.cancel();

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
        child: _isLoading
            ? _buildLoadingState()
            : Column(
                children: [
                  _buildRoomHeader(),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft:
                              Radius.circular(ModernTheme.borderRadius * 2),
                          topRight:
                              Radius.circular(ModernTheme.borderRadius * 2),
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
                          topLeft:
                              Radius.circular(ModernTheme.borderRadius * 2),
                          topRight:
                              Radius.circular(ModernTheme.borderRadius * 2),
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
                                  RealtimeChat(roomId: widget.room.roomId),

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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ModernTheme.primary),
          ),
          SizedBox(height: 16),
          Text(
            'Oda yükleniyor...',
            style: ModernTheme.bodyStyle,
          ),
        ],
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

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
