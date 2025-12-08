import 'dart:math';

class VolatilityService {
  static double calculate(List<double> prices) {
    if (prices.length < 2) {
      return 0.0;
    }

    double mean = prices.reduce((a, b) => a + b) / prices.length;
    double variance =
        prices.map((p) => pow(p - mean, 2)).reduce((a, b) => a + b) /
            prices.length;
    double stdDev = sqrt(variance);

    return stdDev;
  }
}
