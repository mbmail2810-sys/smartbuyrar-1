import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/grocery_list.dart';
import 'list_providers.dart';

class AggregatedSpending {
  final double totalSpentThisWeek;
  final double totalSpentLastWeek;
  final double totalSpentThisMonth;
  final double totalBudgetThisMonth;
  final List<DailySpending> weeklyBreakdown;
  final Map<String, double> categorySpending;
  final Map<String, int> categoryItemCounts;
  final double averageDailySpend;
  final int totalItemsPurchased;
  final List<GroceryList> listsWithBudget;
  final Map<String, int> itemFrequency;

  AggregatedSpending({
    required this.totalSpentThisWeek,
    required this.totalSpentLastWeek,
    required this.totalSpentThisMonth,
    required this.totalBudgetThisMonth,
    required this.weeklyBreakdown,
    required this.categorySpending,
    required this.categoryItemCounts,
    required this.averageDailySpend,
    required this.totalItemsPurchased,
    required this.listsWithBudget,
    required this.itemFrequency,
  });

  double get weekOverWeekChange {
    if (totalSpentLastWeek == 0) return 0;
    return ((totalSpentThisWeek - totalSpentLastWeek) / totalSpentLastWeek) * 100;
  }

  double get budgetUtilization {
    if (totalBudgetThisMonth == 0) return 0;
    return (totalSpentThisMonth / totalBudgetThisMonth) * 100;
  }
}

class DailySpending {
  final DateTime date;
  final double amount;
  final String dayLabel;

  DailySpending({required this.date, required this.amount, required this.dayLabel});
}

class SmartSpendSuggestion {
  final String type;
  final String title;
  final String description;
  final String? actionText;
  final double? savings;
  final String icon;
  final int priority;

  SmartSpendSuggestion({
    required this.type,
    required this.title,
    required this.description,
    this.actionText,
    this.savings,
    required this.icon,
    required this.priority,
  });
}

final aggregatedSpendingProvider = FutureProvider<AggregatedSpending>((ref) async {
  final listsAsync = await ref.watch(userListsProvider.future);
  final lists = listsAsync;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 7));
  final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));
  final startOfMonth = DateTime(now.year, now.month, 1);

  final Map<String, double> dailySpending = {};
  final Map<String, double> lastWeekDaily = {};
  final Map<String, double> categorySpending = {};
  final Map<String, int> categoryItemCounts = {};
  final Map<String, int> itemFrequency = {};
  
  final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  
  for (int i = 0; i < 7; i++) {
    final date = startOfWeek.add(Duration(days: i));
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    dailySpending[dateKey] = 0;
  }
  
  for (int i = 0; i < 7; i++) {
    final date = startOfLastWeek.add(Duration(days: i));
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    lastWeekDaily[dateKey] = 0;
  }

  double totalThisMonth = 0;
  double totalBudget = 0;
  int totalItems = 0;
  final listsWithBudget = <GroceryList>[];

  for (final list in lists) {
    if (list.budget != null && list.budget! > 0) {
      totalBudget += list.budget!;
      listsWithBudget.add(list);
    }

    final purchaseLog = list.purchaseLog ?? [];
    for (final entry in purchaseLog) {
      try {
        final dateMs = entry['date'];
        if (dateMs == null) continue;

        final int timestamp = dateMs is int ? dateMs : (dateMs as num).toInt();
        final dateTimeUtc = DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
        final dateTime = dateTimeUtc.toLocal();
        final purchaseDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
        final dateKey = '${purchaseDate.year}-${purchaseDate.month.toString().padLeft(2, '0')}-${purchaseDate.day.toString().padLeft(2, '0')}';

        final totalRaw = entry['total'];
        final total = totalRaw is num ? totalRaw.toDouble() : 0.0;
        final category = entry['category'] as String? ?? 'General';
        final itemName = entry['itemName'] as String? ?? 'Unknown';
        final quantity = entry['quantity'] is num ? (entry['quantity'] as num).toInt() : 1;

        final isThisWeek = !purchaseDate.isBefore(startOfWeek) && purchaseDate.isBefore(endOfWeek);
        if (isThisWeek) {
          dailySpending[dateKey] = (dailySpending[dateKey] ?? 0) + total;
        }

        final isLastWeek = !purchaseDate.isBefore(startOfLastWeek) && purchaseDate.isBefore(startOfWeek);
        if (isLastWeek) {
          lastWeekDaily[dateKey] = (lastWeekDaily[dateKey] ?? 0) + total;
        }

        final isThisMonth = !purchaseDate.isBefore(startOfMonth);
        if (isThisMonth) {
          totalThisMonth += total;
          categorySpending[category] = (categorySpending[category] ?? 0) + total;
          categoryItemCounts[category] = (categoryItemCounts[category] ?? 0) + quantity;
          itemFrequency[itemName] = (itemFrequency[itemName] ?? 0) + quantity;
          totalItems += quantity;
        }
      } catch (_) {
        continue;
      }
    }
  }

  final weeklyBreakdown = <DailySpending>[];
  final thisWeekKeys = <String>[];
  for (int i = 0; i < 7; i++) {
    final date = startOfWeek.add(Duration(days: i));
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    thisWeekKeys.add(dateKey);
    weeklyBreakdown.add(DailySpending(
      date: date,
      amount: dailySpending[dateKey] ?? 0,
      dayLabel: dayLabels[i],
    ));
  }

  final lastWeekKeys = <String>[];
  for (int i = 0; i < 7; i++) {
    final date = startOfLastWeek.add(Duration(days: i));
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    lastWeekKeys.add(dateKey);
  }

  final thisWeekTotal = thisWeekKeys.fold(0.0, (sum, key) => sum + (dailySpending[key] ?? 0));
  final lastWeekTotal = lastWeekKeys.fold(0.0, (sum, key) => sum + (lastWeekDaily[key] ?? 0));
  final daysInMonth = now.day;
  final avgDaily = daysInMonth > 0 ? totalThisMonth / daysInMonth : 0.0;

  return AggregatedSpending(
    totalSpentThisWeek: thisWeekTotal,
    totalSpentLastWeek: lastWeekTotal,
    totalSpentThisMonth: totalThisMonth,
    totalBudgetThisMonth: totalBudget,
    weeklyBreakdown: weeklyBreakdown,
    categorySpending: categorySpending,
    categoryItemCounts: categoryItemCounts,
    averageDailySpend: avgDaily,
    totalItemsPurchased: totalItems,
    listsWithBudget: listsWithBudget,
    itemFrequency: itemFrequency,
  );
});

final smartSpendSuggestionsProvider = FutureProvider<List<SmartSpendSuggestion>>((ref) async {
  final spending = await ref.watch(aggregatedSpendingProvider.future);
  final lists = await ref.watch(userListsProvider.future);
  
  final suggestions = <SmartSpendSuggestion>[];

  if (spending.budgetUtilization > 90 && spending.totalBudgetThisMonth > 0) {
    suggestions.add(SmartSpendSuggestion(
      type: 'budget_alert',
      title: 'Budget Nearly Exhausted',
      description: 'You\'ve used ${spending.budgetUtilization.toStringAsFixed(0)}% of your monthly budget. Consider reviewing upcoming purchases.',
      icon: 'warning',
      priority: 1,
    ));
  }

  if (spending.weekOverWeekChange > 25) {
    final increase = spending.weekOverWeekChange.toStringAsFixed(0);
    suggestions.add(SmartSpendSuggestion(
      type: 'spending_trend',
      title: 'Spending Up This Week',
      description: 'Your spending increased by $increase% compared to last week. Track your purchases to stay on budget.',
      icon: 'trending_up',
      priority: 2,
    ));
  } else if (spending.weekOverWeekChange < -20 && spending.totalSpentLastWeek > 0) {
    final decrease = (-spending.weekOverWeekChange).toStringAsFixed(0);
    suggestions.add(SmartSpendSuggestion(
      type: 'spending_trend',
      title: 'Great Savings This Week!',
      description: 'You spent $decrease% less than last week. Keep up the good budgeting!',
      icon: 'savings',
      priority: 3,
    ));
  }

  if (spending.categorySpending.isNotEmpty) {
    final sortedCategories = spending.categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sortedCategories.isNotEmpty) {
      final topCategory = sortedCategories.first;
      final totalSpent = spending.categorySpending.values.fold(0.0, (a, b) => a + b);
      final percentage = totalSpent > 0 ? (topCategory.value / totalSpent * 100) : 0;
      
      if (percentage > 40) {
        suggestions.add(SmartSpendSuggestion(
          type: 'category_insight',
          title: 'High ${topCategory.key} Spending',
          description: '${percentage.toStringAsFixed(0)}% of your spending is on ${topCategory.key}. Consider comparing prices or buying in bulk.',
          actionText: 'View alternatives',
          icon: 'pie_chart',
          priority: 2,
        ));
      }
    }
  }

  for (final list in lists) {
    if (list.budget != null && list.budget! > 0) {
      final utilization = (list.spent ?? 0) / list.budget! * 100;
      if (utilization > 100) {
        final over = ((list.spent ?? 0) - list.budget!).toStringAsFixed(2);
        suggestions.add(SmartSpendSuggestion(
          type: 'list_budget',
          title: '"${list.title}" Over Budget',
          description: 'This list is ₹$over over budget. Review items before your next shop.',
          icon: 'error_outline',
          priority: 1,
        ));
      }
    }
  }

  if (spending.averageDailySpend > 0) {
    final daysRemaining = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day - DateTime.now().day;
    final projectedTotal = spending.totalSpentThisMonth + (spending.averageDailySpend * daysRemaining);
    
    if (spending.totalBudgetThisMonth > 0 && projectedTotal > spending.totalBudgetThisMonth * 1.1) {
      final overBy = (projectedTotal - spending.totalBudgetThisMonth).toStringAsFixed(2);
      suggestions.add(SmartSpendSuggestion(
        type: 'projection',
        title: 'Projected Overspend',
        description: 'At current pace, you\'ll exceed budget by ₹$overBy this month. Reduce daily spending to stay on track.',
        savings: projectedTotal - spending.totalBudgetThisMonth,
        icon: 'timeline',
        priority: 1,
      ));
    }
  }

  if (spending.itemFrequency.isNotEmpty) {
    final frequentItems = spending.itemFrequency.entries
        .where((e) => e.value >= 3)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (frequentItems.isNotEmpty) {
      final top = frequentItems.first;
      suggestions.add(SmartSpendSuggestion(
        type: 'bulk_buy',
        title: 'Consider Bulk Buying ${top.key}',
        description: 'You bought ${top.key} ${top.value} times this month. Buying in bulk could save money.',
        icon: 'inventory_2',
        priority: 3,
      ));
    }
  }

  final highSpendDays = spending.weeklyBreakdown
      .where((d) => d.amount > spending.averageDailySpend * 1.5 && d.amount > 0)
      .toList();
  
  if (highSpendDays.isNotEmpty && spending.averageDailySpend > 0) {
    final days = highSpendDays.map((d) => d.dayLabel).join(', ');
    suggestions.add(SmartSpendSuggestion(
      type: 'pattern',
      title: 'Peak Shopping Days',
      description: 'You spend more on $days. Planning ahead for these days can help control spending.',
      icon: 'calendar_today',
      priority: 3,
    ));
  }

  if (suggestions.isEmpty) {
    suggestions.add(SmartSpendSuggestion(
      type: 'default',
      title: 'Keep Up the Good Work!',
      description: 'Your spending patterns look healthy. Continue tracking to build more insights.',
      icon: 'thumb_up',
      priority: 4,
    ));
  }

  suggestions.sort((a, b) => a.priority.compareTo(b.priority));
  
  return suggestions.take(5).toList();
});

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
