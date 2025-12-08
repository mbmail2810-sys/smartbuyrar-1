import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/services/firestore_service.dart';
import 'src/core/firebase_init.dart';
import 'src/providers/offline_sync_provider.dart';
import 'src/services/notification_service.dart';
import 'src/services/offline_sync_service.dart';
import 'package:smartbuy/src/ui/routes/app_router.dart';
import 'package:smartbuy/src/core/theme.dart';
import 'package:smartbuy/src/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await initFirebase();

  // SIGN IN TEMPORARILY
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  await NotificationService().init();
  // Direct initialization of services
  final firestoreService = FirestoreService();
  final offlineSyncService = OfflineSyncService(firestoreService);
  await offlineSyncService.init();
  runApp(
    ProviderScope(
      overrides: [
        // Override the provider to use the initialized instance
        offlineSyncServiceProvider.overrideWithValue(offlineSyncService),
      ],
      child: const SmartBuyApp(),
    ),
  );
}

class SmartBuyApp extends ConsumerStatefulWidget {
  const SmartBuyApp({super.key});
  @override
  ConsumerState<SmartBuyApp> createState() => _SmartBuyAppState();
}

class _SmartBuyAppState extends ConsumerState<SmartBuyApp> {
  @override
  void initState() {
    super.initState();
    // Attempt sync on start
    Future.delayed(const Duration(seconds: 3), () {
      // ref.read(offlineSyncServiceProvider).syncQueuedData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
    );
  }
}
