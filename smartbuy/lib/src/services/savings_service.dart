class SavingsService {
  static Map<String, double> analyzeSavings(List<double> prices) {
    if (prices.length < 2) {
      return {
        'latestPrice': 0,
        'averagePrice': 0,
        'savings': 0,
        'percentSaved': 0,
      };
    }
    final latestPrice = prices.last;
    final averagePrice = prices.reduce((a, b) => a + b) / prices.length;
    final savings = averagePrice - latestPrice;
    final percentSaved = (savings / averagePrice) * 100;

    return {
      'latestPrice': latestPrice,
      'averagePrice': averagePrice,
      'savings': savings,
      'percentSaved': percentSaved,
    };
  }
}
