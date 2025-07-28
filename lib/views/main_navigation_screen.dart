import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/user_provider.dart';
import 'chat/chat_list_screen.dart';
import 'call/call_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [];

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
    
    if (currentUser != null && _screens.isEmpty) {
      setState(() {
        _screens.addAll([
          const ChatListScreen(),
          const CallScreen(), // Remove currentUser parameter since CallViewModel is singleton
        ]);
      });
      debugPrint('[MainNavigationScreen] Screens initialized. Count: ${_screens.length}');
    } else if (currentUser == null) {
      debugPrint('[MainNavigationScreen] No current user available');
    } else {
      debugPrint('[MainNavigationScreen] Screens already initialized');
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

        // Initialize screens if not already done (only if _screens is empty)
        if (_screens.isEmpty && currentUser != null) {
          debugPrint('[MainNavigationScreen] Screens empty, initializing');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeScreens();
          });
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