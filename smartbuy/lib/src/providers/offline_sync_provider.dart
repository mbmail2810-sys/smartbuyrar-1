import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbuy/src/services/firestore_service.dart';
import '../services/offline_sync_service.dart';

final syncStatusProvider = StateProvider<SyncStatus>((ref) {
  final syncService = ref.watch(offlineSyncServiceProvider);
  // The state of this provider is the current value of the notifier.
  return syncService.syncStatus.value;
});

final offlineSyncServiceProvider =
    Provider.autoDispose<OfflineSyncService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final offlineSyncService = OfflineSyncService(firestoreService);

  ref.onDispose(() {
    // Close Hive box or perform other cleanup tasks
  });

  return offlineSyncService;
});

extension OfflineSyncServiceInit on ProviderContainer {
  Future<void> initOfflineSyncService() async {
    final offlineSyncService = read(offlineSyncServiceProvider);
    await offlineSyncService.init();
  }
}
