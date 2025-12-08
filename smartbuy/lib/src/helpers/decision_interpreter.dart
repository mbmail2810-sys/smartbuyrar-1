import 'package:flutter/material.dart';

class DecisionInterpreter {
  static String getMessage(String decision) {
    switch (decision) {
      case "BUY_NOW":
        return "🔥 BUY NOW — price is at a low!";
      case "BUY_SOON":
        return "👍 Good time to buy soon.";
      case "BUY_MODERATE":
        return "🙂 Safe to buy if needed.";
      case "WAIT":
        return "⏳ WAIT — price likely to drop.";
      default:
        return "No decision.";
    }
  }

  static Color getColor(String decision) {
    switch (decision) {
      case "BUY_NOW":
        return Colors.green;
      case "BUY_SOON":
        return Colors.lightGreen;
      case "BUY_MODERATE":
        return Colors.orange;
      case "WAIT":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
