import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'src/core/theme.dart';
import 'src/ui/routes/splash_wrapper.dart';
import 'package:smartbuy/src/providers/connectivity_provider.dart';
import 'package:smartbuy/src/providers/offline_sync_provider.dart';

class SmartBuyApp extends ConsumerStatefulWidget {
  const SmartBuyApp({super.key});
  @override
  ConsumerState<SmartBuyApp> createState() => _SmartBuyAppState();
}

class _SmartBuyAppState extends ConsumerState<SmartBuyApp> {
  @override
  void initState() {
    super.initState();
    ref.read(offlineSyncServiceProvider).init();
  }

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(connectivityProvider);
    final isOffline = connection.asData?.value == ConnectivityResult.none;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartBuy',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Stack(
        children: [
          const SplashWrapper(),
          if (isOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.red.shade400,
                padding: const EdgeInsets.all(8),
                child: const Text(
                  "⚠️ Offline mode: changes will sync later",
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Positioned(
            bottom: 16,
            right: 16,
            child: StreamBuilder<List<ConnectivityResult>>(
              stream: Connectivity().onConnectivityChanged,
              builder: (context, snapshot) {
                final connected = snapshot.data?.contains(ConnectivityResult.none) == false;
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    connected ? Icons.cloud_done : Icons.cloud_off,
                    color: connected ? Colors.green : Colors.grey,
                    size: 30,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
