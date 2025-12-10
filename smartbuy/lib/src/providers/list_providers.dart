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

// Optimistic lists state notifier for instant UI updates
class OptimisticListsNotifier extends StateNotifier<List<GroceryList>> {
  OptimisticListsNotifier() : super([]);

  void addOptimisticList(GroceryList list) {
    state = [list, ...state];
  }

  void removeOptimisticList(String listId) {
    state = state.where((l) => l.id != listId).toList();
  }

  void clear() {
    state = [];
  }
}

final optimisticListsProvider =
    StateNotifierProvider<OptimisticListsNotifier, List<GroceryList>>(
        (ref) => OptimisticListsNotifier());

// Stream of grocery lists for logged in user (merged with optimistic lists)
final userListsProvider = StreamProvider.autoDispose<List<GroceryList>>((ref) {
  final auth = ref.watch(authStateProvider).value;
  if (auth == null) return const Stream.empty();
  
  final optimisticLists = ref.watch(optimisticListsProvider);
  final firestoreStream = ref.watch(listRepositoryProvider).watchLists();
  
  return firestoreStream.map((firestoreLists) {
    // Remove optimistic lists that now exist in Firestore
    final firestoreIds = firestoreLists.map((l) => l.id).toSet();
    final pendingOptimistic = optimisticLists
        .where((l) => !firestoreIds.contains(l.id))
        .toList();
    
    // Merge: optimistic first, then Firestore lists
    return [...pendingOptimistic, ...firestoreLists];
  });
});

final groceryListProvider =
    StreamProvider.autoDispose.family<GroceryList, String>((ref, listId) {
  return ref.watch(listRepositoryProvider).watchList(listId);
});

final remindersProvider =
    StreamProvider.autoDispose.family<List<Reminder>, String>((ref, listId) {
  return ref.watch(listRepositoryProvider).watchReminders(listId);
});
