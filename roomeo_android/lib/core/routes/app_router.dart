import 'package:flutter/material.dart';
import '../../ui/screens/auth/login_screen.dart';
import '../../ui/screens/auth/register_screen.dart';
import '../../ui/screens/home/home_screen.dart';
import '../../ui/screens/rooms/create_room_screen.dart';
import '../../ui/screens/rooms/room_detail_screen.dart';
import '../../data/models/room.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => LoginScreen());

      case '/login':
        return MaterialPageRoute(builder: (_) => LoginScreen());

      case '/register':
        return MaterialPageRoute(builder: (_) => RegisterScreen());

      case '/home':
        return MaterialPageRoute(builder: (_) => HomeScreen());

      case '/create-room':
        return MaterialPageRoute(builder: (_) => CreateRoomScreen());

      case '/room-detail':
        final room = settings.arguments as Room;
        return MaterialPageRoute(
          builder: (_) => RoomDetailScreen(room: room),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route ${settings.name} not found'),
            ),
          ),
        );
    }
  }
}
