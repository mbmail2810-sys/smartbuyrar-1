import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbuy/src/providers/auth_providers.dart';
import 'package:smartbuy/src/providers/connectivity_provider.dart';
import 'package:smartbuy/src/ui/screens/sign_in_screen.dart';

class SplashWrapper extends ConsumerWidget {
  const SplashWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final connection = ref.watch(connectivityProvider);
    final isOffline = connection.asData?.value == ConnectivityResult.none;

    return authState.when(
      data: (user) {
        if (user == null) {
          return const SignInScreen();
        }
        return Stack(
          children: [
            if (isOffline)
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.red.shade400,
                  padding: const EdgeInsets.all(8),
                  child: const Material(
                    color: Colors.transparent,
                    child: Text(
                      "⚠️ Offline mode: changes will sync later",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Authentication Error')),
      ),
    );
  }
}
