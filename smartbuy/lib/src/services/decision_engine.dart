enum Decision {
  buyNow,
  wait,
  goodDeal,
  poorDeal,
}

class DecisionEngine {
  static Decision decide({
    required double latestPrice,
    required double avgPrice,
    required double volatility,
    required double percentSaved,
  }) {
    if (percentSaved > 15) {
      return Decision.goodDeal;
    }
    if (percentSaved < -15) {
      return Decision.poorDeal;
    }
    if (latestPrice < avgPrice && volatility < 5) {
      return Decision.buyNow;
    }
    return Decision.wait;
  }
}
