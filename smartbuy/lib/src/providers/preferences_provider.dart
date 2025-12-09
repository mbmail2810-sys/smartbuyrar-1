import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsNotifier, bool>((ref) {
  return NotificationsNotifier();
});

class NotificationsNotifier extends StateNotifier<bool> {
  NotificationsNotifier() : super(true) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('settings')
          .get();

      if (doc.exists) {
        state = doc.data()?['notificationsEnabled'] ?? true;
      }
    } catch (e) {
      state = true;
    }
  }

  Future<void> toggle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newValue = !state;
    state = newValue;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('settings')
          .set({'notificationsEnabled': newValue}, SetOptions(merge: true));
    } catch (e) {
      state = !newValue;
    }
  }
}
