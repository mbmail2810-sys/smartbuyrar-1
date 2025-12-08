import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbuy/src/providers/theme_provider.dart';
import 'package:smartbuy/src/providers/auth_providers.dart';

class HomeScreenRouter extends ConsumerStatefulWidget {
  const HomeScreenRouter({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<HomeScreenRouter> createState() => _HomeScreenRouterState();
}

class _HomeScreenRouterState extends ConsumerState<HomeScreenRouter> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider);
    final currentLocation = GoRouterState.of(context).uri.toString();
    
    if (currentLocation.contains('/lists')) {
      _currentIndex = 0;
    } else if (currentLocation.contains('/insights')) {
      _currentIndex = 1;
    } else if (currentLocation.contains('/pantry')) {
      _currentIndex = 2;
    } else if (currentLocation.contains('/profile')) {
      _currentIndex = 3;
    }

    return Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/smartbuy_cart_green.png',
              height: 28,
              width: 28,
            ),
            const SizedBox(width: 8),
            const Text('My Grocery List'),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF00B200),
              ),
              child: const Text('SmartBuy', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            SwitchListTile(
              title: const Text("Dark Mode"),
              value: mode == ThemeMode.dark,
              secondary: const Icon(Icons.dark_mode),
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggleTheme(),
            ),
            ListTile(
              title: const Text('Settings'),
              leading: const Icon(Icons.settings),
              onTap: () {
                Navigator.pop(context);
                context.go('/settings');
              },
            ),
          ],
        ),
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00B200),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0:
              context.go('/lists');
              break;
            case 1:
              context.go('/insights');
              break;
            case 2:
              context.go('/pantry');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Lists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Pantry',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
