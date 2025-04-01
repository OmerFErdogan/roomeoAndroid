// lib/ui/screens/rooms/search_room_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/room_provider.dart';
import '../../../data/models/room.dart';
import '../../../core/error/exceptions.dart';
import '../../shared/styles/modern_theme.dart';
import '../../shared/widgets/modern_button.dart';

class SearchRoomsScreen extends StatefulWidget {
  const SearchRoomsScreen({Key? key}) : super(key: key);

  @override
  _SearchRoomsScreenState createState() => _SearchRoomsScreenState();
}

class _SearchRoomsScreenState extends State<SearchRoomsScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  List<Room> _searchResults = [];
  String? _selectedFilter;
  bool _showOnlyAvailable = false;

  final List<String> _filters = [
    'Tümü',
    'Normal',
    'Premium',
    'Genel',
    'Özel',
  ];

  @override
  void initState() {
    super.initState();
    _selectedFilter = _filters[0];

    // İlk açılışta genel arama yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchRooms('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Oda Ara',
          style: ModernTheme.titleStyle,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: ModernTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          _buildFilterSection(),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: ModernTheme.backgroundLight,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: ModernTheme.borderColor),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Oda ara...',
                prefixIcon: Icon(Icons.search, color: ModernTheme.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon:
                            Icon(Icons.clear, color: ModernTheme.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          _searchRooms('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: _searchRooms,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ModernTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_searchResults.length} oda bulundu',
                  style: ModernTheme.captionStyle.copyWith(
                    color: ModernTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Spacer(),
              Row(
                children: [
                  Text(
                    'Sadece Müsait Odalar',
                    style: ModernTheme.captionStyle,
                  ),
                  Switch(
                    value: _showOnlyAvailable,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyAvailable = value;
                        // Mevcut arama sonuçlarını filtrele
                        _filterResults();
                      });
                    },
                    activeColor: ModernTheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      height: 50,
      color: Colors.white,
      padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                    _filterResults();
                  });
                }
              },
              selectedColor: ModernTheme.primary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : ModernTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color:
                      isSelected ? Colors.transparent : ModernTheme.borderColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ModernTheme.primary),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: ModernTheme.error,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Arama sırasında bir hata oluştu',
              style: ModernTheme.titleStyle,
            ),
            SizedBox(height: 8),
            Text(
              _error!,
              style: ModernTheme.captionStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ModernButton(
              text: 'Tekrar Dene',
              icon: Icons.refresh,
              type: ModernButtonType.primary,
              onPressed: () => _searchRooms(_searchController.text),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: ModernTheme.textSecondary.withOpacity(0.5),
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Hiç oda bulunamadı',
              style: ModernTheme.titleStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Farklı anahtar kelimelerle tekrar arayın veya kendi odanızı oluşturun',
              style: ModernTheme.captionStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ModernButton(
              text: 'Oda Oluştur',
              icon: Icons.add,
              type: ModernButtonType.primary,
              onPressed: () {
                Navigator.pushNamed(context, '/create-room');
              },
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final room = _searchResults[index];
        return _RoomSearchItem(
          room: room,
          onJoin: (accessCode) => _joinRoom(room, accessCode),
        );
      },
    );
  }

  Future<void> _searchRooms(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rooms = await context.read<RoomProvider>().searchRooms(query);
      setState(() {
        _searchResults = rooms;
        _isLoading = false;
        _filterResults(); // Filtreleri uygula
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterResults() {
    if (_selectedFilter == 'Tümü' && !_showOnlyAvailable) {
      return; // Filtreleme yapma
    }

    final List<Room> filteredResults = [];

    for (final room in _searchResults) {
      // Sadece müsait odalar filtresini uygula
      if (_showOnlyAvailable && room.isFull) {
        continue;
      }

      // Seçili filtreyi uygula
      switch (_selectedFilter) {
        case 'Normal':
          if (room.roomType != 'normal') continue;
          break;
        case 'Premium':
          if (room.roomType != 'premium') continue;
          break;
        case 'Genel':
          if (room.isPrivate) continue;
          break;
        case 'Özel':
          if (!room.isPrivate) continue;
          break;
      }

      filteredResults.add(room);
    }

    setState(() {
      _searchResults = filteredResults;
    });
  }

  Future<void> _joinRoom(Room room, String? accessCode) async {
    try {
      setState(() => _isLoading = true);

      if (room.isPrivate && (accessCode == null || accessCode.isEmpty)) {
        throw ValidationException('Özel odalar için erişim kodu gereklidir');
      }

      await context.read<RoomProvider>().joinRoom(
            room.roomId,
            accessCode: accessCode,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Oda başarıyla katıldınız'),
          backgroundColor: ModernTheme.success,
        ),
      );

      Navigator.pop(context); // Arama ekranını kapat
    } catch (e) {
      String errorMessage = e.toString();
      if (e is ValidationException) {
        errorMessage = e.message;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: ModernTheme.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _RoomSearchItem extends StatelessWidget {
  final Room room;
  final Function(String?) onJoin;

  const _RoomSearchItem({
    Key? key,
    required this.room,
    required this.onJoin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ModernTheme.borderRadius),
        boxShadow: ModernTheme.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoomHeader(context),
          _buildRoomContent(context),
          _buildRoomFooter(context),
        ],
      ),
    );
  }

  Widget _buildRoomHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ModernTheme.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: room.isPremium
                  ? ModernTheme.warning.withOpacity(0.1)
                  : ModernTheme.primary.withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(ModernTheme.smallBorderRadius),
            ),
            child: Icon(
              room.isPremium ? Icons.star : Icons.meeting_room,
              color: room.isPremium ? ModernTheme.warning : ModernTheme.primary,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: ModernTheme.titleStyle.copyWith(
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: room.isPremium
                            ? ModernTheme.warning.withOpacity(0.1)
                            : ModernTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        room.roomType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: room.isPremium
                              ? ModernTheme.warning
                              : ModernTheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    if (room.isPrivate)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 10, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              'ÖZEL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            room.description,
            style: ModernTheme.bodyStyle.copyWith(
              color: ModernTheme.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                Icons.people,
                '${room.currentParticipants}/${room.maxParticipants}',
                'Katılımcılar',
              ),
              _buildInfoItem(
                Icons.calendar_today,
                _formatDate(room.createdAt),
                'Oluşturulma',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ModernTheme.backgroundLight,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(ModernTheme.borderRadius),
          bottomRight: Radius.circular(ModernTheme.borderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Kapasite durumu
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getCapacityColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getCapacityColor().withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              _getCapacityText(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getCapacityColor(),
              ),
            ),
          ),
          if (!room.isFull)
            ModernButton(
              text: room.isPrivate ? 'Kod Gir & Katıl' : 'Katıl',
              icon: room.isPrivate ? Icons.vpn_key : Icons.login,
              type: room.isPrivate
                  ? ModernButtonType.secondary
                  : ModernButtonType.primary,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onPressed: () => _handleJoinTap(context),
            )
          else
            Text(
              'Oda Dolu',
              style: ModernTheme.captionStyle.copyWith(
                color: ModernTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: ModernTheme.textSecondary,
        ),
        SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: ModernTheme.captionStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: ModernTheme.textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: ModernTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleJoinTap(BuildContext context) {
    if (room.isPrivate) {
      _showAccessCodeDialog(context);
    } else {
      onJoin(null);
    }
  }

  void _showAccessCodeDialog(BuildContext context) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Erişim Kodu Gir',
          style: ModernTheme.titleStyle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bu özel bir oda. Erişim kodunu girerek katılabilirsiniz.',
              style: ModernTheme.bodyStyle,
            ),
            SizedBox(height: 24),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Erişim Kodu',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ModernTheme.borderRadius),
                ),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
              autofocus: true,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context, value);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context, code);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ModernTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Katıl'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernTheme.borderRadius),
        ),
      ),
    ).then((code) {
      if (code != null && code.isNotEmpty) {
        onJoin(code);
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getCapacityText() {
    if (room.isFull) {
      return 'Dolu';
    } else if (room.currentParticipants >= room.maxParticipants * 0.8) {
      return 'Az Yer Kaldı';
    } else {
      return 'Müsait';
    }
  }

  Color _getCapacityColor() {
    if (room.isFull) {
      return ModernTheme.error;
    } else if (room.currentParticipants >= room.maxParticipants * 0.8) {
      return ModernTheme.warning;
    } else {
      return ModernTheme.success;
    }
  }
}
