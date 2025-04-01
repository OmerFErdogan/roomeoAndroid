import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/room_provider.dart';
import '../../../data/models/room.dart';
import '../../../core/error/exceptions.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Rooms'),
      ),
      body: Column(
        children: [
          // Arama çubuğu
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search rooms...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                _searchRooms(value);
              },
            ),
          ),

          // Yükleme göstergesi veya hata mesajı
          if (_isLoading)
            Center(child: CircularProgressIndicator())
          else if (_error != null)
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red),
              ),
            ),

          // Arama sonuçları
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
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
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rooms = await context.read<RoomProvider>().searchRooms(query);
      setState(() {
        _searchResults = rooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _joinRoom(Room room, String? accessCode) async {
    try {
      setState(() => _isLoading = true);

      if (room.isPrivate && (accessCode == null || accessCode.isEmpty)) {
        throw ValidationException('Access code is required for private rooms');
      }

      await context.read<RoomProvider>().joinRoom(
            room.roomId,
            accessCode: accessCode,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully joined room')),
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
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${room.name}${room.isPrivate ? " 🔒" : ""}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildRoomTypeChip(),
              ],
            ),
            SizedBox(height: 8),
            Text(room.description),
            if (room.isPrivate)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Private Room - Access Code Required',
                  style: TextStyle(
                    color: Colors.orange,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      '${room.currentParticipants}/${room.maxParticipants} participants',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (room.isPrivate)
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.lock, size: 16, color: Colors.orange),
                      ),
                    if (!room.isFull)
                      ElevatedButton(
                        onPressed: () => _handleJoin(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              room.isPrivate ? Colors.orange : Colors.blue,
                        ),
                        child:
                            Text(room.isPrivate ? 'Enter Code & Join' : 'Join'),
                      )
                    else
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Full',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomTypeChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: room.isPremium ? Colors.purple[100] : Colors.blue[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        room.roomType.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          color: room.isPremium ? Colors.purple : Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _handleJoin(BuildContext context) async {
    if (room.isPrivate) {
      _showAccessCodeDialog(context);
    } else {
      onJoin(null);
    }
  }

  Future<void> _showAccessCodeDialog(BuildContext context) async {
    final codeController = TextEditingController();

    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Access Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This is a private room. Please enter the access code to join.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Access Code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Enter the room access code',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              //textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: TextStyle(
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
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
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context, code);
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Join Room'),
          ),
        ],
      ),
    );

    if (code != null && code.isNotEmpty) {
      onJoin(code);
    }
  }
}
