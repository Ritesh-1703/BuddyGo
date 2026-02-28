import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:buddygoapp/app.dart';
import 'package:buddygoapp/providers.dart';
import 'package:buddygoapp/core/services/notification_service.dart';
import 'package:buddygoapp/features/groups/presentation/group_chat_screen.dart'; // Add this
import 'package:buddygoapp/features/user/presentation/profile_screen.dart'; // Add this
import 'core/theme/dark_theme.dart';
import 'core/theme/light_theme.dart';
import 'firebase_options.dart';

// Add this global key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notifications with callback
  await NotificationService().initialize(
    onTap: (route, data) {
      // Handle notification tap
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
      }
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: MaterialApp(
        title: 'BuddyGO',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey, // Add this
        theme: lightTheme,
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