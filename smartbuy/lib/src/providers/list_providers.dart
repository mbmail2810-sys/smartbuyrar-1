// This is the list_providers.dart file.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../repositories/list_repository.dart';
import '../models/grocery_list.dart';
import '../models/reminder_model.dart';
import '../providers/auth_providers.dart';
import 'offline_sync_provider.dart';
import 'analytics_provider.dart';

final firestoreProvider = Provider((ref) => FirestoreService());
final listRepositoryProvider = Provider((ref) => ListRepository(
    ref.watch(firestoreProvider),
    ref.watch(offlineSyncServiceProvider),
    ref.watch(analyticsServiceProvider)));

// Stream of grocery lists for logged in user
final userListsProvider = StreamProvider.autoDispose<List<GroceryList>>((ref) {
  final auth = ref.watch(authStateProvider).value;
  if (auth == null) return const Stream.empty();
  return ref.watch(listRepositoryProvider).watchLists();
});

final groceryListProvider =
    StreamProvider.autoDispose.family<GroceryList, String>((ref, listId) {
  return ref.watch(listRepositoryProvider).watchList(listId);
});

final remindersProvider =
    StreamProvider.autoDispose.family<List<Reminder>, String>((ref, listId) {
  return ref.watch(listRepositoryProvider).watchReminders(listId);
});
