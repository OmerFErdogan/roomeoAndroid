// lib/ui/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roome_android/ui/shared/widgets/modern_room_item.dart';
import '../../../providers/room_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/room.dart';
import '../../shared/widgets/modern_card.dart';
import '../../shared/widgets/modern_button.dart';
import '../../shared/styles/modern_theme.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomProvider>().fetchUserRooms();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundLight,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                title: Row(
                  children: [
                    Text(
                      'Çalışma Odaları',
                      style: ModernTheme.headingStyle.copyWith(fontSize: 24),
                    ),
                  ],
                ),
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    image: DecorationImage(
                      image: AssetImage('assets/images/pattern.png'),
                      opacity: 0.05,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(48),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: ModernTheme.primary,
                    labelColor: ModernTheme.primary,
                    unselectedLabelColor: ModernTheme.textSecondary,
                    tabs: [
                      Tab(text: 'Ana Sayfa'),
                      Tab(text: 'Odalarım'),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.search, color: ModernTheme.primary),
                  onPressed: () {
                    Navigator.pushNamed(context, '/search-rooms');
                  },
                ),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final user = auth.currentUser;
                    final initial = user?.username?[0].toUpperCase() ?? 'U';

                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          // Profil menüsünü göster
                          _showProfileMenu(context, auth);
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: ModernTheme.primary.withOpacity(0.1),
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: ModernTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildHomePage(),
              _buildRoomsPage(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/create-room');
        },
        backgroundColor: ModernTheme.primary,
        label: Text('Oda Oluştur'),
        icon: Icon(Icons.add),
      ),
    );
  }

  Widget _buildHomePage() {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, child) {
        if (roomProvider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ModernTheme.primary),
            ),
          );
        }

        if (roomProvider.error != null) {
          return _buildErrorState(roomProvider);
        }

        return RefreshIndicator(
          onRefresh: () => roomProvider.fetchUserRooms(),
          color: ModernTheme.primary,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Aktif oturum kartı (varsa)
                if (roomProvider.activeRoom != null)
                  _buildActiveSessionCard(roomProvider.activeRoom!),

                // Karşılama kartı
                _buildWelcomeCard(),

                SizedBox(height: 24),

                // İstatistikler
                _buildStatsSection(roomProvider),

                SizedBox(height: 24),

                // Kategoriler
                _buildCategoriesSection(),

                SizedBox(height: 24),

                // Son katılınan odalar
                _buildRecentRooms(roomProvider),

                SizedBox(height: 80), // FloatingActionButton için boşluk
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomsPage() {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, child) {
        if (roomProvider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ModernTheme.primary),
            ),
          );
        }

        if (roomProvider.error != null) {
          return _buildErrorState(roomProvider);
        }

        if (roomProvider.userRooms.isEmpty) {
          return _buildEmptyRoomsState();
        }

        return RefreshIndicator(
          onRefresh: () => roomProvider.fetchUserRooms(),
          color: ModernTheme.primary,
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: roomProvider.userRooms.length,
            itemBuilder: (context, index) {
              final room = roomProvider.userRooms[index];
              final isActive = roomProvider.activeRoom?.roomId == room.roomId;

              return ModernRoomItem(
                room: room,
                isActive: isActive,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/room-detail',
                    arguments: room,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActiveSessionCard(Room room) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: ModernCard(
        padding: EdgeInsets.all(0),
        hasShadow: true,
        highlightColor: ModernTheme.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ModernTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.timer,
                          color: ModernTheme.primary,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aktif Oturum',
                            style: ModernTheme.captionStyle.copyWith(
                              color: ModernTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            room.name,
                            style: ModernTheme.titleStyle,
                          ),
                        ],
                      ),
                      Spacer(),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Canlı',
                              style: ModernTheme.captionStyle.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    room.description,
                    style: ModernTheme.captionStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
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
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: ModernTheme.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${room.participantDisplay} katılımcı',
                        style: ModernTheme.captionStyle,
                      ),
                    ],
                  ),
                  ModernButton(
                    text: 'Devam Et',
                    icon: Icons.login,
                    type: ModernButtonType.primary,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/room-detail',
                        arguments: room,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final username = user?.username ?? 'Arkadaş';

    return ModernCard(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: ModernTheme.primary.withOpacity(0.1),
                child: Text(
                  username[0].toUpperCase(),
                  style: TextStyle(
                    color: ModernTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merhaba, $username!',
                    style: ModernTheme.titleStyle,
                  ),
                  Text(
                    'Bugün ne çalışmak istersin?',
                    style: ModernTheme.captionStyle,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          ModernButton(
            text: 'Oda Bul ve Katıl',
            icon: Icons.search,
            type: ModernButtonType.primary,
            onPressed: () {
              Navigator.pushNamed(context, '/search-rooms');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(RoomProvider roomProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'İstatistikleriniz',
            style: ModernTheme.subheadingStyle.copyWith(fontSize: 18),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Odalar',
                '${roomProvider.userRooms.length}',
                Icons.meeting_room,
                ModernTheme.primary,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Çalışma Süresi',
                '0 saat',
                Icons.timer,
                ModernTheme.secondary,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Arkadaşlar',
                '0',
                Icons.people,
                ModernTheme.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return ModernCard(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: ModernTheme.titleStyle.copyWith(
              fontSize: 20,
              color: color,
            ),
          ),
          Text(
            title,
            style: ModernTheme.captionStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Kategoriler',
            style: ModernTheme.subheadingStyle.copyWith(fontSize: 18),
          ),
        ),
        Container(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildCategoryItem('Matematik', Icons.calculate, Colors.blue),
              _buildCategoryItem('Bilim', Icons.science, Colors.green),
              _buildCategoryItem('Diller', Icons.language, Colors.orange),
              _buildCategoryItem('Sanat', Icons.palette, Colors.purple),
              _buildCategoryItem('Müzik', Icons.music_note, Colors.pink),
              _buildCategoryItem('Tarih', Icons.history, Colors.brown),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String title, IconData icon, Color color) {
    return Container(
      width: 100,
      margin: EdgeInsets.only(right: 12),
      child: ModernCard(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: ModernTheme.captionStyle.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRooms(RoomProvider roomProvider) {
    if (roomProvider.userRooms.isEmpty) {
      return Container();
    }

    // En son 2 odayı göster
    final recentRooms = roomProvider.userRooms.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Son Katıldığınız Odalar',
                style: ModernTheme.subheadingStyle.copyWith(fontSize: 18),
              ),
              TextButton(
                onPressed: () {
                  _tabController.animateTo(1);
                },
                child: Text(
                  'Tümünü Gör',
                  style: TextStyle(
                    color: ModernTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...recentRooms
            .map((room) => ModernRoomItem(
                  room: room,
                  isActive: roomProvider.activeRoom?.roomId == room.roomId,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/room-detail',
                      arguments: room,
                    );
                  },
                ))
            .toList(),
      ],
    );
  }

  Widget _buildErrorState(RoomProvider roomProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: ModernTheme.error,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Bir şeyler yanlış gitti!',
              style: ModernTheme.titleStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              roomProvider.error!,
              style: ModernTheme.bodyStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ModernButton(
              text: 'Tekrar Dene',
              icon: Icons.refresh,
              type: ModernButtonType.primary,
              onPressed: () => roomProvider.fetchUserRooms(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRoomsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.meeting_room_outlined,
              color: ModernTheme.textSecondary,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Henüz hiç odanız yok',
              style: ModernTheme.titleStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Yeni bir oda oluşturun veya mevcut odalara katılın.',
              style: ModernTheme.bodyStyle,
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
            SizedBox(height: 12),
            ModernButton(
              text: 'Odaları Ara',
              icon: Icons.search,
              type: ModernButtonType.outline,
              onPressed: () {
                Navigator.pushNamed(context, '/search-rooms');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, AuthProvider auth) {
    final user = auth.currentUser;
    final username = user?.username ?? 'Kullanıcı';
    final email = user?.email ?? 'E-posta yok';

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ModernTheme.borderRadius),
        ),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: ModernTheme.primary.withOpacity(0.1),
                  child: Text(
                    username[0].toUpperCase(),
                    style: TextStyle(
                      color: ModernTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: ModernTheme.titleStyle,
                      ),
                      Text(
                        email,
                        style: ModernTheme.captionStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            _buildProfileMenuItem(Icons.person, 'Profil', () {
              Navigator.pop(context);
              // Profil sayfasına git
            }),
            _buildProfileMenuItem(Icons.settings, 'Ayarlar', () {
              Navigator.pop(context);
              // Ayarlar sayfasına git
            }),
            _buildProfileMenuItem(Icons.help_outline, 'Yardım', () {
              Navigator.pop(context);
              // Yardım sayfasına git
            }),
            SizedBox(height: 16),
            ModernButton(
              text: 'Çıkış Yap',
              icon: Icons.logout,
              type: ModernButtonType.error,
              onPressed: () {
                Navigator.pop(context);
                auth.logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem(
      IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: ModernTheme.primary),
      title: Text(title, style: ModernTheme.bodyStyle),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
