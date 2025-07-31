import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/user_provider.dart';
import '../models/user_model.dart';
import 'chat/chat_list_screen.dart';
import 'call/call_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  List<Widget> _screens = [];
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    // Initialize screens after getting user from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreens();
    });
  }

  void _initializeScreens() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    
    debugPrint('[MainNavigationScreen] Initializing screens. Current user: ${currentUser?.displayName}');
    
    // Check if user has changed
    if (currentUser != null && currentUser != _currentUser) {
      _currentUser = currentUser;
      setState(() {
        _screens = [
          const ChatListScreen(),
          const CallScreen(),
        ];
      });
      debugPrint('[MainNavigationScreen] Screens re-initialized for new user: ${currentUser.displayName}');
    } else if (currentUser == null) {
      debugPrint('[MainNavigationScreen] No current user available');
    } else {
      debugPrint('[MainNavigationScreen] User unchanged, keeping existing screens');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.user;
        
        debugPrint('[MainNavigationScreen] Building. Current user: ${currentUser?.displayName}, Screens count: ${_screens.length}');
        
        if (currentUser == null) {
          debugPrint('[MainNavigationScreen] No user, showing loading');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Re-initialize screens if user has changed
        if (currentUser != _currentUser) {
          debugPrint('[MainNavigationScreen] User changed, re-initializing screens');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeScreens();
          });
        }

        // Show loading if screens are not ready
        if (_screens.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: 'Chats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.call),
                label: 'Calls',
              ),
            ],
          ),
        );
      },
    );
  }
} 