import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/room.dart';
import '../../../providers/room_provider.dart';

class ActiveSessionCard extends StatelessWidget {
  final Room room;

  const ActiveSessionCard({Key? key, required this.room}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Active Session',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              room.name,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${room.currentParticipants} participants'),
                TextButton(
                  onPressed: () {
                    context.read<RoomProvider>().exitRoom(room.roomId);
                  },
                  child: Text('Exit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}