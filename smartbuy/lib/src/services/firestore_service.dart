// This is the firestore_service.dart file.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/grocery_list.dart';
import '../models/grocery_item.dart';
import '../models/reminder_model.dart';
import '../models/invite_model.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

class FirestoreService {
  static FirebaseFirestore? _instance;
  FirebaseFirestore get db => _instance ??= FirebaseFirestore.instance;

  CollectionReference get listsRef => db.collection('lists');

  // Create new list
  Future<DocumentReference> createList(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    data['createdAt'] = DateTime.now().millisecondsSinceEpoch;
    // Ensure the owner is also a member
    if (data.containsKey('ownerId')) {
      final members = List<String>.from(data['members'] ?? []);
      final ownerId = data['ownerId'];
      if (!members.contains(ownerId)) {
        members.add(ownerId);
      }
      data['members'] = members;
    }
    return await listsRef.add(data);
  }

  // Watch all lists of a user
  Stream<List<GroceryList>> watchLists() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return listsRef.where('members', arrayContains: uid).snapshots().map(
        (snapshot) =>
            snapshot.docs.map((d) => GroceryList.fromDoc(d)).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  // Watch a single list
  Stream<GroceryList> watchList(String listId) {
    return listsRef
        .doc(listId)
        .snapshots()
        .map((snap) => GroceryList.fromDoc(snap));
  }

  // Update a list
  Future<void> updateList(String listId, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    await listsRef.doc(listId).update(data);
  }

  // Add item to a list
  Future<DocumentReference> addItem(
      String listId, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final itemsRef = listsRef.doc(listId).collection('items');
    // Use Timestamp.now() for createdAt
    data['createdAt'] = Timestamp.now();
    // createdBy is already expected to be in the 'data' map from item.toMap()
    return await itemsRef.add(data);
  }

  // Watch items in list
  Stream<List<GroceryItem>> watchItems(String listId) {
    final itemsRef = listsRef.doc(listId).collection('items');
    return itemsRef.orderBy('createdAt').snapshots().map(
        (snap) => snap.docs.map((d) => GroceryItem.fromDoc(d)).toList());
  }

  // Update an item in a list
  Future<void> updateItem(
      String listId, String itemId, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final itemRef = listsRef.doc(listId).collection('items').doc(itemId);

    final snapshot = await itemRef.get();
    final docData = snapshot.data();

    final usageLog = (docData?['usageLog'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    final ts = DateTime.now().millisecondsSinceEpoch;
    usageLog.add({
      'date': ts,
    });
    data['usageLog'] = usageLog;

    data['updatedAt'] = ts;
    await itemRef.update(data);
  }

  Future<void> deleteItem(String listId, String itemId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    await listsRef.doc(listId).collection('items').doc(itemId).delete();
  }

  // Invites
  Future<DocumentReference> createInvite(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final invites = db.collection('invites');
    data['createdAt'] = DateTime.now().millisecondsSinceEpoch;
    return await invites.add(data);
  }

  Future<Invite?> getInviteById(String inviteId) async {
    final doc = await db.collection('invites').doc(inviteId).get();
    if (!doc.exists) return null;
    return Invite.fromDoc(doc);
  }

  Future<void> acceptInvite(String inviteId, String userId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final invite = await getInviteById(inviteId);
    if (invite == null) return;

    final listRef = db.collection('lists').doc(invite.listId);
    final inviteRef = db.collection('invites').doc(inviteId);

    await db.runTransaction((txn) async {
      final listDoc = await txn.get(listRef);
      if (!listDoc.exists) return;

      txn.update(listRef, {
        'members': FieldValue.arrayUnion([userId]),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      txn.delete(inviteRef);
    });
  }

  Future<void> declineInvite(String inviteId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    await db.collection('invites').doc(inviteId).delete();
  }

  Stream<List<Invite>> getInvitesForUser(String email) {
    return db
        .collection('invites')
        .where('invitedUserEmail', isEqualTo: email)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Invite.fromDoc(doc)).toList());
  }

  Future<void> addReminder(String listId, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final ref = listsRef.doc(listId).collection('reminders');
    data['createdAt'] = DateTime.now().millisecondsSinceEpoch;
    await ref.add(data);
  }

  Stream<List<Reminder>> watchReminders(String listId) {
    return listsRef
        .doc(listId)
        .collection('reminders')
        .orderBy('datetime')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Reminder.fromFirestore(d.data(), d.id))
            .toList());
  }

  Future<void> deleteReminder(String listId, String reminderId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    await listsRef
        .doc(listId)
        .collection('reminders')
        .doc(reminderId)
        .delete();
  }

  Future<void> updateReminder(
      String listId, String reminderId, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    await listsRef
        .doc(listId)
        .collection('reminders')
        .doc(reminderId)
        .update(data);
  }

  Future<void> deleteList(String listId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    await listsRef.doc(listId).delete();
  }

  // Generic methods
  Future<List<T>> getCollection<T>(String path,
      T Function(Map<String, dynamic>, String) fromFirestore) async {
    final snapshot = await db.collection(path).get();
    return snapshot.docs
        .map((doc) => fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> addDocument(String path, Map<String, dynamic> data) {
    return db.collection(path).add(data);
  }

  Future<void> setDocument(
    String path,
    String docId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) {
    return db.collection(path).doc(docId).set(data, SetOptions(merge: merge));
  }

  Future<void> updateDocument(
      String path, String docId, Map<String, dynamic> data) {
    return db.collection(path).doc(docId).update(data);
  }

  Future<void> deleteDocument(String path, String docId) {
    return db.collection(path).doc(docId).delete();
  }
}
