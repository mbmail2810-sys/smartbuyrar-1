import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartbuy/src/services/analytics_service.dart';
import 'package:smartbuy/src/services/pantry_service.dart';
import 'package:smartbuy/src/services/category_stats_service.dart'; // Import CategoryStatsService
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart

final categoryStatsServiceProvider = Provider((ref) => CategoryStatsService()); // Define provider

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text("Not logged in"));
    }

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
      appBar: AppBar(
        title: const Text("Insights"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(analyticsServiceProvider).resetAnalytics(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            _header(" Category Spend Distribution"),
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
                  return const Center(child: Text("No Analytics yet"));
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
                        title: '${percentage.toStringAsFixed(1)}%',
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
                        Column(
                          children: categoryDocs.map((categoryDoc) {
                            final categoryData = categoryDoc.data() as Map<String, dynamic>;
                            final categoryName = categoryData["category"] as String;
                            final totalSpendCategory = (categoryData["totalSpend"] as num?)?.toDouble() ?? 0.0;
                            final percentage = totalBill > 0 ? (totalSpendCategory / totalBill) * 100 : 0.0;
                            final color = Colors.primaries[categoryDocs.indexOf(categoryDoc) % Colors.primaries.length];
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    color: color,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('$categoryName: ₹${totalSpendCategory.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)'),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('analytics')
                              .doc(uid)
                              .collection('itemStats')
                              .snapshots(), // Fetch all item stats for client-side filtering
                          builder: (context, itemStatsSnapshotInner) {
                            if (itemStatsSnapshotInner.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (itemStatsSnapshotInner.hasError) {
                              return const Center(child: Text("Error loading item stats"));
                            }

                            final allItemStats = itemStatsSnapshotInner.hasData
                                ? itemStatsSnapshotInner.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList()
                                : <Map<String, dynamic>>[];

                            return Column(
                              children: categoryDocs.map((categoryDoc) {
                                final categoryData = categoryDoc.data() as Map<String, dynamic>;
                                final categoryName = categoryData["category"] as String;
                                final itemsPurchased = categoryData["itemsPurchased"] ?? 0;
                                final avgSpend = categoryData["avgSpend"] ?? 0.0;
                                final totalSpendCategory = (categoryData["totalSpend"] as num?)?.toDouble() ?? 0.0;
                                final frequencyPerMonth = categoryData["frequencyPerMonth"] ?? 0;
                                final purchaseHistory = categoryData["purchaseHistory"] as List<dynamic>? ?? [];

                                // Calculate percentage of total bill
                                final percentageOfTotalBill = totalBill > 0 ? (totalSpendCategory / totalBill) * 100 : 0.0;

                                // Determine most frequent purchase day
                                final mostFrequentDay = categoryStatsService.getMostFrequentPurchaseDay(purchaseHistory);

                                // Find most frequently purchased item for this category
                                final categoryItems = allItemStats
                                    .where((item) => item["category"] == categoryName)
                                    .toList();

                                categoryItems.sort((a, b) => (b["timesPurchased"] ?? 0).compareTo(a["timesPurchased"] ?? 0));
                                final mostBoughtItem = categoryItems.isNotEmpty ? categoryItems.first["item"] : 'N/A';

                                return _categoryInsightCard(
                                  context,
                                  category: categoryName,
                                  itemsPurchased: itemsPurchased,
                                  avgSpend: avgSpend,
                                  frequencyPerMonth: frequencyPerMonth,
                                  mostBoughtItem: mostBoughtItem,
                                  percentageOfTotalBill: percentageOfTotalBill,
                                  mostFrequentPurchaseDay: mostFrequentDay,
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            _header("🧾 Frequent Purchase Summary"),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: categoryStream, // Use the existing categoryStream
              builder: (context, categorySnapshot) {
                if (categorySnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (categorySnapshot.hasError) {
                  return const Center(child: Text("Error loading category data"));
                }
                if (!categorySnapshot.hasData || categorySnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No Analytics yet"));
                }

                final categoryDocs = categorySnapshot.data!.docs;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('analytics')
                      .doc(uid)
                      .collection('itemStats')
                      .snapshots(), // Fetch all item stats for client-side filtering
                  builder: (context, itemStatsSnapshotInner) {
                    if (itemStatsSnapshotInner.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (itemStatsSnapshotInner.hasError) {
                      return const Center(child: Text("Error loading item stats"));
                    }

                    final allItemStats = itemStatsSnapshotInner.hasData
                        ? itemStatsSnapshotInner.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList()
                        : <Map<String, dynamic>>[];

                    // Calculate overall most frequent category
                    String mostFrequentCategory = 'N/A';
                    double mostFrequentCategoryAvgSpend = 0.0;
                    int maxFrequency = 0;

                    for (var doc in categoryDocs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final currentCategory = data["category"] as String;
                      final currentFrequency = data["frequencyPerMonth"] ?? 0;
                      if (currentFrequency > maxFrequency) {
                        maxFrequency = currentFrequency;
                        mostFrequentCategory = currentCategory;
                        mostFrequentCategoryAvgSpend = data["avgSpend"] ?? 0.0;
                      }
                    }

                    // Calculate overall most frequently purchased item
                    String overallMostBoughtItem = 'N/A';
                    int maxTimesPurchased = 0;

                    for (var itemData in allItemStats) {
                      final currentItem = itemData["item"] as String;
                      final currentTimesPurchased = itemData["timesPurchased"] ?? 0;
                      if (currentTimesPurchased > maxTimesPurchased) {
                        maxTimesPurchased = currentTimesPurchased;
                        overallMostBoughtItem = currentItem;
                      }
                    }

                    // Hardcoded suggestions for the most frequent category (Fruits)
                    List<String> suggestions = [];
                    if (mostFrequentCategory.toLowerCase() == 'fruits') {
                      suggestions = ['Apple', 'Orange', 'Grapes'];
                    } else if (mostFrequentCategory.toLowerCase() == 'vegetables') {
                      suggestions = ['Potato', 'Onion', 'Tomato'];
                    } else {
                      suggestions = ['No specific suggestions'];
                    }


                    return _frequentPurchaseSummaryCard(
                      context,
                      category: mostFrequentCategory,
                      avgSpend: mostFrequentCategoryAvgSpend,
                      mostBoughtItem: overallMostBoughtItem,
                      suggestions: suggestions,
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),
            _header("📍 Shopping Insights"),
            const SizedBox(height: 8),

            StreamBuilder<DocumentSnapshot>(
              stream: shoppingInsightsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
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
            _header("🔥 Pantry Consumption Forecast"),
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
                  return const Center(child: Text("No items in pantry yet"));
                }

                final items = snapshot.data!.docs;

                return Column(
                  children: items.map((doc) {
                    final d = doc.data() as Map;
                    final rate = d["estimatedConsumptionRateDays"] ?? 0;
                    return _insightCard(
                      context,
                      icon: Icons.label_important_outline_rounded,
                      title: d["item"],
                      value:
                          "Est. Consumption: ${rate.toStringAsFixed(2)} days/unit",
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 40)
          ],
        ),
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

  Widget _frequentPurchaseSummaryCard(
    BuildContext context, {
    required String category,
    required double avgSpend,
    required String mostBoughtItem,
    required List<String> suggestions,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🧾 You frequently buy $category — Avg ₹${avgSpend.toStringAsFixed(2)}/month",
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            "🍌 Most frequently purchased: $mostBoughtItem",
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          Text(
            "🍎 Suggestions: ${suggestions.join(', ')}",
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ],
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

  Widget _categoryInsightCard(
    BuildContext context, {
    required String category,
    required int itemsPurchased,
    required double avgSpend,
    required int frequencyPerMonth,
    required String mostBoughtItem,
    required double percentageOfTotalBill,
    required String mostFrequentPurchaseDay,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$category ($itemsPurchased purchases)",
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "Spend avg: ₹${avgSpend.toStringAsFixed(2)}/month",
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          Text(
            "Frequency: $frequencyPerMonth times/month",
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          Text(
            "You often buy: $mostBoughtItem",
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "You spend ${percentageOfTotalBill.toStringAsFixed(1)}% of your bill on ${category.toLowerCase()}",
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "You usually buy ${category.toLowerCase()} items on $mostFrequentPurchaseDay",
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
