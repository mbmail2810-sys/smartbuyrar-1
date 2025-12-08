import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grocery_item.dart';

class SuggestionEngine {
  /// Calculates score using usage frequency & recency
  static double score(GroceryItem item) {
    if (item.priceHistory == null && item.usageLog == null) return 0;

    final usage = item.usageLog?.length ?? 0;

    final lastDateRaw = item.usageLog?.isNotEmpty == true
        ? item.usageLog!.last["date"]
        : null;

    final lastDateMs = _normalizeDate(lastDateRaw);

    final recency = lastDateMs > 0
        ? DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(lastDateMs))
            .inDays
        : 999;

    return (usage * 2) + (100 / (recency + 1));
  }

  static int _normalizeDate(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is Timestamp) return val.millisecondsSinceEpoch;
    return 0;
  }
}
