import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbuy/src/providers/auth_providers.dart';
import 'package:smartbuy/src/ui/widgets/animated_scale_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authServiceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              auth.currentUser?.email ?? 'No email',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            AnimatedScaleWidget(
              onTap: () => auth.signOut(),
              child: ElevatedButton(
                onPressed: () async {
                  await auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/signIn');
                  }
                },
                child: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
