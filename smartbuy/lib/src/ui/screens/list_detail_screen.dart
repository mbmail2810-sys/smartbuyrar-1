import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/grocery_list.dart';
import '../../providers/item_providers.dart';
import '../../models/grocery_item.dart';
import 'package:lottie/lottie.dart';
import '../../providers/list_providers.dart' as list_providers;
import '../../providers/auth_providers.dart';
import '../../providers/reminders_provider.dart';
import '../../providers/suggestion_provider.dart';
import 'package:flutter/services.dart';
import '../../core/utils.dart';
import '../../services/pantry_service.dart';
import '../../services/category_stats_service.dart';
import '../../providers/budget_provider.dart';
import '../widgets/share_list_bottom_sheet.dart';

class ListDetailScreen extends ConsumerStatefulWidget {
  final String listId;
  final String listTitle;

  const ListDetailScreen({super.key, required this.listId, required this.listTitle});

  @override
  ConsumerState<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends ConsumerState<ListDetailScreen> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<SliverAnimatedListState> _listKey = GlobalKey();
  List<GroceryItem> _items = []; // Local state to manage items for AnimatedList

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(listItemsProvider(widget.listId));
    final listAsync = ref.watch(list_providers.groceryListProvider(widget.listId)); // Watch the list provider
    final user = ref.watch(authServiceProvider).currentUser; // Get current user

    ref.listen(listItemsProvider(widget.listId), (previous, next) {
      if (next.hasValue && next.value != null) {
        final newItems = next.value!;
        if (newItems.length > _items.length) {
          // Find the new item and its index
          final newItem = newItems.firstWhere((item) => !_items.contains(item));
          // For simplicity, we assume new items are added to the start.
          // In a real app, you might need a more sophisticated diffing algorithm
          // to find the exact insertion point.
          _items.insert(0, newItem);
          _listKey.currentState?.insertItem(0);
        } else if (newItems.length < _items.length) {
          // Handle removals
          final removedItem = _items.firstWhere((item) => !newItems.contains(item));
          final removedIndex = _items.indexOf(removedItem);
          _items.removeAt(removedIndex);
          _listKey.currentState?.removeItem(
            removedIndex,
            (context, animation) => ScaleTransition(
              scale: animation,
              child: _buildItemTile(removedItem, context, ref),
            ),
          );
        } else {
          // Handle updates (if necessary)
          _items = newItems;
          // You might want to find the updated item and refresh it,
          // but for now, a simple state update might be enough if the item's widget rebuilds.
          setState(() {});
        }
      }
    });

    return Scaffold(
      key: _scaffoldMessengerKey,
      appBar: AppBar(
        title: Hero(
          tag: widget.listId,
          child: Text(
            widget.listTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        actions: [
          StreamBuilder<List<ConnectivityResult>>(
            stream: Connectivity().onConnectivityChanged,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              final isConnected = !snapshot.data!.contains(ConnectivityResult.none);
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    isConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: isConnected ? Colors.green : Colors.grey,
                  ),
                ),
              );
            },
          ),
          if (listAsync.valueOrNull != null && listAsync.value!.canShare(user?.uid ?? ''))
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ShareListBottomSheet(list: listAsync.value!),
                );
              },
            ),
          if (listAsync.valueOrNull != null && listAsync.value!.canEdit(user?.uid ?? ''))
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddItemDialog(context, ref),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          if (listAsync.value != null)
            SliverToBoxAdapter(child: _buildBudgetCard(context, listAsync.value!)),
          if (itemsAsync.value != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  children: itemsAsync.value!
    .where((item) {
      if (item.usageLog == null || item.usageLog!.isEmpty) return false;

      final lastUsed = toDateTime(item.usageLog!.last['date']);
      return DateTime.now().difference(lastUsed).inDays >= 7;
    })
    .map((item) => Card(
          margin: const EdgeInsets.only(top: 8),
          child: ListTile(
            title: Text("You usually buy ${item.name} weekly 🧠"),
            trailing: ElevatedButton(
              child: const Text("Add"),
              onPressed: () => _showAddItemDialog(context, ref, suggestion: item),
            ),
          ),
        ))
    .toList(),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Consumer(builder: (context, ref, _) {
                final suggestions = ref.watch(suggestionsProvider(widget.listId));
                if (suggestions.isEmpty) return const SizedBox.shrink();

                return SizedBox(
                  height: 46,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: suggestions.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(item.name),
                          avatar: const Icon(Icons.lightbulb_outline),
                          onPressed: () => _showAddItemDialog(context, ref, suggestion: item),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            ),
          ),
          itemsAsync.when(
            data: (items) {
              _items = items.toList(); // Initialize local items list
              _items.sort((a, b) {
                final aTime = a.createdAt is int
                    ? DateTime.fromMillisecondsSinceEpoch(a.createdAt as int)
                    : a.createdAt;
                final bTime = b.createdAt is int
                    ? DateTime.fromMillisecondsSinceEpoch(b.createdAt as int)
                    : b.createdAt;
                return aTime.compareTo(bTime);
              });
              if (_items.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset('assets/lottie/empty-cart.json', height: 180),
                        const Text(
                          "No items yet! Add your first 🛍️",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverAnimatedList(
                key: _listKey,
                initialItemCount: _items.length,
                itemBuilder: (context, index, animation) {
                  final item = _items[index];
                  return ScaleTransition(
                    scale: animation,
                    child: _buildItemTile(item, context, ref),
                  );
                },
              );
            },
            loading: () =>
                const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator.adaptive())),
            error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),
          // Moved the Smart Suggestion card outside the SliverList and before the Reminders ExpansionTile
          if (itemsAsync.value != null &&
              itemsAsync.value!.isNotEmpty &&
              itemsAsync.value!.length > 5)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: ListTile(
                    title: const Text("🧠 Smart Suggestion"),
                    subtitle: const Text("You usually shop every 7 days. Want a reminder?"),
                    trailing: ElevatedButton(
                      onPressed: () {
                        final nextWeek =
                            DateTime.now().add(const Duration(days: 7, hours: 17));
                        ref.read(list_providers.listRepositoryProvider).addReminder(
                              listId: widget.listId,
                              title: "Next Weekly Grocery Run 🛒",
                              datetime: nextWeek,
                              createdBy: ref.read(authStateProvider).value!.uid,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reminder added for next week!'),
                          ),
                        );
                      },
                      child: const Text("Add"),
                    ),
                  ),
                ),
              ),
            ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                ExpansionTile(
                  key: const PageStorageKey<String>('reminders'),
                  maintainState: true,
                  leading: const Icon(Icons.notifications),
                  title: const Text("Reminders"),
                  children: [
                    Consumer(builder: (context, ref, _) {
                      final remindersStream = ref.watch(remindersProvider(widget.listId));
                      return remindersStream.when(
                        data: (reminders) => Column(
                          children: [
                            for (final r in reminders)
                              ListTile(
                                title: Text(r.title),
                                subtitle: Builder(builder: (context) {
                                  final dt = DateTime.fromMillisecondsSinceEpoch(r.datetime);
                                  return Text("⏰ $dt");
                                }),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => ref
                                      .read(list_providers.listRepositoryProvider)
                                      .safeDeleteReminder(widget.listId, r.id!),
                                ),
                              ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text("Add Reminder"),
                              onPressed: () => _showAddReminderDialog(context, ref),
                            ),
                          ],
                        ),
                        loading: () => const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator()),
                        error: (e, _) => Text("Error: $e"),
                      );
                    })
                  ],
                ),
                // Add padding to the bottom to ensure the last elements are not obscured by the bottom navigation bar
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      )
    );
  }

  Widget _buildItemTile(GroceryItem item, BuildContext context, WidgetRef ref) {
    final repo = ref.read(list_providers.listRepositoryProvider);
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: Text('Are you sure you want to delete "${item.name}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
        return confirmed ?? false;
      },
      onDismissed: (direction) {
        final index = _items.indexOf(item);
        if (index != -1) {
          _items.removeAt(index);
          _listKey.currentState?.removeItem(
            index,
            (context, animation) {
              // Return a simple, stateless widget for the animation.
              // It should be visually similar to the original item.
              return ScaleTransition(
                scale: animation,
                child: ListTile(
                  title: Text(
                    item.name,
                    style: TextStyle(
                      decoration: item.checked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${item.quantity} × ${item.category} • ₹${item.price?.toStringAsFixed(2) ?? '-'}",
            ),
            if (item.description != null && item.description!.isNotEmpty)
              Text(
                item.description!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: Checkbox(
                    value: item.checked,
                    onChanged: null, // No action needed during dismissal
                  ),
                ),
              );
            },
          );
        }
        repo.safeDeleteItem(widget.listId, item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} deleted')),
        );
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        onTap: () => _showEditItemDialog(context, ref, item),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.checked
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        subtitle: Text(
          "${item.quantity} × ${item.category} • ₹${item.price?.toStringAsFixed(2) ?? '-'}",
        ),
        trailing: Checkbox(
            value: item.checked,
            onChanged: (val) async {
              // This onChanged is usually for the Checkbox itself, but we're handling taps
              // via InkWell to ensure clickability. We can still keep this for consistency,
              // or set it to null if InkWell is the sole source of truth for taps.
              // For now, let's keep it to also update the state, effectively having two ways
              // of triggering the same logic. This often handles subtle platform differences.
              final newCheckedState = val ?? false;
              await ref
                  .read(list_providers.listRepositoryProvider)
                  .updateItemChecked(widget.listId, item.id, newCheckedState);

              if (newCheckedState) {
                // Item is checked as purchased, add to pantry
                PantryService.addToPantry(item.name, qty: item.quantity);

                // Call CategoryStatsService after an item is marked as purchased
                if (!mounted) return;
                final user = ref.read(authStateProvider).value;
                if (user == null) return;

                final uid = user.uid;

                await CategoryStatsService().updateCategoryStats(
                  userId: uid,
                  category: item.category,
                  price: item.price ?? 0.0, // Use 0.0 if price is null
                );
              }
            },
        ),
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context, WidgetRef ref) {
    final titleCtl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));

    showDialog(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);
        return AlertDialog(
          title: const Text("Add Reminder"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtl,
                decoration: const InputDecoration(hintText: "Reminder Title"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                    "Select Time: ${selectedDate.hour}:${selectedDate.minute.toString().padLeft(2, '0')}"),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    // Capture the context safely before the async operation for showTimePicker
                    final currentScreenContext = context;
                    if (!currentScreenContext.mounted) return;
                    final time = await showTimePicker(
                        context: currentScreenContext,
                        initialTime: TimeOfDay.fromDateTime(selectedDate));
                    if (time != null) {
                      if (!currentScreenContext.mounted) return;
                      selectedDate = DateTime(picked.year, picked.month,
                          picked.day, time.hour, time.minute);
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtl.text.trim();
                if (title.isEmpty) return;
                final user = ref.read(authStateProvider).value!;
                await ref
                    .read(list_providers.listRepositoryProvider)
                    .addReminder(
                      listId: widget.listId,
                      title: title,
                      datetime: selectedDate,
                      createdBy: user.uid,
                    );
                navigator.pop();
              },
              child: const Text("Save"),
            )
          ],
        );
      },
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref, {GroceryItem? suggestion}) {
    final nameCtl = TextEditingController(text: suggestion?.name ?? "");
    _showItemDialog(context, ref, isEdit: false, suggestion: suggestion, nameCtl: nameCtl);
  }

  void _showEditItemDialog(BuildContext context, WidgetRef ref, GroceryItem item) {
    _showItemDialog(context, ref, item: item, isEdit: true);
  }

  void _shareList(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      final inviteId =
          await ref.read(list_providers.listRepositoryProvider).createInvite(
                listId: widget.listId,
                listTitle: widget.listTitle,
                createdBy: user.uid,
              );

      final inviteLink = "https://smartbuy.app/invite/$inviteId";

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Invite link generated: $inviteLink'),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: inviteLink)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error generating invite: $e')),
      );
      }
    }
  }

  void _showItemDialog(BuildContext context, WidgetRef ref,
      {GroceryItem? item, bool isEdit = false, GroceryItem? suggestion, TextEditingController? nameCtl}) {
    final nameController = nameCtl ?? TextEditingController(text: item?.name ?? suggestion?.name ?? '');
    final descController = TextEditingController(text: item?.description ?? suggestion?.description ?? '');
    final qtyCtl = TextEditingController(text: item?.quantity.toString() ?? suggestion?.quantity.toString() ?? '1');
    final priceCtl =
        TextEditingController(text: item?.price?.toStringAsFixed(2) ?? suggestion?.price?.toStringAsFixed(2) ?? '');
    String category = item?.category ?? suggestion?.category ?? 'General';

    final repo = ref.read(list_providers.listRepositoryProvider);
    showDialog(
      context: context,
      builder: (ctx) {
        final navigator = Navigator.of(ctx);
        return AlertDialog(
          title: Text(isEdit ? 'Edit Item' : 'Add Item'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Item name'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: qtyCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
                TextField(
                  controller: priceCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price (₹)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  onChanged: (val) => category = val ?? 'General',
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'Fruits', child: Text('🍎 Fruits')),
                    DropdownMenuItem(value: 'Vegetables', child: Text('🥦 Vegetables')),
                    DropdownMenuItem(value: 'Dairy', child: Text('🥛 Dairy')),
                    DropdownMenuItem(value: 'Bakery', child: Text('🥐 Bakery')),
                    DropdownMenuItem(value: 'Snacks', child: Text('🍿 Snacks')),
                    DropdownMenuItem(value: 'General', child: Text('📦 General')),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isEdit
                  ? () async {
                      final itemName = nameController.text.trim();
                      if (itemName.isEmpty) return;

                      final newItem = GroceryItem(
                        id: item?.id ?? '',
                        name: itemName,
                        description: descController.text.trim(),
                        price: double.tryParse(priceCtl.text),
                        quantity: int.tryParse(qtyCtl.text) ?? 1,
                        category: category,
                        checked: item?.checked ?? false,
                        createdAt: item?.createdAt ?? DateTime.now(),
                        createdBy:
                            ref.read(authStateProvider).value!.uid, // Add createdBy
                      );

                      await ref
                          .read(list_providers.listRepositoryProvider)
                          .safeUpdateItem(widget.listId, item!.id, newItem.toMap());
                      if (mounted) navigator.pop();
                    }
                  : () async {
                      final itemName = nameController.text.trim();
                      if (itemName.isEmpty) return;

                      final itemPrice = double.tryParse(priceCtl.text) ?? 0.0;
                      final itemQuantity = int.tryParse(qtyCtl.text) ?? 1;

                      final canAdd = ref.read(canAddItemProvider((
                        listId: widget.listId,
                        itemPrice: itemPrice,
                        itemQuantity: itemQuantity,
                      )));

                      if (!canAdd) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Cannot add item: Budget control is enabled and adding this item would exceed the budget.')),
                        );
                        return;
                      }

                      final newItem = GroceryItem(
                        id: item?.id ?? '',
                        name: itemName,
                        description: descController.text.trim(),
                        price: itemPrice,
                        quantity: itemQuantity,
                        category: category,
                        checked: item?.checked ?? false,
                        createdAt: item?.createdAt ?? DateTime.now(),
                        createdBy: ref.read(authStateProvider).value!.uid,
                      );

                      navigator.pop();
                      await repo.safeAddItem(widget.listId, newItem);
                      if (!context.mounted) return;
                      _showSuccess(context);

                      final user = ref.read(authStateProvider).value;
                      if (user != null) {
                        await CategoryStatsService().updateCategoryStats(
                          userId: user.uid,
                          category: newItem.category,
                          price: newItem.price ?? 0.0,
                        );
                      }
                    },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccess(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Lottie.asset('assets/lottie/success.json', repeat: false),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        navigator.pop(); // Close the dialog
      }
    });
  }

  Widget _buildBudgetCard(BuildContext context, GroceryList list) {
    final budget = list.budget ?? 0;
    final spent = list.spent ?? 0;
    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;

    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Budget: ₹${budget.toStringAsFixed(0)}",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: progress, minHeight: 8),
            const SizedBox(height: 6),
            Text(
              "Spent: ₹${spent.toStringAsFixed(0)} • Remaining: ₹${(budget - spent).toStringAsFixed(0)}",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Consumer(builder: (context, watch, _) {
              final budgetAlertStatus =
                  watch.watch(currentBudgetAlertStatusProvider(widget.listId));
              String alertMessage = '';
              Color alertColor = Colors.transparent;
              IconData alertIcon = Icons.info_outline;

              switch (budgetAlertStatus) {
                case BudgetAlertStatus.warning:
                  alertMessage = 'Warning: Approaching budget limit!';
                  alertColor = Colors.orange;
                  alertIcon = Icons.warning_amber_rounded;
                  break;
                case BudgetAlertStatus.exceeded:
                  alertMessage = 'Budget exceeded!';
                  alertColor = Colors.red;
                  alertIcon = Icons.error_outline_rounded;
                  break;
                case BudgetAlertStatus.noBudget:
                  alertMessage = 'No budget set.';
                  alertColor = Colors.grey;
                  alertIcon = Icons.info_outline;
                  break;
                case BudgetAlertStatus.safe:
                  alertMessage = ''; // No alert for safe status
                  break;
              }

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return SizeTransition(
                      sizeFactor: animation,
                      axisAlignment: -1.0,
                      child: child);
                },
                child: alertMessage.isNotEmpty
                    ? Padding(
                        key: ValueKey(alertMessage), // Key for animation
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Icon(alertIcon, color: alertColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                alertMessage,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: alertColor),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('no-alert')),
              );
            }),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.block, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Restrict add when budget exceeded",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Switch(
                  value: list.budgetControlEnabled,
                  onChanged: (bool value) async {
                    await ref
                        .read(list_providers.listRepositoryProvider)
                        .safeUpdateList(
                            widget.listId, {'budgetControlEnabled': value});
                  },
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                label: const Text("Edit Budget"),
                onPressed: () => _showBudgetDialog(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, WidgetRef ref) {
    final ctl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);
        return AlertDialog(
          title: const Text('Set Budget'),
          content: TextField(
            controller: ctl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter budget in ₹'),
          ),
          actions: [
            TextButton(
                onPressed: () => navigator.pop(),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () async {
                final newBudget = double.tryParse(ctl.text);
                if (newBudget == null) return;
                
                navigator.pop();
                await ref
                    .read(list_providers.listRepositoryProvider)
                    .updateBudget(widget.listId, newBudget);
              },
              child: const Text('Save'),
            )
          ],
        );
      },
    );
  }
}
