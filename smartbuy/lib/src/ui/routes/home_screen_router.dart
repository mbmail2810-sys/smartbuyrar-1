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
    final authState = ref.watch(authStateProvider);

    String welcomeMessage = 'Welcome';
    authState.whenOrNull(
      data: (user) {
        if (user != null) {
          welcomeMessage = 'Welcome, ${user.displayName ?? user.email ?? 'there'}!';
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(welcomeMessage),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('SmartBuy'),
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
                Navigator.pop(context); // close the drawer
                context.go('/settings');
              },
            ),
          ],
        ),
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
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
              context.go('/pantry'); // Added Pantry navigation
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            label: 'Lists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen_outlined), // Pantry icon
            label: 'Pantry',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
