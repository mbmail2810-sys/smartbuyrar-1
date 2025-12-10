import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionPlan {
  free,
  plus,
  family,
  pro,
}

extension SubscriptionPlanExtension on SubscriptionPlan {
  String get displayName {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Free';
      case SubscriptionPlan.plus:
        return 'Plus';
      case SubscriptionPlan.family:
        return 'Family';
      case SubscriptionPlan.pro:
        return 'Pro';
    }
  }

  String get emoji {
    switch (this) {
      case SubscriptionPlan.free:
        return '🆓';
      case SubscriptionPlan.plus:
        return '⚡';
      case SubscriptionPlan.family:
        return '👨‍👩‍👧';
      case SubscriptionPlan.pro:
        return '💎';
    }
  }

  int get priceInr {
    switch (this) {
      case SubscriptionPlan.free:
        return 0;
      case SubscriptionPlan.plus:
        return 99;
      case SubscriptionPlan.family:
        return 199;
      case SubscriptionPlan.pro:
        return 299;
    }
  }

  int get maxLists {
    switch (this) {
      case SubscriptionPlan.free:
        return 1;
      case SubscriptionPlan.plus:
        return 5;
      case SubscriptionPlan.family:
        return -1; // Unlimited
      case SubscriptionPlan.pro:
        return -1; // Unlimited
    }
  }

  bool get canShare {
    switch (this) {
      case SubscriptionPlan.free:
        return false;
      case SubscriptionPlan.plus:
      case SubscriptionPlan.family:
      case SubscriptionPlan.pro:
        return true;
    }
  }

  bool get hasReminders {
    switch (this) {
      case SubscriptionPlan.free:
        return false;
      case SubscriptionPlan.plus:
      case SubscriptionPlan.family:
      case SubscriptionPlan.pro:
        return true;
    }
  }

  bool get hasCollaboration {
    switch (this) {
      case SubscriptionPlan.free:
      case SubscriptionPlan.plus:
        return false;
      case SubscriptionPlan.family:
      case SubscriptionPlan.pro:
        return true;
    }
  }

  bool get hasAiInsights {
    switch (this) {
      case SubscriptionPlan.free:
      case SubscriptionPlan.plus:
      case SubscriptionPlan.family:
        return false;
      case SubscriptionPlan.pro:
        return true;
    }
  }

  bool get hasSyncBackup {
    switch (this) {
      case SubscriptionPlan.free:
      case SubscriptionPlan.plus:
      case SubscriptionPlan.family:
        return false;
      case SubscriptionPlan.pro:
        return true;
    }
  }

  List<String> get features {
    switch (this) {
      case SubscriptionPlan.free:
        return ['1 List', 'Basic features', 'No sharing'];
      case SubscriptionPlan.plus:
        return ['5 Lists', 'Share lists', 'Reminders', 'Budget tracking'];
      case SubscriptionPlan.family:
        return ['Unlimited lists', 'Real-time collaboration', 'Family sharing', 'All Plus features'];
      case SubscriptionPlan.pro:
        return ['Everything in Family', 'AI Smart Insights', 'Cloud backup & sync', 'Priority support'];
    }
  }

  String get description {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Try SmartBuy basics';
      case SubscriptionPlan.plus:
        return 'Perfect for individuals';
      case SubscriptionPlan.family:
        return 'Shared with family';
      case SubscriptionPlan.pro:
        return 'For smart shoppers';
    }
  }
}

class UserSubscription {
  final String oderId;
  final SubscriptionPlan plan;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? razorpaySubscriptionId;
  final String? razorpayPaymentId;
  final Map<String, dynamic>? paymentDetails;

  UserSubscription({
    required this.oderId,
    required this.plan,
    required this.startDate,
    this.endDate,
    required this.isActive,
    this.razorpaySubscriptionId,
    this.razorpayPaymentId,
    this.paymentDetails,
  });

  factory UserSubscription.free() {
    return UserSubscription(
      oderId: 'free',
      plan: SubscriptionPlan.free,
      startDate: DateTime.now(),
      isActive: true,
    );
  }

  factory UserSubscription.fromMap(Map<String, dynamic> data) {
    return UserSubscription(
      oderId: data['orderId'] ?? 'free',
      plan: SubscriptionPlan.values.firstWhere(
        (p) => p.name == data['plan'],
        orElse: () => SubscriptionPlan.free,
      ),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? false,
      razorpaySubscriptionId: data['razorpaySubscriptionId'],
      razorpayPaymentId: data['razorpayPaymentId'],
      paymentDetails: data['paymentDetails'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': oderId,
      'plan': plan.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'razorpaySubscriptionId': razorpaySubscriptionId,
      'razorpayPaymentId': razorpayPaymentId,
      'paymentDetails': paymentDetails,
    };
  }

  bool get isExpired {
    if (plan == SubscriptionPlan.free) return false;
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  UserSubscription copyWith({
    String? orderId,
    SubscriptionPlan? plan,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? razorpaySubscriptionId,
    String? razorpayPaymentId,
    Map<String, dynamic>? paymentDetails,
  }) {
    return UserSubscription(
      oderId: orderId ?? this.oderId,
      plan: plan ?? this.plan,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      razorpaySubscriptionId: razorpaySubscriptionId ?? this.razorpaySubscriptionId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      paymentDetails: paymentDetails ?? this.paymentDetails,
    );
  }
}
