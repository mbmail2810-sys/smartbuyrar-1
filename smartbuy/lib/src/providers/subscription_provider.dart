import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';
import 'auth_providers.dart';

final subscriptionServiceProvider = Provider((ref) => SubscriptionService());

final userSubscriptionProvider = StreamProvider.autoDispose<UserSubscription>((ref) {
  final auth = ref.watch(authStateProvider).value;
  if (auth == null) return Stream.value(UserSubscription.free());
  
  return ref.watch(subscriptionServiceProvider).watchUserSubscription(auth.uid);
});

final currentPlanProvider = Provider.autoDispose<SubscriptionPlan>((ref) {
  final subscription = ref.watch(userSubscriptionProvider);
  return subscription.valueOrNull?.plan ?? SubscriptionPlan.free;
});

// Feature access providers
final canCreateListProvider = Provider.autoDispose.family<bool, int>((ref, currentListCount) {
  final subscription = ref.watch(userSubscriptionProvider).valueOrNull;
  if (subscription == null) return false;
  return ref.watch(subscriptionServiceProvider).canCreateList(subscription, currentListCount);
});

final canShareProvider = Provider.autoDispose<bool>((ref) {
  final subscription = ref.watch(userSubscriptionProvider).valueOrNull;
  if (subscription == null) return false;
  return ref.watch(subscriptionServiceProvider).canShareList(subscription);
});

final canUseRemindersProvider = Provider.autoDispose<bool>((ref) {
  final subscription = ref.watch(userSubscriptionProvider).valueOrNull;
  if (subscription == null) return false;
  return ref.watch(subscriptionServiceProvider).canUseReminders(subscription);
});

final canCollaborateProvider = Provider.autoDispose<bool>((ref) {
  final subscription = ref.watch(userSubscriptionProvider).valueOrNull;
  if (subscription == null) return false;
  return ref.watch(subscriptionServiceProvider).canCollaborate(subscription);
});

final canUseAiInsightsProvider = Provider.autoDispose<bool>((ref) {
  final subscription = ref.watch(userSubscriptionProvider).valueOrNull;
  if (subscription == null) return false;
  return ref.watch(subscriptionServiceProvider).canUseAiInsights(subscription);
});

final canUseSyncBackupProvider = Provider.autoDispose<bool>((ref) {
  final subscription = ref.watch(userSubscriptionProvider).valueOrNull;
  if (subscription == null) return false;
  return ref.watch(subscriptionServiceProvider).canUseSyncBackup(subscription);
});
