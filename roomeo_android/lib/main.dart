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

// Uygulama yaşam döngüsü değişikliklerini global bir handler ile yönetelim
class AppLifecycleManager extends StatefulWidget {
  final Widget child;
  
  const AppLifecycleManager({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Uygulama yaşam döngüsü olaylarını dinlemeye başla
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    // Dinlemeyi durdur
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Provider'ı bu context'te güvenli bir şekilde kullanabiliriz
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      print('App lifecycle changed to $state - marking user inactive');
      // Kullanıcıyı inaktif olarak işaretle
      roomProvider.markUserAsInactive();
    } else if (state == AppLifecycleState.resumed) {
      // Uygulama tekrar öne geldiğinde, odaların bağlantı durumunu kontrol et
      print('App resumed - checking connection status');
      roomProvider.startConnectionHealthCheck();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
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
          lazy: false, // RoomProvider'ı hızlıca başlat
        ),
        ChangeNotifierProvider(
          create: (_) => MessageProvider(),
        ),
      ],
      // AppLifecycleManager tüm uygulamayı sarmalıyor
      child: AppLifecycleManager(
        child: MaterialApp(
          title: 'Study Rooms',
          debugShowCheckedModeBanner: false,
          theme: ModernTheme.themeData, // Modern temayı kullanıyoruz
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              // Kullanıcı girişi varsa, bağlantı durumu kontrolünü başlat
              if (auth.isLoggedIn) {
                final roomProvider = Provider.of<RoomProvider>(context, listen: false);
                // Uygulama başlangıcında bağlantı durumu kontrolünü başlat
                Future.microtask(() => roomProvider.startConnectionHealthCheck());
              }
              return auth.isLoggedIn ? HomeScreen() : LoginScreen();
            },
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
      ),
    );
  }
}
