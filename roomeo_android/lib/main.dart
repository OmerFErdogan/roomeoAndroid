// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/room_provider.dart';
import 'providers/message_provider.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/register_screen.dart';
import 'ui/screens/home/home_screen.dart';
import 'ui/screens/rooms/create_room_screen.dart';
import 'ui/screens/rooms/room_detail_screen.dart';
import 'ui/screens/rooms/search_room_screen.dart';
import 'data/models/room.dart';
import 'ui/shared/styles/modern_theme.dart'; // Modern tema import edildi

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({
    Key? key,
    required this.prefs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => RoomProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => MessageProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Study Rooms',
        debugShowCheckedModeBanner: false,
        theme: ModernTheme.themeData, // Modern temayı kullanıyoruz
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) =>
              auth.isLoggedIn ? HomeScreen() : LoginScreen(),
        ),
        routes: {
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/home': (context) => HomeScreen(),
          '/create-room': (context) => CreateRoomScreen(),
          '/search-rooms': (context) => SearchRoomsScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/room-detail') {
            final room = settings.arguments as Room;
            return MaterialPageRoute(
              builder: (context) => RoomDetailScreen(room: room),
            );
          }
          return null;
        },
      ),
    );
  }
}
