import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/grocery_list.dart';
import '../models/grocery_item.dart';
import 'list_providers.dart';
import 'item_providers.dart';
import '../repositories/list_repository.dart';
import '../services/notification_service.dart';

final _statusCache = <String, String>{};
final _listLoaded = <String, bool>{};
final _itemsLoaded = <String, bool>{};
final _writeLock = <String, Completer<void>?>{};

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
      (previous, next) {
        next.whenData((list) {
          final wasLoaded = _listLoaded[_listId] == true;
          _listLoaded[_listId] = true;
          
          if (!wasLoaded) {
            final stored = list.lastAlertStatus;
            _statusCache[_listId] = stored ?? getBudgetAlertStatus(list).name;
            
            if (stored == null) {
              _listRepository.safeUpdateList(_listId, {'lastAlertStatus': _statusCache[_listId]!});
            }
            return;
          }
          
          _updateSpent(list);
          _maybeNotify(list);
        });
      },
    );

    _ref.listen<AsyncValue<List<GroceryItem>>>(
      listItemsProvider(_listId),
      (previous, next) {
        next.whenData((items) {
          final wasLoaded = _itemsLoaded[_listId] == true;
          _itemsLoaded[_listId] = true;
          
          if (!wasLoaded || _listLoaded[_listId] != true) {
            return;
          }
          
          _ref.read(groceryListProvider(_listId)).whenData((list) {
            _updateSpent(list, items: items);
            _maybeNotify(list);
          });
        });
      },
    );
  }

  Future<void> _maybeNotify(GroceryList list) async {
    final currentStatus = getBudgetAlertStatus(list);
    final currentStr = currentStatus.name;
    final cached = _statusCache[_listId];
    
    if (cached == currentStr) return;
    
    _statusCache[_listId] = currentStr;
    
    if (currentStatus == BudgetAlertStatus.warning && 
        cached != 'warning' && cached != 'exceeded') {
      final pct = ((list.spent ?? 0) / (list.budget ?? 1)) * 100;
      NotificationService().showBudgetWarningNotification(list.title, pct);
    } else if (currentStatus == BudgetAlertStatus.exceeded && cached != 'exceeded') {
      final over = (list.spent ?? 0) - (list.budget ?? 0);
      NotificationService().showBudgetExceededNotification(list.title, over);
    }
    
    await _writeStatusWithLock(currentStr);
  }

  Future<void> _writeStatusWithLock(String status) async {
    final existingLock = _writeLock[_listId];
    if (existingLock != null && !existingLock.isCompleted) {
      await existingLock.future;
    }
    
    final myLock = Completer<void>();
    _writeLock[_listId] = myLock;
    
    try {
      await _listRepository.safeUpdateList(_listId, {'lastAlertStatus': status});
    } finally {
      myLock.complete();
    }
  }

  Future<void> _updateSpent(GroceryList list, {List<GroceryItem>? items}) async {
    state = const AsyncLoading();
    try {
      final currentItems =
          items ?? (await _ref.read(listItemsProvider(_listId).future)) ?? [];

      double newSpent = 0.0;
      for (var item in currentItems) {
        if (item.checked) {
          newSpent += (item.price ?? 0.0) * item.quantity;
        }
      }

      if ((newSpent - (list.spent ?? 0)).abs() > 0.01) {
        await _listRepository.safeUpdateList(_listId, {'spent': newSpent});
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  bool canAddItem(GroceryList list, double itemPrice, int itemQuantity) {
    if (!list.budgetControlEnabled || list.budget == null) {
      return true;
    }

    final currentSpent = list.spent ?? 0.0;
    final potentialSpent = currentSpent + (itemPrice * itemQuantity);

    return potentialSpent <= list.budget!;
  }

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

final currentBudgetAlertStatusProvider =
    Provider.family<BudgetAlertStatus, String>((ref, listId) {
  final listAsyncValue = ref.watch(groceryListProvider(listId));
  return listAsyncValue.when(
    data: (list) => ref.watch(budgetNotifierProvider(listId).notifier).getBudgetAlertStatus(list),
    loading: () => BudgetAlertStatus.safe,
    error: (_, __) => BudgetAlertStatus.safe,
  );
});

final canAddItemProvider =
    Provider.family<bool, ({String listId, double itemPrice, int itemQuantity})>(
        (ref, args) {
  final listAsyncValue = ref.watch(groceryListProvider(args.listId));
  return listAsyncValue.when(
    data: (list) => ref
        .watch(budgetNotifierProvider(args.listId).notifier)
        .canAddItem(list, args.itemPrice, args.itemQuantity),
    loading: () => true,
    error: (_, __) => true,
  );
});

final spendingTrendsProvider = FutureProvider.family<List<SpendingTrend>, String>((ref, listId) async {
  final list = await ref.watch(groceryListProvider(listId).future);
  
  final Map<String, double> dailySpending = {};
  final now = DateTime.now();
  
  for (int i = 6; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    dailySpending[dateKey] = 0;
  }
  
  final purchaseLog = list.purchaseLog ?? [];
  for (final entry in purchaseLog) {
    try {
      final dateMs = entry['date'];
      if (dateMs == null) continue;
      
      final int timestamp = dateMs is int ? dateMs : (dateMs as num).toInt();
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final daysDiff = now.difference(dateTime).inDays;
      
      if (daysDiff >= 0 && daysDiff < 7) {
        final dateKey = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
        final totalRaw = entry['total'];
        final total = totalRaw is num ? totalRaw.toDouble() : 0.0;
        dailySpending[dateKey] = (dailySpending[dateKey] ?? 0) + total;
      }
    } catch (_) {
      continue;
    }
  }
  
  final trends = dailySpending.entries.map((e) {
    final parts = e.key.split('-');
    return SpendingTrend(
      date: DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
      amount: e.value,
    );
  }).toList();
  
  trends.sort((a, b) => a.date.compareTo(b.date));
  
  return trends;
});

class SpendingTrend {
  final DateTime date;
  final double amount;
  
  SpendingTrend({required this.date, required this.amount});
}
