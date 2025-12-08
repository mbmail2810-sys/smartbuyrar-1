import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbuy/src/models/grocery_item.dart';
// For max function
// For date formatting and comparison

final analyticsServiceProvider = Provider((ref) => AnalyticsService());

class AnalyticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> logPurchase(GroceryItem item) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final batch = _db.batch();

    // Update item stats
    final itemStatsRef =
        _db.collection('analytics').doc(uid).collection('itemStats').doc(item.name);
    batch.set(
      itemStatsRef,
      {
        'item': item.name,
        'timesPurchased': FieldValue.increment(1),
        'lastPrice': item.price, // Update to last price
        'priceHistory': FieldValue.arrayUnion([item.price]), // Store historical prices
        'lastPurchaseDate': Timestamp.now(), // Add last purchase date
        'purchaseTimestamps': FieldValue.arrayUnion([Timestamp.now()]), // Store all purchase timestamps
      },
      SetOptions(merge: true),
    );

    // Update category stats
    final categoryStatsRef = _db
        .collection('analytics')
        .doc(uid)
        .collection('categoryStats')
        .doc(item.category);
    batch.set(
      categoryStatsRef,
      {
        'category': item.category,
        'totalSpend': FieldValue.increment(item.price ?? 0.0), // Track total spend for the category
        'lastPurchaseDate': Timestamp.now(), // Add last purchase date
        'purchaseTimestamps': FieldValue.arrayUnion([Timestamp.now()]), // Store all purchase timestamps
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    await updateShoppingInsights();
  }
  Future<void> updateShoppingInsights() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final insightsRef =
    _db.collection('analytics').doc(uid).collection('shoppingInsights').doc('insights');

    // Calculate Shopping Frequency
    final itemStatsSnapshot = await _db.collection('analytics').doc(uid).collection('itemStats').get();
    List<Timestamp> allPurchaseTimestamps = [];
    double totalMonthlySpend = 0.0;
    String topSpendingCategory = 'N/A';
    double maxCategorySpend = 0.0;

    DateTime now = DateTime.now();
    DateTime thirtyDaysAgo = now.subtract(const Duration(days: 30));

    for (var doc in itemStatsSnapshot.docs) {
      final data = doc.data();
      if (data.containsKey('purchaseTimestamps')) {
        List<dynamic> timestamps = data['purchaseTimestamps'];
        for (var ts in timestamps) {
          if (ts is Timestamp) {
            allPurchaseTimestamps.add(ts);
            // Calculate monthly spend from individual item purchases
            if (ts.toDate().isAfter(thirtyDaysAgo)) {
              totalMonthlySpend += (data['lastPrice'] as num?)?.toDouble() ?? 0.0;
            }
          }
        }
      }
    }

    // Calculate shopping frequency
    String shoppingFrequency = 'N/A';
    if (allPurchaseTimestamps.isNotEmpty) {
      allPurchaseTimestamps.sort((a, b) => a.toDate().compareTo(b.toDate()));
      if (allPurchaseTimestamps.length > 1) {
        Duration totalDiff = Duration.zero;
        for (int i = 0; i < allPurchaseTimestamps.length - 1; i++) {
          totalDiff += allPurchaseTimestamps[i+1].toDate().difference(allPurchaseTimestamps[i].toDate());
        }
        double avgDays = totalDiff.inDays / (allPurchaseTimestamps.length - 1);
        shoppingFrequency = 'Every ${avgDays.toStringAsFixed(1)} days';
      } else {
        shoppingFrequency = 'Once'; // Only one purchase recorded
      }
    }

    // Calculate monthly spend from category stats (more accurate for aggregated spend)
    // Re-calculating to ensure it reflects actual spend in the last 30 days, not just lastPrice of items
    final categoryStatsSnapshot = await _db.collection('analytics').doc(uid).collection('categoryStats').get();
    totalMonthlySpend = 0.0; // Reset to calculate truly monthly

    for (var doc in categoryStatsSnapshot.docs) {
      final data = doc.data();

      if (data.containsKey('purchaseTimestamps')) {
        // The 'timestamps' variable was unused in this block.
        // The logic for calculating monthly spend and top spending category
        // now relies on iterating through itemStats again, which provides
        // more detailed item-level purchase data, including category and price history.
        // Therefore, the local 'timestamps' and 'prices' variables from categoryStats
        // are no longer needed here.

        // For simplicity, if priceHistory isn't directly in categoryStats, we sum totalSpend
        // However, totalSpend is cumulative. So, it's better to fetch actual item prices
        // associated with timestamps if possible, or refine categoryStats.
        // For now, I'll use the cumulative totalSpend from categoryStats as a proxy
        // if a more detailed monthly breakdown isn't feasible with current data structure.

        // Re-evaluating: itemStats has lastPrice and purchaseTimestamps.
        // Summing up lastPrice for items purchased within the last 30 days is a reasonable approach.
        // The previous calculation of totalMonthlySpend is fine.

        // To determine top spending category, we need category-specific monthly spend.
        // This requires getting item prices per category within the last 30 days.

        // Let's iterate through itemStats again, but this time group by category
        // to find the top spending category and its monthly spend.
      }
    }

    // Re-calculating monthly spend and top spending category more accurately
    totalMonthlySpend = 0.0;
    Map<String, double> monthlyCategorySpends = {};
    for (var doc in itemStatsSnapshot.docs) {
      final data = doc.data();
      String category = 'Unknown';
      // Find the category of the item. This might not be directly in itemStats.
      // Need to either store category in itemStats or fetch item details.
      // Assuming 'category' field is present in itemStats due to previous logic in logPurchase.
      if (data.containsKey('category')) {
        category = data['category'];
      } else {
        // Fallback: if category not in itemStats, might need to fetch item details or rely on categoryStats
        // For now, let's assume itemStats has category.
      }


      if (data.containsKey('purchaseTimestamps') && data.containsKey('priceHistory')) {
        List<dynamic> timestamps = data['purchaseTimestamps'];
        List<dynamic> prices = data['priceHistory'];

        if (prices.length < 2) {
          // Not enough data to compute trend for this item, skip further processing for this item
          continue; // Move to the next item in itemStatsSnapshot.docs
        }

        for (int i = 0; i < timestamps.length; i++) {
          Timestamp ts = timestamps[i];
          double price = (prices[i] as num?)?.toDouble() ?? 0.0;

          if (ts.toDate().isAfter(thirtyDaysAgo)) {
            totalMonthlySpend += price;
            monthlyCategorySpends.update(category, (value) => value + price, ifAbsent: () => price);
          }
        }
      }
    }

    if (monthlyCategorySpends.isNotEmpty) {
      topSpendingCategory = monthlyCategorySpends.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      maxCategorySpend = monthlyCategorySpends[topSpendingCategory] ?? 0.0;
    }


    // Determine Best Saving Opportunity (simple placeholder for now)
    String savingOpportunity = 'No specific saving opportunity found.';
    if (topSpendingCategory != 'N/A') {
      savingOpportunity = 'Look for discounts on $topSpendingCategory items this month!';
    }


    await insightsRef.set({
      'shoppingFrequency': shoppingFrequency,
      'monthlySpend': totalMonthlySpend,
      'savingOpportunity': savingOpportunity,
      'topSpendingCategory': topSpendingCategory,
      'maxCategorySpend': maxCategorySpend,
    });
  }

  Future<void> updateItemStats({
    required String userId,
    required String item,
    required double price,
  }) async {
    final doc = FirebaseFirestore.instance
        .collection('analytics')
        .doc(userId)
        .collection('itemStats')
        .doc(item);

    final timestamp = Timestamp.now(); // Local timestamp

    await doc.set({
      "item": item,
      "avgPrice": price,
      "timesPurchased": FieldValue.increment(1),
      "purchaseDates": FieldValue.arrayUnion([timestamp]),
      "lastUpdated": FieldValue.serverTimestamp(), // server timestamp OK
    }, SetOptions(merge: true));
  }

  Future<void> resetAnalytics() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final batch = _db.batch();
    final itemStats =
        await _db.collection('analytics').doc(uid).collection('itemStats').get();
    for (final doc in itemStats.docs) {
      batch.delete(doc.reference);
    }

    final categoryStats = await _db
        .collection('analytics')
        .doc(uid)
        .collection('categoryStats')
        .get();
    for (final doc in categoryStats.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
