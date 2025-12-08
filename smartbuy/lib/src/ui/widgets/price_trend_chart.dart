import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartbuy/src/helpers/decision_interpreter.dart';
import 'package:smartbuy/src/services/decision_engine.dart';
import 'package:smartbuy/src/services/savings_service.dart';
import 'package:smartbuy/src/services/volatility_service.dart';

class PriceTrendChart extends StatelessWidget {
  final List<double> priceValues;

  const PriceTrendChart({super.key, required this.priceValues});

  @override
  Widget build(BuildContext context) {
    if (priceValues.isEmpty) {
      return const Center(child: Text("No price data available."));
    }

    final savings = SavingsService.analyzeSavings(priceValues);
    final volatility = VolatilityService.calculate(priceValues);
    final decision = DecisionEngine.decide(
      latestPrice: savings['latestPrice']!,
      avgPrice: savings['averagePrice']!,
      volatility: volatility,
      percentSaved: savings['percentSaved']!,
    );

    final spots = List.generate(priceValues.length, (index) {
      return FlSpot(index.toDouble(), priceValues[index]);
    });

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Theme.of(context).primaryColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildInfoCard(context, "Savings", "₹${savings['savings']!.toStringAsFixed(2)}"),
            _buildInfoCard(context, "Volatility", volatility.toStringAsFixed(2)),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          DecisionInterpreter.getMessage(_getDecisionString(decision)),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: DecisionInterpreter.getColor(_getDecisionString(decision)),
          ),
        ),
      ],
    );
  }

  String _getDecisionString(Decision decision) {
    switch (decision) {
      case Decision.buyNow:
        return "BUY_NOW";
      case Decision.goodDeal:
        return "BUY_SOON";
      case Decision.poorDeal:
      case Decision.wait:
        return "WAIT";
    }
  }

  Widget _buildInfoCard(BuildContext context, String title, String value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
