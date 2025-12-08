import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grocery_item.dart';
import '../models/grocery_list.dart';
import '../models/reminder_model.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/offline_sync_service.dart';

class ListRepository {
  final FirestoreService _firestore;
  final OfflineSyncService _offline;
  final AnalyticsService _analytics;

  ListRepository(this._firestore, this._offline, this._analytics);

  Future<DocumentReference> safeCreateList(Map<String, dynamic> data) async {
    try {
      final docRef = await _firestore.createList(data);
      return docRef;
    } catch (_) {
      // For offline creation, we can't get a docRef from firestore.
      // The offline service will need to handle creating a temporary ID
      // and then replacing it with the real one once synced.
      // For now, let's queue and rely on UI to handle the optimistic update.
      await _offline.queueOperation(
        collectionPath: 'lists',
        operation: OperationType.add,
        data: data,
      );
      // This is tricky. When offline, we don't have a document reference.
      // The calling code needs to be able to handle this.
      // A possible solution is to generate a temporary local ID.
      // For now, this will throw an error on return if it fails.
      // A better solution would be to return a temporary object.
      // Re-throwing the exception so the UI layer knows the operation is offline.
      rethrow;
    }
  }

  Stream<List<GroceryList>> watchLists() {
    return _firestore.watchLists();
  }

  Stream<GroceryList> watchList(String listId) {
    return _firestore.watchList(listId);
  }

  Future<void> safeUpdateList(
      String listId, Map<String, dynamic> data) async {
    try {
      await _firestore.updateList(listId, data);
    } catch (_) {
      await _offline.queueOperation(
        collectionPath: 'lists',
        docId: listId,
        operation: OperationType.update,
        data: data,
      );
    }
  }

  Future<void> safeAddItem(String listId, GroceryItem item) async {
    // Add current price to priceHistory if price is available
    List<Map<String, dynamic>> updatedPriceHistory = List.from(item.priceHistory ?? []);
    if (item.price != null && item.price! > 0) {
      updatedPriceHistory.add({
        'date': DateTime.now(),
        'price': item.price,
      });
    }

    final itemWithHistory = item.copyWith(
      priceHistory: updatedPriceHistory,
    );

    try {
      await _firestore.addItem(listId, itemWithHistory.toMap());
    } catch (_) {
      await _offline.queueOperation(
        collectionPath: 'lists/$listId/items',
        operation: OperationType.add,
        data: itemWithHistory.toMap(),
      );
    }
  }

  Stream<List<GroceryItem>> watchItems(String listId) {
    return _firestore.watchItems(listId);
  }

  Future<void> safeUpdateItem(
      String listId, String itemId, Map<String, dynamic> data) async {
    final itemRef = _firestore.listsRef.doc(listId).collection('items').doc(itemId);

    // Fetch existing item to check current price history
    final existingItemDoc = await itemRef.get();
    final existingItem = GroceryItem.fromDoc(existingItemDoc);

    // Get new price from data (if available)
    final newPrice = (data['price'] as num?)?.toDouble();

    // Update price history if price has changed
    List<Map<String, dynamic>> updatedPriceHistory = List.from(existingItem.priceHistory ?? []);
    if (newPrice != null && newPrice != existingItem.price) {
      updatedPriceHistory.add({
        'date': DateTime.now(),
        'price': newPrice,
      });
      data['priceHistory'] = updatedPriceHistory.map((e) => {
        'date': Timestamp.fromDate(e['date']),
        'price': e['price'],
      }).toList();
    }

    try {
      await _firestore.updateItem(listId, itemId, data);
      await _recalculateSpent(listId);
    } catch (_) {
      await _offline.queueOperation(
        collectionPath: 'lists/$listId/items',
        docId: itemId,
        operation: OperationType.update,
        data: data,
      );
    }
  }

  Future<void> safeDeleteItem(String listId, String itemId) async {
    try {
      final listRef = _firestore.listsRef.doc(listId);
      final itemRef = listRef.collection('items').doc(itemId);

      await _firestore.db.runTransaction((transaction) async {
        final itemDoc = await transaction.get(itemRef);
        final listDoc = await transaction.get(listRef);

        if (!itemDoc.exists || !listDoc.exists) {
          throw Exception("Document not found!");
        }

        transaction.delete(itemRef);
      });

      await _recalculateSpent(listId);
    } catch (_) {
      await _offline.queueOperation(
        collectionPath: 'lists/$listId/items',
        docId: itemId,
        operation: OperationType.delete,
      );
    }
  }

  Future<String> createInvite({
    required String listId,
    required String listTitle,
    required String createdBy,
    String role = 'editor',
  }) async {
    final validRole = _validateRole(role);
    try {
      final ref = await _firestore.createInvite({
        'listId': listId,
        'listTitle': listTitle,
        'role': validRole,
        'createdBy': createdBy,
      });
      return ref.id;
    } catch (_) {
      await _offline.queueOperation(
        collectionPath: 'invites',
        operation: OperationType.add,
        data: {
          'listId': listId,
          'listTitle': listTitle,
          'role': validRole,
          'createdBy': createdBy,
        },
      );
      rethrow;
    }
  }

  Future<void> acceptInvite(String inviteId, String userId) async {
    // This action should probably only happen online.
    await _firestore.acceptInvite(inviteId, userId);
  }

  Future<void> addReminder({
    required String listId,
    required String title,
    required DateTime datetime,
    required String createdBy,
  }) async {
    // Scheduling local notifications should work offline.
    // The database part can be queued.
    try {
      await _firestore.addReminder(listId, {
        'title': title,
        'datetime': datetime.millisecondsSinceEpoch,
        'active': true,
        'createdBy': createdBy,
        'listId': listId,
      });
    } catch (_) {
      await _offline.queueOperation(
        collectionPath: 'lists/$listId/reminders',
        operation: OperationType.add,
        data: {
          'title': title,
          'datetime': datetime.millisecondsSinceEpoch,
          'active': true,
          'createdBy': createdBy,
          'listId': listId,
        },
      );
    }

    final id = datetime.millisecondsSinceEpoch;

    await NotificationService().scheduleNotification(
      id: id,
      title: 'SmartBuy Reminder',
      body: title,
      scheduledTime: datetime,
    );
  }

  Future<void> updateReminder({
    required String listId,
    required String reminderId,
    required String title,
    required DateTime datetime,
    required bool active,
  }) async {
    try {
      await _firestore.updateReminder(listId, reminderId, {
        'title': title,
        'datetime': datetime.millisecondsSinceEpoch,
        'active': true,
      });
    } catch (_) {
      await _offline.queueOperation(
        collectionPath: 'lists/$listId/reminders',
        docId: reminderId,
        operation: OperationType.update,
        data: {
          'title': title,
          'datetime': datetime.millisecondsSinceEpoch,
          'active': true,
        },
      );
    }

    final id = datetime.millisecondsSinceEpoch;

    if (active) {
      await NotificationService().scheduleNotification(
        id: id,
        title: 'SmartBuy Reminder',
        body: title,
        scheduledTime: datetime,
      );
    } else {
      await NotificationService().cancelNotification(id);
    }
  }

  Stream<List<Reminder>> watchReminders(String listId) {
    return _firestore.watchReminders(listId);
  }

  Future<void> safeDeleteReminder(String listId, String reminderId) async {
    try {
      final reminderDoc = await _firestore.db
          .collection('lists')
          .doc(listId)
          .collection('reminders')
          .doc(reminderId)
          .get();

      if (reminderDoc.exists) {
        final reminder =
            Reminder.fromFirestore(reminderDoc.data()!, reminderDoc.id);
        final id = reminder.datetime;
        await NotificationService().cancelNotification(id);
      }

      await _firestore.deleteReminder(listId, reminderId);
    } catch (_) {
      await _offline.queueOperation(
        collectionPath: 'lists/$listId/reminders',
        docId: reminderId,
        operation: OperationType.delete,
      );
    }
  }

  Future<void> safeDeleteList(String listId) async {
    try {
      await _firestore.deleteList(listId);
    } catch (_) {
      await _offline.queueOperation(
        collectionPath: 'lists',
        docId: listId,
        operation: OperationType.delete,
      );
    }
  }

  Future<void> updateItemChecked(
      String listId, String itemId, bool checked) async {
    final itemRef =
        _firestore.listsRef.doc(listId).collection('items').doc(itemId);

    final Map<String, dynamic> data = {
      'checked': checked,
    };

    if (checked) {
      final snapshot = await itemRef.get();
      final docData = snapshot.data();

      if (docData != null) {
        final item = GroceryItem.fromDoc(snapshot);
        await _analytics.logPurchase(item);
        
        await _logPurchaseToList(listId, item);
      }

      final usageLog = (docData?['usageLog'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [];

      usageLog.add({
        'date': DateTime.now().millisecondsSinceEpoch,
      });
      data['usageLog'] = usageLog;
    }
    await itemRef.update(data);
    await _recalculateSpent(listId);
  }

  Future<void> _logPurchaseToList(String listId, GroceryItem item) async {
    final listRef = _firestore.listsRef.doc(listId);
    
    final purchaseEntry = {
      'itemId': item.id,
      'itemName': item.name,
      'price': item.price ?? 0.0,
      'quantity': item.quantity,
      'total': (item.price ?? 0.0) * item.quantity,
      'date': DateTime.now().millisecondsSinceEpoch,
    };
    
    await listRef.update({
      'purchaseLog': FieldValue.arrayUnion([purchaseEntry])
    });
  }

  Future<void> updateBudget(String listId, double newBudget) async {
    await _firestore.listsRef.doc(listId).update({'budget': newBudget});
  }

  Future<void> updateSpent(String listId, double spent) async {
    await _firestore.listsRef.doc(listId).update({'spent': spent});
  }

  Future<void> addPriceToHistory(
      String listId, String itemId, double price) async {
    final itemRef =
        _firestore.listsRef.doc(listId).collection('items').doc(itemId);

    final snapshot = await itemRef.get();
    final data = snapshot.data();

    final history = (data?['priceHistory'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    history.add({
      'price': price,
      'date': DateTime.now().millisecondsSinceEpoch,
    });

    await itemRef.update({
      'price': price,
      'priceHistory': history,
    });
  }

  Future<void> _recalculateSpent(String listId) async {
    final listRef = _firestore.listsRef.doc(listId);
    final itemsSnapshot = await listRef.collection('items').get();

    double totalSpent = 0;
    for (final doc in itemsSnapshot.docs) {
      final itemData = doc.data();
      final isChecked = itemData['checked'] ?? false;
      if (isChecked) {
        final price = (itemData['price'] as num?)?.toDouble() ?? 0.0;
        final quantity = (itemData['quantity'] as num?)?.toInt() ?? 1;
        totalSpent += price * quantity;
      }
    }

    await listRef.update({'spent': totalSpent});
  }

  String _validateRole(String role) {
    const validRoles = ['owner', 'editor', 'viewer'];
    if (validRoles.contains(role)) return role;
    if (role == 'member') return 'editor';
    return 'viewer';
  }

  Future<String> createInviteWithEmail({
    required String listId,
    required String listTitle,
    required String createdBy,
    required String invitedUserEmail,
    String role = 'editor',
  }) async {
    final validRole = _validateRole(role);
    try {
      final ref = await _firestore.createInvite({
        'listId': listId,
        'listTitle': listTitle,
        'role': validRole,
        'createdBy': createdBy,
        'invitedUserEmail': invitedUserEmail,
      });
      return ref.id;
    } catch (_) {
      await _offline.queueOperation(
        collectionPath: 'invites',
        operation: OperationType.add,
        data: {
          'listId': listId,
          'listTitle': listTitle,
          'role': validRole,
          'createdBy': createdBy,
          'invitedUserEmail': invitedUserEmail,
        },
      );
      rethrow;
    }
  }

  Future<void> addMember(String listId, String userId, MemberRole role) async {
    await _firestore.addMemberToList(listId, userId, role);
  }

  Future<void> removeMember(String listId, String userId) async {
    await _firestore.removeMemberFromList(listId, userId);
  }

  Future<void> updateMemberRole(String listId, String userId, MemberRole role) async {
    await _firestore.updateMemberRole(listId, userId, role);
  }
}
