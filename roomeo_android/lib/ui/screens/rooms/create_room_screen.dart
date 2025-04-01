// lib/ui/screens/rooms/create_room_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roome_android/providers/room_provider.dart';

class CreateRoomScreen extends StatefulWidget {
  @override
  _CreateRoomScreenState createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _roomType = 'normal';
  bool _isPrivate = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Room'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Room Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a room name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _roomType,
              decoration: InputDecoration(
                labelText: 'Room Type',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'normal',
                  child: Text('Normal (6 participants)'),
                ),
                DropdownMenuItem(
                  value: 'premium',
                  child: Text('Premium (18 participants)'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _roomType = value ?? 'normal';
                });
              },
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Private Room'),
              subtitle: Text(
                'Private rooms require an access code that will be generated automatically',
              ),
              value: _isPrivate,
              onChanged: (value) {
                setState(() {
                  _isPrivate = value;
                });
              },
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _createRoom,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Create Room'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final room = await context.read<RoomProvider>().createRoom(
            name: _nameController.text,
            description: _descriptionController.text,
            roomType: _roomType,
            isPrivate: _isPrivate,
          );

      if (room.isPrivate) {
        // Özel oda oluşturulduğunda access code'u göster
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Room Created'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your room has been created successfully.'),
                SizedBox(height: 16),
                Text(
                  'Access Code: ${room.accessCode}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Share this code with others to let them join your room.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Dialog'u kapat
                  Navigator.pop(context); // Create Room ekranını kapat
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
