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
  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
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
                Navigator.pop(context); // close the drawer
                context.go('/settings');
              },
            ),
          ],
        ),
      ),
      body: widget.child,
    );
  }
}
