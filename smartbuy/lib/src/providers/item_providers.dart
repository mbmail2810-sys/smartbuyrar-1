import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/list_repository.dart';
import '../models/grocery_item.dart';
import 'list_providers.dart';

final listItemsProvider =
    StreamProvider.family<List<GroceryItem>, String>((ref, listId) {
  final repo = ref.watch(listRepositoryProvider);
  return repo.watchItems(listId);
});

final itemQueryProvider = StateProvider<String>((ref) => '');

final itemFamily = Provider.family<List<GroceryItem>, List<GroceryItem>>(
  (ref, items) {
    final query = ref.watch(itemQueryProvider);
    if (query.isEmpty) return items;
    return items.where((item) {
      if (item.usageLog == null || item.usageLog!.isEmpty) return false;

      final ts = item.usageLog!.last['date'];

      final lastDate = ts is Timestamp
          ? ts.toDate()
          : DateTime.fromMillisecondsSinceEpoch(ts);

      return DateTime.now().difference(lastDate).inDays >= 7;
    }).toList();
  },
);

final itemNotifierProvider =
    StateNotifierProvider<ItemNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(listRepositoryProvider);
  return ItemNotifier(repo);
});

class ItemNotifier extends StateNotifier<AsyncValue<void>> {
  final ListRepository _repo;
  ItemNotifier(this._repo) : super(const AsyncData(null));

  Future<void> addItem(String listId, GroceryItem item) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.safeAddItem(listId, item));
  }

  Future<void> updateItem(
      String listId, String itemId, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.safeUpdateItem(listId, itemId, data));
  }

  Future<void> deleteItem(String listId, String itemId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.safeDeleteItem(listId, itemId));
  }

}
