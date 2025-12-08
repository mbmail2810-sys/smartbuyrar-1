import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/grocery_list.dart';
import '../models/grocery_item.dart';
import 'list_providers.dart';
import 'item_providers.dart';
import '../repositories/list_repository.dart';

// This provider will calculate the total spent for a grocery list
// and manage budget alerts and control.
final budgetNotifierProvider =
    StateNotifierProvider.family<BudgetNotifier, AsyncValue<void>, String>(
        (ref, listId) {
  final listRepository = ref.watch(listRepositoryProvider);
  return BudgetNotifier(ref, listId, listRepository);
});

class BudgetNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final String _listId;
  final ListRepository _listRepository;

  BudgetNotifier(this._ref, this._listId, this._listRepository)
      : super(const AsyncData(null)) {
    _init();
  }

  void _init() {
    _ref.listen<AsyncValue<GroceryList>>(
      groceryListProvider(_listId),
      (_, next) {
        next.whenData((list) {
          _updateSpent(list);
        });
      },
    );

    _ref.listen<AsyncValue<List<GroceryItem>>>(
      listItemsProvider(_listId),
      (_, next) {
        next.whenData((items) {
          _ref.read(groceryListProvider(_listId)).whenData((list) {
            _updateSpent(list, items: items);
          });
        });
      },
    );
  }

  Future<void> _updateSpent(GroceryList list, {List<GroceryItem>? items}) async {
    state = const AsyncLoading();
    try {
      final currentItems =
          items ?? (await _ref.read(listItemsProvider(_listId).future)) ?? [];

      double newSpent = 0.0;
      for (var item in currentItems) {
        newSpent += (item.price ?? 0.0) * item.quantity;
      }

      if (newSpent != list.spent) {
        await _listRepository.safeUpdateList(_listId, {'spent': newSpent});
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // Check if adding an item would exceed the budget with control enabled
  bool canAddItem(GroceryList list, double itemPrice, int itemQuantity) {
    if (!list.budgetControlEnabled || list.budget == null) {
      return true; // No budget control or no budget set
    }

    final currentSpent = list.spent ?? 0.0;
    final potentialSpent = currentSpent + (itemPrice * itemQuantity);

    return potentialSpent <= list.budget!;
  }

  // Get budget alert status
  BudgetAlertStatus getBudgetAlertStatus(GroceryList list) {
    if (list.budget == null || list.budget! <= 0) {
      return BudgetAlertStatus.noBudget;
    }

    final currentSpent = list.spent ?? 0.0;
    final budget = list.budget!;

    if (currentSpent >= budget) {
      return BudgetAlertStatus.exceeded;
    } else if (currentSpent / budget >= 0.90) {
      return BudgetAlertStatus.warning;
    } else {
      return BudgetAlertStatus.safe;
    }
  }
}

enum BudgetAlertStatus {
  safe,
  warning,
  exceeded,
  noBudget,
}

// Provider to get the current budget alert status for a list
final currentBudgetAlertStatusProvider =
    Provider.family<BudgetAlertStatus, String>((ref, listId) {
  final listAsyncValue = ref.watch(groceryListProvider(listId));
  return listAsyncValue.when(
    data: (list) => ref.watch(budgetNotifierProvider(listId).notifier).getBudgetAlertStatus(list),
    loading: () => BudgetAlertStatus.safe, // Default to safe while loading
    error: (_, __) => BudgetAlertStatus.safe, // Default to safe on error
  );
});

// Provider to check if adding an item is allowed
final canAddItemProvider =
    Provider.family<bool, ({String listId, double itemPrice, int itemQuantity})>(
        (ref, args) {
  final listAsyncValue = ref.watch(groceryListProvider(args.listId));
  return listAsyncValue.when(
    data: (list) => ref
        .watch(budgetNotifierProvider(args.listId).notifier)
        .canAddItem(list, args.itemPrice, args.itemQuantity),
    loading: () => true, // Allow adding while loading
    error: (_, __) => true, // Allow adding on error
  );
});
