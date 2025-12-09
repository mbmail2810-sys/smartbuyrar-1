import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartbuy/src/services/analytics_service.dart';
import 'package:smartbuy/src/services/pantry_service.dart';
import 'package:smartbuy/src/services/category_stats_service.dart';
import 'package:smartbuy/src/providers/insights_provider.dart';
import 'package:fl_chart/fl_chart.dart';

final categoryStatsServiceProvider = Provider((ref) => CategoryStatsService());

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text("Not logged in"));
    }

    final aggregatedSpending = ref.watch(aggregatedSpendingProvider);
    final smartSuggestions = ref.watch(smartSpendSuggestionsProvider);

    final categoryStream = FirebaseFirestore.instance
        .collection('analytics')
        .doc(uid)
        .collection('categoryStats')
        .snapshots();

    final shoppingInsightsStream = FirebaseFirestore.instance
        .collection('analytics')
        .doc(uid)
        .collection('shoppingInsights')
        .doc('insights')
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Insights",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey.shade50,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(aggregatedSpendingProvider);
              ref.invalidate(smartSpendSuggestionsProvider);
              ref.read(analyticsServiceProvider).resetAnalytics();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header("Smart Spend"),
            const SizedBox(height: 8),
            smartSuggestions.when(
              data: (suggestions) => _buildSmartSpendSection(context, suggestions),
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )),
              error: (_, __) => const Padding(
                padding: EdgeInsets.all(16),
                child: Text("Unable to load suggestions"),
              ),
            ),

            const SizedBox(height: 20),
            _header("Spending Overview"),
            const SizedBox(height: 8),
            aggregatedSpending.when(
              data: (data) => _buildSpendingOverview(context, data),
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )),
              error: (_, __) => const Padding(
                padding: EdgeInsets.all(16),
                child: Text("Unable to load spending data"),
              ),
            ),

            const SizedBox(height: 20),
            _header("Weekly Spending"),
            const SizedBox(height: 8),
            aggregatedSpending.when(
              data: (data) => _buildWeeklyChart(context, data),
              loading: () => const SizedBox(height: 200),
              error: (_, __) => const SizedBox(height: 200),
            ),

            const SizedBox(height: 20),
            _header("Category Breakdown"),
            const SizedBox(height: 8),
            aggregatedSpending.when(
              data: (data) => _buildCategoryBreakdown(context, data),
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )),
              error: (_, __) => const SizedBox(),
            ),

            const SizedBox(height: 20),
            _header("Category Spend Distribution"),
            StreamBuilder<QuerySnapshot>(
              stream: categoryStream,
              builder: (context, categorySnapshot) {
                if (categorySnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (categorySnapshot.hasError) {
                  return const Center(child: Text("Error loading category data"));
                }
                if (!categorySnapshot.hasData || categorySnapshot.data!.docs.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("No analytics yet. Start shopping to see insights!"),
                  ));
                }

                final categoryDocs = categorySnapshot.data!.docs;
                final categoryStatsService = ref.read(categoryStatsServiceProvider);

                return FutureBuilder<double>(
                  future: categoryStatsService.getTotalSpendForAllCategories(uid),
                  builder: (context, totalSpendSnapshot) {
                    if (totalSpendSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (totalSpendSnapshot.hasError) {
                      return const Center(child: Text("Error loading total spend"));
                    }

                    final totalBill = totalSpendSnapshot.data ?? 0.0;
                    
                    final List<PieChartSectionData> sections = categoryDocs.map((categoryDoc) {
                      final categoryData = categoryDoc.data() as Map<String, dynamic>;
                      final totalSpendCategory = (categoryData["totalSpend"] as num?)?.toDouble() ?? 0.0;
                      final percentage = totalBill > 0 ? (totalSpendCategory / totalBill) * 100 : 0.0;
                      
                      return PieChartSectionData(
                        color: Colors.primaries[categoryDocs.indexOf(categoryDoc) % Colors.primaries.length],
                        value: percentage,
                        title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                        radius: 50,
                        titleStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList();

                    return Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: sections,
                              centerSpaceRadius: 40,
                              sectionsSpace: 2,
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...categoryDocs.map((categoryDoc) {
                          final categoryData = categoryDoc.data() as Map<String, dynamic>;
                          final categoryName = categoryData["category"] as String;
                          final totalSpendCategory = (categoryData["totalSpend"] as num?)?.toDouble() ?? 0.0;
                          final percentage = totalBill > 0 ? (totalSpendCategory / totalBill) * 100 : 0.0;
                          final color = Colors.primaries[categoryDocs.indexOf(categoryDoc) % Colors.primaries.length];
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: Row(
                              children: [
                                Container(width: 12, height: 12, color: color),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('$categoryName: ₹${totalSpendCategory.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)'),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),
            _header("Shopping Insights"),
            const SizedBox(height: 8),
            StreamBuilder<DocumentSnapshot>(
              stream: shoppingInsightsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("No shopping insights yet"),
                  ));
                }
                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                if (data.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("Start shopping to see insights"),
                  ));
                }
                return Column(
                  children: [
                    _insightCard(
                      context,
                      icon: Icons.access_time,
                      title: "Shopping Frequency",
                      value: data['shoppingFrequency'] ?? 'N/A',
                    ),
                    _insightCard(
                      context,
                      icon: Icons.savings,
                      title: "Monthly Spend",
                      value: "₹${data['monthlySpend']?.toStringAsFixed(2) ?? 'N/A'}",
                    ),
                    _insightCard(
                      context,
                      icon: Icons.local_offer,
                      title: "Best Saving Opportunity",
                      value: data['savingOpportunity'] ?? 'N/A',
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),
            _header("Pantry Consumption Forecast"),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: PantryService.pantryStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading pantry data"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("No items in pantry yet"),
                  ));
                }

                final items = snapshot.data!.docs;
                return Column(
                  children: items.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return _buildPantryForecastCard(context, d);
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartSpendSection(BuildContext context, List<SmartSpendSuggestion> suggestions) {
    if (suggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("No suggestions at the moment"),
      );
    }

    return Column(
      children: suggestions.map((suggestion) => _smartSpendCard(context, suggestion)).toList(),
    );
  }

  Widget _smartSpendCard(BuildContext context, SmartSpendSuggestion suggestion) {
    final iconData = _getIconForSuggestion(suggestion.icon);
    final color = _getColorForSuggestion(suggestion);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(iconData, color: color, size: 24),
        ),
        title: Text(
          suggestion.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            suggestion.description,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  IconData _getIconForSuggestion(String iconName) {
    switch (iconName) {
      case 'warning': return Icons.warning_amber_rounded;
      case 'trending_up': return Icons.trending_up;
      case 'savings': return Icons.savings;
      case 'pie_chart': return Icons.pie_chart;
      case 'error_outline': return Icons.error_outline;
      case 'timeline': return Icons.timeline;
      case 'inventory_2': return Icons.inventory_2;
      case 'calendar_today': return Icons.calendar_today;
      case 'thumb_up': return Icons.thumb_up;
      default: return Icons.lightbulb_outline;
    }
  }

  Color _getColorForSuggestion(SmartSpendSuggestion suggestion) {
    switch (suggestion.type) {
      case 'budget_alert':
      case 'list_budget':
        return Colors.red;
      case 'spending_trend':
        return suggestion.title.contains('Savings') ? Colors.green : Colors.orange;
      case 'category_insight':
        return Colors.blue;
      case 'projection':
        return Colors.deepOrange;
      case 'bulk_buy':
        return Colors.teal;
      case 'pattern':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  Widget _buildSpendingOverview(BuildContext context, AggregatedSpending data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _statBox(
                  context,
                  "This Week",
                  "₹${data.totalSpentThisWeek.toStringAsFixed(0)}",
                  _getChangeIndicator(data.weekOverWeekChange),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statBox(
                  context,
                  "This Month",
                  "₹${data.totalSpentThisMonth.toStringAsFixed(0)}",
                  data.totalBudgetThisMonth > 0
                      ? "${data.budgetUtilization.toStringAsFixed(0)}% of budget"
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statBox(
                  context,
                  "Daily Avg",
                  "₹${data.averageDailySpend.toStringAsFixed(0)}",
                  null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statBox(
                  context,
                  "Items Bought",
                  "${data.totalItemsPurchased}",
                  "this month",
                ),
              ),
            ],
          ),
          if (data.totalBudgetThisMonth > 0) ...[
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Budget Utilization", style: GoogleFonts.poppins(fontSize: 13)),
                    Text(
                      "₹${data.totalSpentThisMonth.toStringAsFixed(0)} / ₹${data.totalBudgetThisMonth.toStringAsFixed(0)}",
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (data.budgetUtilization / 100).clamp(0, 1),
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation(_getBudgetColor(data.budgetUtilization)),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String? _getChangeIndicator(double change) {
    if (change == 0) return null;
    final sign = change > 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(0)}% vs last week';
  }

  Color _getBudgetColor(double utilization) {
    if (utilization >= 100) return Colors.red;
    if (utilization >= 80) return Colors.orange;
    return Colors.green;
  }

  Widget _statBox(BuildContext context, String label, String value, String? subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
          ],
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context, AggregatedSpending data) {
    final maxAmount = data.weeklyBreakdown.map((d) => d.amount).fold(0.0, (a, b) => a > b ? a : b);
    final double chartMax = maxAmount > 0 ? maxAmount * 1.2 : 100.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: chartMax,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '₹${rod.toY.toStringAsFixed(0)}',
                    GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < data.weeklyBreakdown.length) {
                      return Text(
                        data.weeklyBreakdown[index].dayLabel,
                        style: GoogleFonts.poppins(fontSize: 11),
                      );
                    }
                    return const Text('');
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const Text('');
                    return Text(
                      '₹${value.toInt()}',
                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                    );
                  },
                  reservedSize: 45,
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: chartMax / 4,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              ),
            ),
            barGroups: data.weeklyBreakdown.asMap().entries.map((entry) {
              final index = entry.key;
              final spending = entry.value;
              final isToday = _isSameDay(spending.date, DateTime.now());
              
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: spending.amount,
                    color: isToday ? const Color(0xFF00B200) : Colors.blue,
                    width: 24,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context, AggregatedSpending data) {
    if (data.categorySpending.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("No category data yet"),
      );
    }

    final sortedCategories = data.categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = data.categorySpending.values.fold(0.0, (a, b) => a + b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: sortedCategories.take(5).map((entry) {
          final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
          final colorIndex = sortedCategories.indexOf(entry);
          final color = Colors.primaries[colorIndex % Colors.primaries.length];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 12, height: 12, color: color),
                        const SizedBox(width: 8),
                        Text(entry.key, style: GoogleFonts.poppins(fontSize: 14)),
                      ],
                    ),
                    Text(
                      "₹${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(0)}%)",
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _header(String t) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16),
      child: Text(
        t,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _insightCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPantryForecastCard(BuildContext context, Map<String, dynamic> data) {
    final itemName = data['item'] as String? ?? 'Unknown Item';
    final quantity = (data['quantity'] as num?)?.toInt() ?? 0;
    final consumptionRate = (data['estimatedConsumptionRateDays'] as num?)?.toDouble() ?? 0.0;
    final lowStockThreshold = (data['lowStockThreshold'] as num?)?.toInt() ?? 2;
    final expiresAtTimestamp = data['expiresAt'];
    
    DateTime? expiresAt;
    if (expiresAtTimestamp != null) {
      if (expiresAtTimestamp is Timestamp) {
        expiresAt = expiresAtTimestamp.toDate();
      } else if (expiresAtTimestamp is int) {
        expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtTimestamp);
      }
    }

    final int daysUntilEmpty = consumptionRate > 0 
        ? (quantity * consumptionRate).round() 
        : -1;

    final bool isLowStock = quantity <= lowStockThreshold;
    final bool isExpiringSoon = expiresAt != null && 
        expiresAt.difference(DateTime.now()).inDays <= 3;
    final bool isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now());

    Color statusColor = Colors.green;
    String statusText = '';
    IconData statusIcon = Icons.check_circle;

    if (isExpired) {
      statusColor = Colors.red;
      statusText = 'Expired';
      statusIcon = Icons.error;
    } else if (isExpiringSoon) {
      statusColor = Colors.orange;
      statusText = 'Expiring soon';
      statusIcon = Icons.warning;
    } else if (isLowStock) {
      statusColor = Colors.amber;
      statusText = 'Low stock';
      statusIcon = Icons.inventory_2;
    } else if (quantity > 0) {
      statusText = 'In stock';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: isLowStock || isExpiringSoon || isExpired
            ? Border.all(color: statusColor.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
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
                    Text(
                      '$quantity ${quantity == 1 ? 'unit' : 'units'} remaining',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (statusText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
            ],
          ),
          if (daysUntilEmpty > 0 || expiresAt != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                if (daysUntilEmpty > 0) ...[
                  Icon(Icons.timeline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    daysUntilEmpty == 1 
                        ? 'Runs out in ~1 day' 
                        : 'Runs out in ~$daysUntilEmpty days',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                if (daysUntilEmpty > 0 && expiresAt != null)
                  const SizedBox(width: 16),
                if (expiresAt != null) ...[
                  Icon(
                    Icons.event, 
                    size: 16, 
                    color: isExpired || isExpiringSoon ? statusColor : Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isExpired 
                        ? 'Expired ${_formatDate(expiresAt)}'
                        : 'Expires ${_formatDate(expiresAt)}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isExpired || isExpiringSoon ? statusColor : Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    
    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    if (diff == -1) return 'yesterday';
    if (diff > 0 && diff <= 7) return 'in $diff days';
    if (diff < 0 && diff >= -7) return '${-diff} days ago';
    
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
