import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      appBar: AppBar(title: const Text("Pantry Stock")),
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
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final items = snapshot.data!.docs;

        if (items.isEmpty) {
          return const Center(child: Text("Your pantry is empty"));
        }

        return ListView(
          children: items.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final analysis = PantryAI.analyzePantryItem(data);
            final itemName = data["item"] as String;
            final quantity = data["quantity"] as int;
            final expiresAtTimestamp = data["expiresAt"] as Timestamp?;
            final lowStockThreshold = data["lowStockThreshold"] as int? ?? 2;

            DateTime? expiresAt = expiresAtTimestamp?.toDate();

            return ListTile(
              onTap: () => _showPantryItemDialog(
                context,
                ref,
                itemName: itemName,
                quantity: quantity,
                expiresAt: expiresAt,
                lowStockThreshold: lowStockThreshold,
                isEdit: true,
              ),
              title: Text(itemName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Qty: $quantity — ${analysis["status"]}"),
                  if (expiresAt != null)
                    Text("Expires: ${DateFormat("yyyy-MM-dd").format(expiresAt)}"),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  analysis["needsRestock"]
                      ? const Icon(Icons.warning, color: Colors.orange)
                      : const Icon(Icons.check_circle, color: Colors.green),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () async {
                      await PantryService.consumeItem(data["item"] as String);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Consumed ${data["item"]}"),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  if (analysis["needsRestock"])
                    IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () async {
                        _showGroceryListSelectionDialog(context, ref, data);
                      },
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
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
                      enabled: !isEdit, // Item name cannot be edited
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
                            quantity: 1, // Default quantity for restock
                            category: "General", // Or try to infer category
                            checked: false,
                            createdAt: DateTime.now(),
                            createdBy: list.ownerId, // Or current user id
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
                      // Option to create a new list, if desired.
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
