// lib/ui/shared/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roome_android/ui/shared/widgets/cartoon_button.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../data/models/room.dart';
import '../../screens/rooms/room_detail_screen.dart';
import '../../screens/rooms/create_room_screen.dart';
import '../../screens/rooms/search_room_screen.dart';
import '../styles/cartoon_theme.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Stack(
        children: [
          // Comic background pattern
          _buildComicBackground(),

          // Main content
          Column(
            children: [
              _buildDrawerHeader(context),
              Expanded(
                child: _buildRoomsList(context),
              ),
              _buildDrawerFooter(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComicBackground() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/comic_dots.png'),
          fit: BoxFit.cover,
          opacity: 0.05,
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final username = authProvider.currentUser?.username ?? 'User';
    final email = authProvider.currentUser?.email ?? 'Email';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';

    return Container(
      padding: EdgeInsets.all(CartoonTheme.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.black,
            width: 3,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                // Shadow
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                // Avatar frame
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black,
                      width: 3,
                    ),
                  ),
                ),

                // Avatar content
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.black,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                // Shine effect
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                      ),
                    ),
                  ),
                ),

                // Mini shine
                Positioned(
                  top: 15,
                  right: 20,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Username in comic format
            Stack(
              children: [
                // Shadow
                Positioned(
                  left: 3,
                  top: 3,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      username.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'ComicNeue',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),

                // Username container
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    username.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'ComicNeue',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 6),

            // Email info
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 1,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                email,
                style: TextStyle(
                  fontFamily: 'ComicNeue',
                  fontSize: 12,
                  color: Colors.black,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsList(BuildContext context) {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, child) {
        if (roomProvider.isLoading) {
          return Center(
            child: _buildComicLoadingIndicator(),
          );
        }

        if (roomProvider.error != null) {
          return Center(
            child: _buildComicErrorMessage(context, roomProvider),
          );
        }

        return RefreshIndicator(
          onRefresh: () => roomProvider.fetchUserRooms(),
          color: Colors.black,
          child: ListView.builder(
            padding: EdgeInsets.all(CartoonTheme.defaultPadding),
            itemCount: roomProvider.userRooms.length + 1, // +1 for the header
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildComicSectionHeader(context, 'YOUR STUDY ROOMS');
              }

              final room = roomProvider.userRooms[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildRoomListItem(context, room),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildComicLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Loading icon with comic style shadow
        Stack(
          children: [
            // Shadow
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            // Container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.black,
                  width: 3,
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  strokeWidth: 4,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Loading text
        Stack(
          children: [
            // Shadow
            Positioned(
              left: 2,
              top: 2,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LOADING...',
                  style: TextStyle(
                    fontFamily: 'ComicNeue',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            // Loading text container
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.black,
                  width: 2,
                ),
              ),
              child: Text(
                'LOADING...',
                style: TextStyle(
                  fontFamily: 'ComicNeue',
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComicErrorMessage(
      BuildContext context, RoomProvider roomProvider) {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            offset: Offset(5, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error title
          Stack(
            children: [
              // Title shadow
              Positioned(
                left: 2,
                top: 2,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'OOPS!',
                    style: TextStyle(
                      fontFamily: 'ComicNeue',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Title container
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
                child: Text(
                  'OOPS!',
                  style: TextStyle(
                    fontFamily: 'ComicNeue',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Error message
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black,
                width: 1,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              roomProvider.error!,
              style: TextStyle(
                fontFamily: 'ComicNeue',
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: 16),

          // Retry button
          GestureDetector(
            onTap: () => roomProvider.fetchUserRooms(),
            child: Stack(
              children: [
                // Button shadow
                Positioned(
                  left: 3,
                  top: 3,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 0, // Hidden in shadow
                        ),
                        SizedBox(width: 8),
                        Text(
                          'RETRY',
                          style: TextStyle(
                            fontFamily: 'ComicNeue',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Actual button
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh,
                        color: Colors.black,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'RETRY',
                        style: TextStyle(
                          fontFamily: 'ComicNeue',
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComicSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Stack(
        children: [
          // Shadow
          Positioned(
            left: 3,
            top: 3,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Text(''),
              ),
            ),
          ),

          // Main container
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'ComicNeue',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 1,
                  ),
                ),
                Stack(
                  children: [
                    // Button shadow
                    Positioned(
                      left: 1,
                      top: 1,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Refresh button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black,
                          width: 1.5,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: Colors.black,
                          size: 18,
                        ),
                        onPressed: () {
                          Provider.of<RoomProvider>(context, listen: false)
                              .fetchUserRooms();
                        },
                        tooltip: 'Refresh',
                        constraints: BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        padding: EdgeInsets.zero,
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

  Widget _buildRoomListItem(BuildContext context, Room room) {
    // Make icon different for premium rooms
    final IconData roomIcon = room.isPremium ? Icons.star : Icons.meeting_room;

    return GestureDetector(
      onTap: () {
        // Close drawer first
        Navigator.pop(context);
        // Navigate to room detail
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomDetailScreen(room: room),
          ),
        );
      },
      child: Stack(
        children: [
          // Shadow
          Positioned(
            left: 6,
            top: 6,
            child: Container(
              width: double.infinity,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Room card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                // Left vertical icon indicator
                Container(
                  width: 8,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomLeft: Radius.circular(6),
                    ),
                  ),
                ),

                // Room icon
                Container(
                  width: 60,
                  height: 60,
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Stack(
                      children: [
                        // Icon shadow
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Icon(
                            roomIcon,
                            color: Colors.black.withOpacity(0.3),
                            size: 30,
                          ),
                        ),

                        // Main icon
                        Icon(
                          roomIcon,
                          color: Colors.black,
                          size: 30,
                        ),
                      ],
                    ),
                  ),
                ),

                // Room details
                Expanded(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(0, 10, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Room name
                        Text(
                          room.name.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'ComicNeue',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),

                        // Participant info and private room indicator
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 14,
                              color: Colors.black,
                            ),
                            SizedBox(width: 4),
                            Text(
                              room.participantDisplay,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                            if (room.isPrivate) ...[
                              SizedBox(width: 8),
                              Icon(
                                Icons.lock,
                                size: 14,
                                color: Colors.black,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "PRIVATE",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ],
                        ),

                        SizedBox(height: 6),

                        // Room type
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.black,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            room.roomType.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'ComicNeue',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Entry button
                Container(
                  width: 30,
                  margin: EdgeInsets.only(right: 10),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerFooter(BuildContext context) {
    return Column(
      children: [
        // Zigzag divider
        Container(
          height: 12,
          width: double.infinity,
          child: CustomPaint(
            painter: ZigzagLinePainter(),
          ),
        ),

        Padding(
          padding: EdgeInsets.all(CartoonTheme.defaultPadding),
          child: Column(
            children: [
              _buildComicDrawerButton(
                icon: Icons.add_circle,
                text: 'CREATE NEW ROOM',
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CreateRoomScreen()));
                },
              ),
              SizedBox(height: 16),
              _buildComicDrawerButton(
                icon: Icons.search,
                text: 'SEARCH ROOMS',
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SearchRoomsScreen()));
                },
              ),
              SizedBox(height: 16),
              _buildComicDrawerButton(
                icon: Icons.logout,
                text: 'LOGOUT',
                isDestructive: true,
                onTap: () {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  Navigator.pop(context); // Close drawer
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildComicDrawerButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Shadow
          Positioned(
            left: 5,
            top: 5,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Main button
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isDestructive ? Colors.black : Colors.black,
                  size: 22,
                ),
                SizedBox(width: 10),
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'ComicNeue',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDestructive ? Colors.black : Colors.black,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Small action indicator
          if (isDestructive)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
              ),
            ),

          // Highlight effect
          Positioned(
            top: 6,
            left: 10,
            child: Container(
              width: 15,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Zigzag line painter
class ZigzagLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final segmentWidth = 10.0;
    final zigHeight = 6.0;
    final width = size.width;

    path.moveTo(0, zigHeight);

    for (double i = 0; i < width; i += segmentWidth) {
      path.lineTo(i + (segmentWidth / 2), 0);
      path.lineTo(i + segmentWidth, zigHeight);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
