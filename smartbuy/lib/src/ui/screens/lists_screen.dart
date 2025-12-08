import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'list_detail_screen.dart';
import '../../providers/auth_providers.dart';
import '../../providers/list_providers.dart';
import '../../providers/item_providers.dart'; // Import item_providers
import '../../models/grocery_list.dart';

class ListsScreen extends ConsumerStatefulWidget {
  const ListsScreen({super.key});

  @override
  ConsumerState<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends ConsumerState<ListsScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final Duration _animationDuration = const Duration(milliseconds: 400);
  final List<GroceryList> _lists = [];
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didUpdateWidget(covariant ListsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // This is where we would typically handle updates if the widget itself changed,
    // but for Riverpod, ref.listen in build or a Consumer is more idiomatic for reactive updates.
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(userListsProvider);

    ref.listen<AsyncValue<List<GroceryList>>>(userListsProvider, (prev, next) {
      if (!next.hasValue || !prev!.hasValue) return;

      final prevLists = prev.value!;
      final nextLists = next.value!;

      // Handle removals
      for (int i = prevLists.length - 1; i >= 0; i--) {
        if (!nextLists.any((list) => list.id == prevLists[i].id)) {
          final listToRemove = _lists.removeAt(i);
          _listKey.currentState?.removeItem(
            i,
            (context, animation) => _buildAnimatedCard(context, listToRemove, animation),
            duration: _animationDuration,
          );
        }
      }

      // Handle additions
      for (int i = 0; i < nextLists.length; i++) {
        if (!prevLists.any((list) => list.id == nextLists[i].id)) {
          _lists.insert(i, nextLists[i]);
          _listKey.currentState?.insertItem(i, duration: _animationDuration);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Grocery Lists 🛒"),
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
                child: Icon(
                  isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: isConnected ? Colors.green : Colors.grey,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddListDialog(context, ref),
      ),
      body: listsAsync.when(
        data: (lists) {
          if (_lists.isEmpty) {
            _lists.addAll(lists);
          }

          if (_lists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/lottie/empty-cart.png', height: 120),
                  const SizedBox(height: 10),
                  const Text("No lists yet. Tap ➕ to create one!",
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }

          return AnimatedList(
            key: _listKey,
            initialItemCount: _lists.length,
            itemBuilder: (context, index, animation) {
              if (index >= _lists.length) return Container();
              final list = _lists[index];
              return _buildAnimatedCard(context, list, animation);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildAnimatedCard(BuildContext context, GroceryList list, Animation<double> animation) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Consumer(
            builder: (context, ref, child) {
              final itemsAsync = ref.watch(listItemsProvider(list.id));
              final user = ref.watch(authStateProvider).value;
              final isOwner = list.ownerId == user?.uid;

              return ListTile(
                title: Text(list.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    itemsAsync.when(
                      data: (items) => Text("Members: ${list.members.length} • Items: ${items.length}"),
                      loading: () => Text("Members: ${list.members.length} • Items: Loading..."),
                      error: (e, _) => Text("Members: ${list.members.length} • Items: Error"),
                    ),
                    if (list.budget != null && list.budget! > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Budget: ₹${list.budget?.toStringAsFixed(2)} / Spent: ₹${list.spent?.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: (list.spent ?? 0) > (list.budget ?? 0) ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
                leading: Hero(
                  tag: list.id,
                  child: const Icon(Icons.list_alt, size: 32, color: Colors.green),
                ),
                trailing: isOwner
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share),
                            onPressed: () async {
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              final user = ref.read(authStateProvider).value!;
                              final repo = ref.read(listRepositoryProvider);
                              final inviteId = await repo.createInvite(
                                listId: list.id,
                                listTitle: list.title,
                                createdBy: user.uid,
                              );
                              final link = "smartbuy://invite/$inviteId";
                              await Clipboard.setData(ClipboardData(text: link));
                              if (!mounted) return;
                              scaffoldMessenger.showSnackBar(
                                SnackBar(content: Text('Invite link copied: $link')),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _deleteList(context, ref, list),
                          ),
                        ],
                      )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 450),
                      pageBuilder: (_, __, ___) => ListDetailScreen(
                        listId: list.id,
                        listTitle: list.title,
                      ),
                      transitionsBuilder: (_, anim, __, child) => FadeTransition(
                        opacity: anim,
                        child: child,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAddListDialog(BuildContext context, WidgetRef ref) {
    final titleCtl = TextEditingController();
    final budgetCtl = TextEditingController();

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('New List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtl,
              decoration: const InputDecoration(hintText: 'e.g. Weekly Groceries'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: budgetCtl,
              decoration: const InputDecoration(hintText: 'Budget (optional)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final title = titleCtl.text.trim();
              if (title.isEmpty) return;

              final budget = double.tryParse(budgetCtl.text.trim());
              final auth = ref.read(authStateProvider).value!;
              final repo = ref.read(listRepositoryProvider);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              final listData = {
                'title': title,
                'ownerId': auth.uid,
                'members': [auth.uid],
                if (budget != null) 'budget': budget,
              };

              Navigator.pop(c);
              await repo.safeCreateList(listData);

              if (mounted) {
                scaffoldMessenger.showSnackBar(const SnackBar(
                  content: Text('List added successfully 🎉'),
                  duration: Duration(seconds: 2),
                ));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _deleteList(BuildContext context, WidgetRef ref, GroceryList listToDelete) async {
    // Grab the ScaffoldMessenger before the async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete List'),
        content: Text('Are you sure you want to delete "${listToDelete.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(listRepositoryProvider);
      await repo.safeDeleteList(listToDelete.id);

      if (mounted) { // Explicitly check mounted before using context
        // The ref.listen will handle the removeItem animation
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text('List "${listToDelete.title}" deleted.'),
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }
}
