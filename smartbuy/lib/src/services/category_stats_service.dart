import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryStatsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> updateCategoryStats({
    required String userId,
    required String category,
    required double price,
  }) async {
    final categoryRef = _db
        .collection('analytics')
        .doc(userId)
        .collection('categoryStats')
        .doc(category);

    final doc = await categoryRef.get();
    final now = Timestamp.now();

    if (!doc.exists) {
      // FIRST TIME CATEGORY CREATION
      await categoryRef.set({
        "category": category,
        "itemsPurchased": 1,
        "totalSpend": price,
        "avgSpend": price,
        "frequencyPerMonth": 1,
        "lastUpdated": now,
        "purchaseHistory": [now], // Store the purchase timestamp
      });
    } else {
      final data = doc.data()!;

      final oldItems = data["itemsPurchased"] ?? 0;
      final oldAvgSpend = data["avgSpend"] ?? 0.0;

      // New average monthly spend = weighted average
      final newAvgSpend = ((oldAvgSpend * oldItems) + price) / (oldItems + 1);

      await categoryRef.update({
        "itemsPurchased": FieldValue.increment(1),
        "totalSpend": FieldValue.increment(price), // Increment total spend
        "avgSpend": newAvgSpend,
        "frequencyPerMonth": FieldValue.increment(1),
        "lastUpdated": now,
        "purchaseHistory": FieldValue.arrayUnion([now]), // Add new timestamp to history
      });
    }
  }

  Future<Map<String, dynamic>?> getCategoryStats({
    required String userId,
    required String category,
  }) async {
    final doc = await _db
        .collection('analytics')
        .doc(userId)
        .collection('categoryStats')
        .doc(category)
        .get();

    return doc.data();
  }

  Future<List<Map<String, dynamic>>> getAllCategoryStats(String userId) async {
    final querySnapshot = await _db
        .collection('analytics')
        .doc(userId)
        .collection('categoryStats')
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<double> getTotalSpendForAllCategories(String userId) async {
    final allStats = await getAllCategoryStats(userId);
    return allStats.fold<double>(0.0, (totalSum, stats) => totalSum + ((stats['totalSpend'] as num?)?.toDouble() ?? 0.0));
  }

  // Method to determine the most frequent purchase day for a category
  String getMostFrequentPurchaseDay(List<dynamic> purchaseHistory) {
    if (purchaseHistory.isEmpty) {
      return 'N/A';
    }

    final Map<int, int> dayOfWeekCounts = {}; // Sunday = 0, Monday = 1, ..., Saturday = 6

    for (var timestamp in purchaseHistory) {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        continue; // Skip invalid entries
      }
      final dayOfWeek = date.weekday; // Monday = 1, ..., Sunday = 7
      // Convert to 0-6 range where Sunday is 0 for easier display
      final normalizedDay = dayOfWeek == DateTime.sunday ? 0 : dayOfWeek;
      dayOfWeekCounts[normalizedDay] = (dayOfWeekCounts[normalizedDay] ?? 0) + 1;
    }

    if (dayOfWeekCounts.isEmpty) {
      return 'N/A';
    }

    int? mostFrequentDay;
    int maxCount = 0;

    dayOfWeekCounts.forEach((day, itemCount) {
      if (itemCount > maxCount) {
        maxCount = itemCount;
        mostFrequentDay = day;
      }
    });

    if (mostFrequentDay == null) {
      return 'N/A';
    }

    switch (mostFrequentDay) {
      case 0: return 'Sundays';
      case 1: return 'Mondays';
      case 2: return 'Tuesdays';
      case 3: return 'Wednesdays';
      case 4: return 'Thursdays';
      case 5: return 'Fridays';
      case 6: return 'Saturdays';
      default: return 'N/A';
    }
  }
}
