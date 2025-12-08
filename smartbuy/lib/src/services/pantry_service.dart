import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod

class PantryService {
  static final _db = FirebaseFirestore.instance;
  static final _uid = FirebaseAuth.instance.currentUser!.uid;

  static Future<void> addToPantry(String item,
      {required int qty, DateTime? expiresAt, int? lowStockThreshold}) async {
    final ref = _db.collection('pantry').doc(_uid).collection('items').doc(item);

    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        "item": item,
        "quantity": qty,
        "unit": "unit",
        "lastUpdated": Timestamp.now(),
        "estimatedConsumptionRateDays": 0,
        "expiresAt": expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
        "lowStockThreshold": lowStockThreshold ?? 2,
      });
    } else {
      await ref.update({
        "quantity": FieldValue.increment(qty),
        "lastUpdated": Timestamp.now(),
        if (expiresAt != null) "expiresAt": Timestamp.fromDate(expiresAt),
        if (lowStockThreshold != null) "lowStockThreshold": lowStockThreshold,
      });
    }
  }

  static Future<void> updatePantryItem(String item, {
    int? quantity,
    DateTime? expiresAt,
    int? lowStockThreshold,
  }) async {
    final ref = _db.collection('pantry').doc(_uid).collection('items').doc(item);
    Map<String, dynamic> updateData = {
      "lastUpdated": Timestamp.now(),
    };
    if (quantity != null) {
      updateData["quantity"] = quantity;
    }
    if (expiresAt != null) {
      updateData["expiresAt"] = Timestamp.fromDate(expiresAt);
    }
    if (lowStockThreshold != null) {
      updateData["lowStockThreshold"] = lowStockThreshold;
    }
    await ref.update(updateData);
  }

  static Future<void> consumeItem(String item) async {
    final ref = _db.collection('pantry').doc(_uid).collection('items').doc(item);
    final doc = await ref.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final qty = data["quantity"];

    if (qty > 0) {
      final now = Timestamp.now();
      double newConsumptionRate = data["estimatedConsumptionRateDays"] ?? 0;
      Timestamp? effectiveLastEvent = data["lastConsumed"] ?? data["lastUpdated"]; // Use lastUpdated as fallback

      if (effectiveLastEvent != null) {
        final daysSinceLastEvent =
            now.toDate().difference(effectiveLastEvent.toDate()).inDays;

        if (daysSinceLastEvent > 0) {
          final oldConsumptionRate = newConsumptionRate;
          if (oldConsumptionRate > 0) {
            // Using a simple moving average with alpha = 0.5 for smoothing
            newConsumptionRate =
                (0.5 * daysSinceLastEvent) + (0.5 * oldConsumptionRate);
          } else {
            newConsumptionRate = daysSinceLastEvent.toDouble();
          }
        }
      }

      await ref.update({
        "quantity": qty - 1,
        "lastUpdated": now,
        "lastConsumed": now,
        "estimatedConsumptionRateDays": newConsumptionRate,
      });
    }
  }

  static Stream<QuerySnapshot> pantryStream() {
    return _db.collection('pantry').doc(_uid).collection('items').snapshots();
  }
}

// Riverpod Provider for PantryService
final pantryServiceProvider = Provider<PantryService>((ref) {
  return PantryService();
});
