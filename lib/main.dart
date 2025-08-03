// lib/main.dart

import 'package:chat_app_frontend/repositories/group_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/locator.dart';
import 'repositories/auth_repository.dart';
import 'repositories/messaging_repository.dart';
import 'repositories/user_repository.dart';
import 'services/socket_client.dart';
import 'views/auth/login_screen.dart';
import 'views/main_navigation_screen.dart';
import 'core/config.dart';
import 'shared/theme.dart';
import 'view_models/user_provider.dart';
import 'view_models/call/call_viewmodel.dart';
import 'shared/widgets/incoming_call_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Call the setup function BEFORE runApp
  setupServiceLocator();

  AppConfig.instance.setup(env: Environment.development);
  runApp(const MyApp());
}
// Global navigator key for accessing context from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
        // Provide the singleton CallViewModel globally
        ChangeNotifierProvider.value(value: sl<CallViewModel>()),
      ],
      child: MaterialApp(
        title: 'Chat App',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        home: const AuthWrapper(),
        // Add builder to ensure overlays work globally
        builder: (context, child) {
          return Stack(
            children: [
              child!,
              // Global incoming call overlay will be shown here when needed
              Consumer<CallViewModel>(
                builder: (context, callViewModel, child) {
                  debugPrint('[Main] 🔍 Checking incoming call overlay. isIncomingCall: ${callViewModel.isIncomingCall}, caller: ${callViewModel.incomingCallFrom?.displayName}');
                  
                  if (callViewModel.isIncomingCall && callViewModel.incomingCallFrom != null) {
                    debugPrint('[Main] 🎯 SHOWING incoming call overlay for ${callViewModel.incomingCallFrom!.displayName}');
                    return IncomingCallOverlay(
                      caller: callViewModel.incomingCallFrom!,
                      isVideoCall: callViewModel.incomingCallPayload?['callType'] == 'video',
                      onAccept: () {
                        debugPrint('[Main] ✅ Accept button pressed');
                        callViewModel.acceptIncomingCall();
                      },
                      onDecline: () {
                        debugPrint('[Main] ❌ Decline button pressed');
                        callViewModel.declineIncomingCall();
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          );
        },
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
      debugPrint('[AuthenticatedAppLoader] Starting initialization...');
      await sl<SocketClient>().connectAndListen();
      debugPrint('[AuthenticatedAppLoader] Socket connected');
      
      final user = await sl<UserRepository>().getMe();
      debugPrint('[AuthenticatedAppLoader] User fetched: ${user.displayName}');
      
      sl<SocketClient>().registerPresence(user);
      debugPrint('[AuthenticatedAppLoader] Presence registered');

      sl<GroupRepository>().listenForGroupKeys();
      debugPrint('[AuthenticatedAppLoader] Started listening for group keys.');

      // Check if widget is still mounted before using context
      if (!mounted) return;

      // Set the user in the provider
      Provider.of<UserProvider>(context, listen: false).setUser(user);
      debugPrint('[AuthenticatedAppLoader] User set in provider');

      // Initialize CallViewModel to start listening for incoming calls
      debugPrint('[AuthenticatedAppLoader] Initializing CallViewModel for incoming calls');
      final callViewModel = sl<CallViewModel>();
      if (!callViewModel.isInitialized) {
        await callViewModel.initialize(user);
      }

      debugPrint('[AuthenticatedAppLoader] Navigating to MainNavigationScreen');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } catch (e) {
      debugPrint('[AuthenticatedAppLoader] Error during initialization: $e');
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