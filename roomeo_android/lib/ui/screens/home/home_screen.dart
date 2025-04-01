// lib/ui/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roome_android/ui/shared/widgets/cartoon_button.dart';
import '../../../providers/room_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/room.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/cartoon_card.dart';
import '../../shared/styles/cartoon_theme.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomProvider>().fetchUserRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CartoonTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Study Rooms',
          style: CartoonTheme.subheadingStyle,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: CartoonTheme.primary,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/search-rooms');
            },
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: Consumer<RoomProvider>(
        builder: (context, roomProvider, child) {
          if (roomProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(CartoonTheme.primary),
              ),
            );
          }

          if (roomProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Consider adding a cartoon error image here
                  // Image.asset('assets/images/error.png', height: 120),
                  SizedBox(height: 20),
                  Text(
                    'Oops!',
                    style: CartoonTheme.headingStyle,
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      roomProvider.error!,
                      style: CartoonTheme.captionStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 20),
                  CartoonButton(
                    text: 'Try Again',
                    icon: Icons.refresh,
                    width: 140,
                    onPressed: () => roomProvider.fetchUserRooms(),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => roomProvider.fetchUserRooms(),
            color: CartoonTheme.primary,
            child: CustomScrollView(
              slivers: [
                // Show active session card if there's an active room
                if (roomProvider.activeRoom != null &&
                    roomProvider.activeRoom!.isActive)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _buildActiveSessionCard(roomProvider.activeRoom!),
                    ),
                  ),

                // Display welcome section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: _buildWelcomeCard(context),
                  ),
                ),

                // Display stats section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _buildStatsCard(context, roomProvider),
                  ),
                ),

                // Quick Actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _buildQuickActions(context),
                  ),
                ),

                // Additional content (can be expanded later)
                SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-room');
        },
        backgroundColor: CartoonTheme.secondary,
        child: Icon(Icons.add, color: CartoonTheme.textPrimary),
        tooltip: 'Create Room',
        elevation: 4,
      ),
    );
  }

  Widget _buildActiveSessionCard(Room room) {
    return CartoonCard(
      backgroundColor: CartoonTheme.primary.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CartoonTheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.timer,
                  color: CartoonTheme.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Session',
                      style: CartoonTheme.captionStyle.copyWith(
                        color: CartoonTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      room.name,
                      style: CartoonTheme.bodyStyle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(CartoonTheme.smallBorderRadius),
                  border: Border.all(
                    color: Colors.green,
                    width: 1.5,
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
                      'Live',
                      style: CartoonTheme.captionStyle.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${room.participantDisplay} participants',
                style: CartoonTheme.captionStyle,
              ),
              CartoonButton(
                text: 'Continue',
                icon: Icons.play_arrow,
                width: 110,
                color: CartoonTheme.primary,
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
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final username = user?.username ?? 'Friend';

    return CartoonCard(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CartoonTheme.secondary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_emotions,
                  color: CartoonTheme.secondary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hi, $username!',
                  style: CartoonTheme.subheadingStyle,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Ready for a productive study session? Join a room or create your own to connect with fellow learners!',
            style: CartoonTheme.bodyStyle,
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CartoonButton(
                  text: 'Create Room',
                  icon: Icons.add,
                  color: CartoonTheme.secondary,
                  textColor: CartoonTheme.textPrimary,
                  onPressed: () {
                    Navigator.pushNamed(context, '/create-room');
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: CartoonButton(
                  text: 'Find Rooms',
                  icon: Icons.search,
                  isOutlined: true,
                  color: CartoonTheme.secondary,
                  onPressed: () {
                    Navigator.pushNamed(context, '/search-rooms');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, RoomProvider roomProvider) {
    return CartoonCard(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CartoonTheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bar_chart,
                  color: CartoonTheme.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your Study Stats',
                  style: CartoonTheme.subheadingStyle,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.meeting_room,
                value: '${roomProvider.userRooms.length}',
                label: 'Rooms',
                iconColor: CartoonTheme.primary,
              ),
              _buildStatItem(
                icon: Icons.timer,
                value: '0h',
                label: 'Study Time',
                iconColor: CartoonTheme.secondary,
              ),
              _buildStatItem(
                icon: Icons.people,
                value: '0',
                label: 'Friends',
                iconColor: CartoonTheme.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return CartoonCard(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CartoonTheme.accent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.flash_on,
                  color: CartoonTheme.accent,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Quick Actions',
                  style: CartoonTheme.subheadingStyle,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickActionItem(
                icon: Icons.add_circle,
                label: 'New Room',
                color: CartoonTheme.primary,
                onTap: () {
                  Navigator.pushNamed(context, '/create-room');
                },
              ),
              _buildQuickActionItem(
                icon: Icons.search,
                label: 'Search',
                color: CartoonTheme.secondary,
                onTap: () {
                  Navigator.pushNamed(context, '/search-rooms');
                },
              ),
              _buildQuickActionItem(
                icon: Icons.people,
                label: 'Friends',
                color: CartoonTheme.accent,
                onTap: () {
                  // Navigate to friends screen when implemented
                },
              ),
              _buildQuickActionItem(
                icon: Icons.settings,
                label: 'Settings',
                color: CartoonTheme.textSecondary,
                onTap: () {
                  // Navigate to settings screen when implemented
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: CartoonTheme.headingStyle.copyWith(
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: CartoonTheme.captionStyle,
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CartoonTheme.borderRadius),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
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
            SizedBox(height: 8),
            Text(
              label,
              style: CartoonTheme.captionStyle.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
