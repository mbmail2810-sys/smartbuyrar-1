import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbuy/src/providers/connectivity_provider.dart';

class SmartBuyAppContentWrapper extends ConsumerWidget {
  const SmartBuyAppContentWrapper({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectivityProvider);
    final isOffline = connection.asData?.value == ConnectivityResult.none;

    return Stack(
      children: [
        child,
        if (isOffline)
          Positioned(
            top: 40, // Adjust position to avoid overlap with system UI
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: Container(
                color: Colors.red.shade400,
                padding: const EdgeInsets.all(8),
                child: const Text(
                  "⚠️ Offline mode: changes will sync later",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 16,
          right: 16,
          child: StreamBuilder<List<ConnectivityResult>>(
            stream: Connectivity().onConnectivityChanged,
            builder: (context, snapshot) {
              final connected = snapshot.hasData &&
                  !snapshot.data!.contains(ConnectivityResult.none);
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  connected ? Icons.cloud_done : Icons.cloud_off,
                  color: connected ? Colors.green : Colors.grey,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
