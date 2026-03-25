import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:buddygoapp/app.dart';
import 'package:buddygoapp/providers.dart';
import 'package:buddygoapp/core/services/notification_service.dart';
import 'package:buddygoapp/features/auth/presentation/auth_controller.dart';
import 'package:buddygoapp/features/groups/presentation/group_chat_screen.dart';
import 'package:buddygoapp/features/user/presentation/profile_screen.dart';
import 'core/theme/dark_theme.dart';
import 'core/theme/light_theme.dart';
import 'firebase_options.dart';

// Global key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 🔥 Background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  print('Message data: ${message.data}');
  print('Message notification: ${message.notification?.title}');

  // Initialize Firebase in background
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔥 Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 🔥 Initialize notification service with callback
  await NotificationService().initialize(
    onTap: (route, data) {
      // Handle notification tap when app is in foreground/background
      print('Notification tapped: route=$route, data=$data');

      if (route == '/chat') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => GroupChatScreen(
              groupId: data['groupId'] ?? '',
              groupName: data['groupName'] ?? 'Chat',
            ),
          ),
        );
      } else if (route == '/profile') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => const ProfileScreen(),
          ),
        );
      } else if (route == '/trip-details') {
        // Navigate to trip details
        // Add your trip details screen navigation here
      } else if (route == '/requests') {
        // Navigate to join requests screen
        // Add your join requests screen navigation here
      }
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFCMTokenRefresh();
    _setupAuthStateListener();
  }

  // 🔥 Listen for FCM token refresh
  void _setupFCMTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print('FCM Token refreshed: $newToken');

      // Get current user and update token in Firestore
      final authController = Provider.of<AuthController>(context, listen: false);
      if (authController.currentUser != null) {
        await authController.refreshFCMToken();
      }
    }).onError((error) {
      print('Error refreshing FCM token: $error');
    });
  }

  // 🔥 Listen to auth state changes
  void _setupAuthStateListener() {
    // This will be handled by AuthController, but we can also add listener here
    // for any additional actions
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: MaterialApp(
        title: 'BuddyGO',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: vibrantNeonTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.light,
        home: const App(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
      ),
    );
  }
}