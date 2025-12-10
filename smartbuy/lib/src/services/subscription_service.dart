import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String razorpayKeyId = String.fromEnvironment('RAZORPAY_KEY_ID', defaultValue: '');

  Future<UserSubscription> getUserSubscription(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('current')
          .get();

      if (!doc.exists || doc.data() == null) {
        return UserSubscription.free();
      }

      final subscription = UserSubscription.fromMap(doc.data()!);
      
      // Check if subscription has expired
      if (subscription.isExpired) {
        await _downgradeToFree(userId);
        return UserSubscription.free();
      }

      return subscription;
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      return UserSubscription.free();
    }
  }

  Stream<UserSubscription> watchUserSubscription(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('subscription')
        .doc('current')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) {
        return UserSubscription.free();
      }
      final subscription = UserSubscription.fromMap(doc.data()!);
      if (subscription.isExpired) {
        return UserSubscription.free();
      }
      return subscription;
    });
  }

  Future<void> _downgradeToFree(String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('subscription')
        .doc('current')
        .set(UserSubscription.free().toMap());
  }

  Future<Map<String, dynamic>> createOrder({
    required String userId,
    required SubscriptionPlan plan,
  }) async {
    // For web, we'll create the order data that will be used by Razorpay checkout
    final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}_$userId';
    final amountInPaise = plan.priceInr * 100;

    final orderData = {
      'orderId': orderId,
      'amount': amountInPaise,
      'currency': 'INR',
      'plan': plan.name,
      'userId': userId,
      'status': 'created',
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Store the order in Firestore
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId)
        .set(orderData);

    return {
      'orderId': orderId,
      'amount': amountInPaise,
      'currency': 'INR',
      'key': razorpayKeyId,
      'name': 'SmartBuy',
      'description': '${plan.displayName} Plan - Monthly',
      'prefill': {
        'contact': '',
        'email': '',
      },
    };
  }

  Future<bool> verifyAndActivateSubscription({
    required String userId,
    required String orderId,
    required String paymentId,
    required SubscriptionPlan plan,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      // Update order status
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'paid',
        'paymentId': paymentId,
        'paidAt': FieldValue.serverTimestamp(),
      });

      // Create/Update subscription
      final subscription = UserSubscription(
        oderId: orderId,
        plan: plan,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        razorpayPaymentId: paymentId,
        paymentDetails: paymentDetails,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('current')
          .set(subscription.toMap());

      // Store subscription history
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('history')
          .collection('payments')
          .add({
        ...subscription.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error activating subscription: $e');
      return false;
    }
  }

  Future<void> cancelSubscription(String userId) async {
    try {
      await _downgradeToFree(userId);
    } catch (e) {
      debugPrint('Error canceling subscription: $e');
      rethrow;
    }
  }

  // Feature access checks
  bool canCreateList(UserSubscription subscription, int currentListCount) {
    if (subscription.plan.maxLists == -1) return true;
    return currentListCount < subscription.plan.maxLists;
  }

  bool canShareList(UserSubscription subscription) {
    return subscription.plan.canShare;
  }

  bool canUseReminders(UserSubscription subscription) {
    return subscription.plan.hasReminders;
  }

  bool canCollaborate(UserSubscription subscription) {
    return subscription.plan.hasCollaboration;
  }

  bool canUseAiInsights(UserSubscription subscription) {
    return subscription.plan.hasAiInsights;
  }

  bool canUseSyncBackup(UserSubscription subscription) {
    return subscription.plan.hasSyncBackup;
  }
}
