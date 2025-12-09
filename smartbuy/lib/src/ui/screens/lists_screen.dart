import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'list_detail_screen.dart';
import '../../providers/auth_providers.dart';
import '../../providers/list_providers.dart';
import '../../providers/item_providers.dart';
import '../../models/grocery_list.dart';
import '../widgets/share_list_bottom_sheet.dart';
import 'package:go_router/go_router.dart';

class ListsScreen extends ConsumerStatefulWidget {
  const ListsScreen({super.key});

  @override
  ConsumerState<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends ConsumerState<ListsScreen> {
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(userListsProvider);
    final user = ref.watch(authStateProvider).value;
    final userName = user?.displayName ?? user?.email?.split('@').first ?? 'User';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(userName),
            _buildSearchBar(),
            _buildCategoriesSection(),
            _buildTabButtons(listsAsync),
            Expanded(
              child: _buildListsContent(listsAsync, user?.uid),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                userName,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildIconButton(
                Icons.bar_chart_rounded,
                onTap: () => GoRouter.of(context).go('/insights'),
              ),
              const SizedBox(width: 10),
              _buildAvatarButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF00B200), size: 24),
      ),
    );
  }

  Widget _buildAvatarButton() {
    final user = ref.watch(authStateProvider).value;
    final initial = (user?.displayName?.isNotEmpty == true
            ? user!.displayName![0]
            : user?.email?.isNotEmpty == true
                ? user!.email![0]
                : 'U')
        .toUpperCase();

    return GestureDetector(
      onTap: () => GoRouter.of(context).go('/profile'),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF00B200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            initial,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search items or lists...',
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
            suffixIcon: Icon(Icons.mic, color: Colors.grey.shade400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'See all',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF00B200),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryItem('Fruits', '🍎', const Color(0xFFFFEBEE)),
              _buildCategoryItem('Vegetables', '🥬', const Color(0xFFE8F5E9)),
              _buildCategoryItem('Dairy', '🧀', const Color(0xFFFFF3E0)),
              _buildCategoryItem('Bakery', '🥐', const Color(0xFFFFF8E1)),
              _buildCategoryItem('Meat', '🍖', const Color(0xFFFFEBEE)),
              _buildCategoryItem('Beverages', '🥤', const Color(0xFFE3F2FD)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String name, String emoji, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButtons(AsyncValue<List<GroceryList>> listsAsync) {
    final user = ref.watch(authStateProvider).value;
    final myListsCount = listsAsync.whenOrNull(
          data: (lists) => lists.where((l) => l.ownerId == user?.uid).length,
        ) ??
        0;
    final sharedCount = listsAsync.whenOrNull(
          data: (lists) => lists.where((l) => l.ownerId != user?.uid).length,
        ) ??
        0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          _buildTabButton('My Lists ($myListsCount)', 0),
          const SizedBox(width: 10),
          _buildTabButton('Shared${sharedCount > 0 ? ' ($sharedCount)' : ''}', 1,
              icon: Icons.people_outline),
          const Spacer(),
          _buildNewButton(),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, {IconData? icon}) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00B200) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF00B200) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewButton() {
    return GestureDetector(
      onTap: () => _showAddListDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF00B200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.add, size: 18, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'New',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListsContent(AsyncValue<List<GroceryList>> listsAsync, String? userId) {
    return listsAsync.when(
      data: (lists) {
        List<GroceryList> filteredLists;
        if (_selectedTab == 0) {
          filteredLists = lists.where((l) => l.ownerId == userId).toList();
        } else {
          filteredLists = lists.where((l) => l.ownerId != userId).toList();
        }

        if (_searchQuery.isNotEmpty) {
          filteredLists = filteredLists
              .where((l) => l.title.toLowerCase().contains(_searchQuery))
              .toList();
        }

        if (filteredLists.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filteredLists.length,
          itemBuilder: (context, index) {
            return _buildListCard(filteredLists[index], userId);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _selectedTab == 0 ? 'No lists yet' : 'No shared lists',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedTab == 0
                ? 'Tap + New to create your first list!'
                : 'Lists shared with you will appear here',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(GroceryList list, String? userId) {
    final isOwner = list.ownerId == userId;

    return Consumer(
      builder: (context, ref, child) {
        final itemsAsync = ref.watch(listItemsProvider(list.id));

        return itemsAsync.when(
          data: (items) {
            final totalItems = items.length;
            final checkedItems = items.where((i) => i.checked).length;
            final progress = totalItems > 0 ? checkedItems / totalItems : 0.0;
            final progressPercent = (progress * 100).round();

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListDetailScreen(
                      listId: list.id,
                      listTitle: list.title,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: list.categoryEmoji != null && list.categoryEmoji!.isNotEmpty
                                ? Text(
                                    list.categoryEmoji!,
                                    style: const TextStyle(fontSize: 24),
                                  )
                                : const Icon(
                                    Icons.shopping_bag_outlined,
                                    color: Color(0xFF00B200),
                                    size: 24,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                list.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$totalItems items',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                          onSelected: (value) {
                            if (value == 'share' && list.canShare(userId ?? '')) {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => ShareListBottomSheet(list: list),
                              );
                            } else if (value == 'delete' && isOwner) {
                              _deleteList(context, ref, list);
                            }
                          },
                          itemBuilder: (context) => [
                            if (list.canShare(userId ?? ''))
                              const PopupMenuItem(
                                value: 'share',
                                child: Row(
                                  children: [
                                    Icon(Icons.share, size: 20),
                                    SizedBox(width: 8),
                                    Text('Share'),
                                  ],
                                ),
                              ),
                            if (isOwner)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$progressPercent% bought',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    progress >= 1.0
                                        ? const Color(0xFF00B200)
                                        : progress >= 0.5
                                            ? Colors.amber
                                            : Colors.orange,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$checkedItems/$totalItems',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    if (list.budget != null && list.budget! > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            'Budget: ₹${list.budget?.toStringAsFixed(0)} • Spent: ₹${(list.spent ?? 0).toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: (list.spent ?? 0) > (list.budget ?? 0)
                                  ? Colors.red
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
          loading: () => _buildLoadingCard(list),
          error: (_, __) => _buildLoadingCard(list),
        );
      },
    );
  }

  Widget _buildLoadingCard(GroceryList list) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Color(0xFF00B200),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  list.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const SizedBox(
                  width: 60,
                  height: 12,
                  child: LinearProgressIndicator(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddListDialog(BuildContext context, WidgetRef ref) {
    final titleCtl = TextEditingController();
    final budgetCtl = TextEditingController();
    String selectedCategory = 'General';
    String selectedEmoji = '🛒';

    final categories = [
      {'name': 'General', 'emoji': '🛒', 'color': const Color(0xFFF5F5F5)},
      {'name': 'Fruits', 'emoji': '🍎', 'color': const Color(0xFFFFEBEE)},
      {'name': 'Vegetables', 'emoji': '🥬', 'color': const Color(0xFFE8F5E9)},
      {'name': 'Dairy', 'emoji': '🧀', 'color': const Color(0xFFFFF3E0)},
      {'name': 'Bakery', 'emoji': '🥐', 'color': const Color(0xFFFFF8E1)},
      {'name': 'Meat', 'emoji': '🍖', 'color': const Color(0xFFFFEBEE)},
      {'name': 'Beverages', 'emoji': '🥤', 'color': const Color(0xFFE3F2FD)},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(c).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Create New List',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleCtl,
                  decoration: InputDecoration(
                    labelText: 'List Name',
                    hintText: 'e.g. Weekly Groceries',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00B200), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Category',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = selectedCategory == cat['name'];
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedCategory = cat['name'] as String;
                            selectedEmoji = cat['emoji'] as String;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFF00B200).withOpacity(0.15)
                                : cat['color'] as Color,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: const Color(0xFF00B200), width: 2)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                cat['emoji'] as String,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat['name'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? const Color(0xFF00B200) : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: budgetCtl,
                  decoration: InputDecoration(
                    labelText: 'Budget (optional)',
                    hintText: '₹0.00',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00B200), width: 2),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(c),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
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
                            'category': selectedCategory,
                            'categoryEmoji': selectedEmoji,
                            if (budget != null) 'budget': budget,
                          };

                          Navigator.pop(c);
                          
                          repo.safeCreateList(listData).then((_) {
                            scaffoldMessenger.showSnackBar(const SnackBar(
                              content: Text('List created successfully!'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Color(0xFF00B200),
                            ));
                          }).catchError((e) {
                            scaffoldMessenger.showSnackBar(SnackBar(
                              content: Text('Creating list... will sync when online'),
                              duration: Duration(seconds: 2),
                            ));
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B200),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Create',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteList(BuildContext context, WidgetRef ref, GroceryList listToDelete) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete List'),
        content: Text('Are you sure you want to delete "${listToDelete.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
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

      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text('List "${listToDelete.title}" deleted.'),
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }
}
