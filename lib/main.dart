// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/locator.dart';
import 'repositories/auth_repository.dart';
import 'repositories/messaging_repository.dart';
import 'repositories/user_repository.dart';
import 'services/socket_client.dart';
import 'views/auth/login_screen.dart';
import 'views/chat/chat_list_screen.dart';
import 'core/config.dart';
import 'shared/theme.dart';
import 'view_models/user_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Call the setup function BEFORE runApp
  setupServiceLocator();

  AppConfig.instance.setup(env: Environment.development);
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide all repositories at the top level so they are available everywhere
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<MessagingRepository>(create: (_) => MessagingRepository()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Chat App',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}

// AuthWrapper remains the same
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We get the repository from the service locator now, not Provider
    final authRepository = sl<AuthRepository>();

    return FutureBuilder<String?>(
      future: authRepository.getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData && snapshot.data != null) {
          // If we have a token, we need to connect and then fetch user info
          // to register presence.
          return const AuthenticatedAppLoader();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}


// A new temporary screen to handle the async loading
class AuthenticatedAppLoader extends StatefulWidget {
  const AuthenticatedAppLoader({Key? key}) : super(key: key);
  @override
  _AuthenticatedAppLoaderState createState() => _AuthenticatedAppLoaderState();
}

class _AuthenticatedAppLoaderState extends State<AuthenticatedAppLoader> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await sl<SocketClient>().connectAndListen();
      final user = await sl<UserRepository>().getMe();
      sl<SocketClient>().registerPresence(user);

      // Check if widget is still mounted before using context
      if (!mounted) return;

      // Set the user in the provider
      Provider.of<UserProvider>(context, listen: false).setUser(user);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ChatListScreen()),
      );
    } catch (e) {
      // If something fails (e.g., token expired), log out and go to login
      await sl<AuthRepository>().logout();
      
      // Check if widget is still mounted before using context
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}