import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/pantry_service.dart';
import '../../services/pantry_ai.dart';
import '../../providers/list_providers.dart' as list_providers;
import '../../models/grocery_item.dart';

class PantryScreen extends ConsumerWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Pantry Stock",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey.shade50,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _buildPantryList(context, ref),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPantryItemDialog(
          context,
          ref,
          itemName: "",
          quantity: 1,
          isEdit: false,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPantryList(BuildContext context, WidgetRef ref) {
    return StreamBuilder(
      stream: PantryService.pantryStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!.docs;

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.kitchen, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  "Your pantry is empty",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Tap + to add items",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final doc = items[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildPantryCard(context, ref, data);
          },
        );
      },
    );
  }

  Widget _buildPantryCard(BuildContext context, WidgetRef ref, Map<String, dynamic> data) {
    final analysis = PantryAI.analyzePantryItem(data);
    final itemName = data["item"] as String;
    final quantity = data["quantity"] as int;
    final expiresAtTimestamp = data["expiresAt"] as Timestamp?;
    final lowStockThreshold = data["lowStockThreshold"] as int? ?? 2;
    final needsRestock = analysis["needsRestock"] as bool;

    DateTime? expiresAt = expiresAtTimestamp?.toDate();
    
    final bool isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now());
    final bool isExpiringSoon = expiresAt != null && 
        !isExpired && 
        expiresAt.difference(DateTime.now()).inDays <= 3;
    final bool isLowStock = needsRestock;
    final bool isOutOfStock = quantity <= 0;

    Color statusColor;
    String statusText;
    IconData statusIcon;
    Color cardBorderColor;

    if (isOutOfStock) {
      statusColor = Colors.red;
      statusText = 'Out of stock';
      statusIcon = Icons.error;
      cardBorderColor = Colors.red;
    } else if (isExpired) {
      statusColor = Colors.red;
      statusText = 'Expired';
      statusIcon = Icons.error;
      cardBorderColor = Colors.red;
    } else if (isExpiringSoon) {
      statusColor = Colors.orange;
      statusText = 'Expiring soon';
      statusIcon = Icons.warning;
      cardBorderColor = Colors.orange;
    } else if (isLowStock) {
      statusColor = Colors.amber.shade700;
      statusText = 'Low stock';
      statusIcon = Icons.inventory_2;
      cardBorderColor = Colors.amber;
    } else {
      statusColor = Colors.green;
      statusText = 'Well stocked';
      statusIcon = Icons.check_circle;
      cardBorderColor = Colors.green;
    }

    final double stockPercentage = lowStockThreshold > 0 
        ? (quantity / (lowStockThreshold * 3)).clamp(0.0, 1.0)
        : 1.0;

    return GestureDetector(
      onTap: () => _showPantryItemDialog(
        context,
        ref,
        itemName: itemName,
        quantity: quantity,
        expiresAt: expiresAt,
        lowStockThreshold: lowStockThreshold,
        isEdit: true,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cardBorderColor.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            if (expiresAt != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.event,
                                size: 14,
                                color: isExpired || isExpiringSoon ? statusColor : Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatExpiryDate(expiresAt),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: isExpired || isExpiringSoon ? statusColor : Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '$quantity',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quantity == 1 ? 'unit' : 'units',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: stockPercentage,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(statusColor),
                  minHeight: 4,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _actionButton(
                    icon: Icons.remove_circle_outline,
                    label: 'Use',
                    color: Colors.grey[700]!,
                    onPressed: () async {
                      await PantryService.consumeItem(itemName);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Used 1 $itemName"),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  if (needsRestock) ...[
                    const SizedBox(width: 8),
                    _actionButton(
                      icon: Icons.add_shopping_cart,
                      label: 'Restock',
                      color: Colors.blue,
                      onPressed: () => _showGroceryListSelectionDialog(context, ref, data),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatExpiryDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(date.year, date.month, date.day);
    final diff = expiryDay.difference(today).inDays;
    
    if (diff < 0) return '${-diff}d ago';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff <= 7) return 'In $diff days';
    
    return DateFormat('MMM d').format(date);
  }

  void _showPantryItemDialog(
    BuildContext context,
    WidgetRef ref, {
    required String itemName,
    required int quantity,
    DateTime? expiresAt,
    int? lowStockThreshold,
    bool isEdit = false,
  }) {
    final nameController = TextEditingController(text: itemName);
    final qtyController = TextEditingController(text: quantity.toString());
    final lowStockController = TextEditingController(text: lowStockThreshold.toString());
    DateTime? selectedDate = expiresAt;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? "Edit Pantry Item" : "Add Pantry Item"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Item Name"),
                      enabled: !isEdit,
                    ),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Quantity"),
                    ),
                    TextField(
                      controller: lowStockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Low Stock Threshold"),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                            "Expires At: ${selectedDate == null ? "Not Set" : DateFormat("yyyy-MM-dd").format(selectedDate!)}"),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setDialogState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => navigator.pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final qty = int.tryParse(qtyController.text) ?? 0;
                    final threshold = int.tryParse(lowStockController.text) ?? 2;

                    if (name.isEmpty || qty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a valid item name and quantity.")),
                      );
                      return;
                    }

                    if (isEdit) {
                      await PantryService.updatePantryItem(
                        name,
                        quantity: qty,
                        expiresAt: selectedDate,
                        lowStockThreshold: threshold,
                      );
                    } else {
                      await PantryService.addToPantry(
                        name,
                        qty: qty,
                        expiresAt: selectedDate,
                        lowStockThreshold: threshold,
                      );
                    }
                    navigator.pop();
                  },
                  child: Text(isEdit ? "Update" : "Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGroceryListSelectionDialog(
      BuildContext context, WidgetRef ref, Map<String, dynamic> itemData) {
    final listsAsyncValue = ref.watch(list_providers.userListsProvider);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Add to Grocery List"),
          content: listsAsyncValue.when(
            data: (lists) {
              if (lists.isEmpty) {
                return const Text("No grocery lists found. Please create one first.");
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...lists.map((list) => ListTile(
                        title: Text(list.title),
                        onTap: () async {
                          final navigator = Navigator.of(dialogContext);
                          final newItem = GroceryItem(
                            id: "",
                            name: itemData["item"],
                            description: "Restock from pantry",
                            price: 0.0,
                            quantity: 1,
                            category: "General",
                            checked: false,
                            createdAt: DateTime.now(),
                            createdBy: list.ownerId,
                          );

                          await ref
                              .read(list_providers.listRepositoryProvider)
                              .safeAddItem(list.id,
                                  newItem);
                          if (!dialogContext.mounted) return;
                          navigator.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("Added ${itemData["item"]} to ${list.title}!")),
                          );
                        },
                      )),
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Create new list functionality not yet implemented.")),
                      );
                    },
                    child: const Text("Create New List"),
                  ),
                ],
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, stack) => Text("Error loading lists: $e"),
          ),
        );
      },
    );
  }
}
