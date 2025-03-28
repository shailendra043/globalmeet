import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/feed_screen.dart';
import 'screens/auth_screen.dart';
import 'services/post_service.dart';
import 'services/user_service.dart';
import 'services/chat_service.dart';
import 'services/auth_service.dart';
import 'services/secure_storage_service.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'providers/post_provider.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Flutter binding initialized');
    
    // Initialize Firebase with web options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
    
    // Initialize security services
    await SecureStorageService.initialize();
    debugPrint('SecureStorage initialized');
    
    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.initialize();
    debugPrint('Notification service initialized');
    
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('Error initializing app: $e');
    debugPrint('Stack trace: $stackTrace');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Error initializing app:',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<PostService>(
          create: (_) => PostService(),
        ),
        Provider<UserService>(
          create: (_) => UserService(),
        ),
        Provider<ChatService>(
          create: (_) => ChatService(),
        ),
        ProxyProvider2<PostService, UserService, PostProvider>(
          update: (_, postService, userService, __) => 
              PostProvider(postService, userService),
        ),
      ],
      child: MaterialApp(
        title: 'GlobalMeet',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                    ],
                  ),
                ),
              );
            }

            return snapshot.hasData ? const FeedScreen() : const AuthScreen();
          },
        ),
      ),
    );
  }
}
