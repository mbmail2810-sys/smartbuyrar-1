import 'package:cloud_firestore/cloud_firestore.dart'; // Import Timestamp

class PantryAI {
  static Map<String, dynamic> analyzePantryItem(Map<dynamic, dynamic> itemData) {
    // Placeholder for pantry item analysis logic
    // This logic can be expanded based on specific requirements,
    // e.g., checking expiration dates, typical consumption rates, etc.

    final String itemName = itemData["item"] ?? "Unknown Item";
    final int quantity = itemData["quantity"] ?? 0;
    final int lowStockThreshold = itemData["lowStockThreshold"] ?? 2; // Use threshold from data
    final Timestamp? expiresAtTimestamp = itemData["expiresAt"] as Timestamp?;
    final double estimatedConsumptionRateDays = (itemData["estimatedConsumptionRateDays"] as num?)?.toDouble() ?? 0.0;

    String status;
    bool needsRestock;
    DateTime? expiresAt = expiresAtTimestamp?.toDate();

    // Calculate days until expiry
    int? daysUntilExpiry;
    if (expiresAt != null) {
      daysUntilExpiry = expiresAt.difference(DateTime.now()).inDays;
    }

    if (quantity == 0) {
      status = "$itemName is out of stock!";
      needsRestock = true;
    } else if (daysUntilExpiry != null && daysUntilExpiry <= 7 && quantity <= lowStockThreshold + 1) {
      // Nearing expiry within 7 days and low stock
      status = "$itemName expires in $daysUntilExpiry days and is running low.";
      needsRestock = true;
    } else if (daysUntilExpiry != null && daysUntilExpiry <= 7) {
      // Nearing expiry within 7 days, but not necessarily low stock
      status = "$itemName expires in $daysUntilExpiry days. Consider using soon!";
      needsRestock = false; // Not necessarily a restock, but a warning
    } else if (estimatedConsumptionRateDays > 0 && quantity <= (estimatedConsumptionRateDays / 7).ceil()) {
      // If consumption rate is available, predict if current quantity will last less than a week
      status = "$itemName is running low based on consumption. Restock soon!";
      needsRestock = true;
    } else if (quantity <= lowStockThreshold) {
      // Use dynamic low stock threshold
      status = "$itemName is running low.";
      needsRestock = true;
    } else {
      status = "$itemName is well stocked.";
      needsRestock = false;
    }

    return {
      "status": status,
      "needsRestock": needsRestock,
    };
  }
}
