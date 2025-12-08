import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

import 'firestore_service.dart';

enum OperationType { add, update, delete }
enum SyncStatus { synced, pending, syncing }

class OfflineSyncService {
  static const _boxName = 'offline_queue';

  final Logger _logger = Logger();
  final FirestoreService _firestoreService;

  /// Underlying Hive box. Nullable until initialized.
  Box<dynamic>? _queueBox;

  /// Public sync status notifier for UI badges / indicators.
  final ValueNotifier<SyncStatus> syncStatus =
      ValueNotifier<SyncStatus>(SyncStatus.synced);

  OfflineSyncService(this._firestoreService);

  /// Whether the Hive box has been opened and is usable.
  bool get _isInitialized => _queueBox != null && _queueBox!.isOpen;

  /// Initialize the offline queue box.
  ///
  /// Safe to call multiple times; subsequent calls will be no-ops.
  Future<void> init() async {
    if (_isInitialized) return;

    _queueBox = await Hive.openBox<dynamic>(_boxName);

    // Initial status computation
    _updateSyncStatus();

    // React to changes in the box to keep status in sync
    _queueBox!.watch().listen((_) => _updateSyncStatus());
  }

  /// Ensure the box is ready before use.
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    _logger.w(
      'OfflineSyncService used before initialization. '
      'Calling init() automatically.',
    );

    await init();
  }

  void _updateSyncStatus() {
    // If not ready, treat as "synced" (no pending queue known yet)
    if (!_isInitialized) {
      if (syncStatus.value != SyncStatus.synced) {
        syncStatus.value = SyncStatus.synced;
      }
      return;
    }

    if (syncStatus.value == SyncStatus.syncing) {
      // Don't override while active sync is running.
      return;
    }

    final hasItems = _queueBox!.isNotEmpty;
    syncStatus.value = hasItems ? SyncStatus.pending : SyncStatus.synced;
  }

  /// Store unsynced operations (add/update/delete) in local queue.
  Future<void> queueOperation({
    required String collectionPath,
    required OperationType operation,
    String? docId,
    Map<String, dynamic>? data,
  }) async {
    await _ensureInitialized();

    // Argument validation
    if ((operation == OperationType.update || operation == OperationType.delete) &&
        docId == null) {
      throw ArgumentError(
        'Document ID must be provided for update/delete operations.',
      );
    }

    if ((operation == OperationType.add || operation == OperationType.update) &&
        data == null) {
      throw ArgumentError(
        'Data must be provided for add/update operations.',
      );
    }

    // Store operation type as index (int) for compactness.
    await _queueBox!.add({
      'collectionPath': collectionPath,
      'operation': operation.index, // int
      'docId': docId,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _updateSyncStatus();
  }

  /// Try syncing all queued writes when online.
  Future<void> syncQueuedData() async {
    await _ensureInitialized();

    final queue = _queueBox;
    if (queue == null) {
      _logger.w('syncQueuedData called, but queue box is null.');
      syncStatus.value = SyncStatus.synced;
      return;
    }

    if (queue.isEmpty) {
      _updateSyncStatus();
      return;
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _logger.i('No connectivity, skipping sync.');
      return;
    }

    syncStatus.value = SyncStatus.syncing;

    // Use a copy of the keys to avoid concurrent modification issues.
    final keys = queue.keys.toList();

    for (final key in keys) {
      final op = queue.get(key);
      if (op == null || op is! Map) {
        _logger.w('Invalid operation entry at key $key, deleting.');
        await queue.delete(key);
        continue;
      }

      try {
        await _handleOperation(Map<dynamic, dynamic>.from(op));
        await queue.delete(key);
      } catch (e, s) {
        final collectionPath = op['collectionPath'];
        final docId = op['docId'];
        _logger.e(
          'Sync failed for operation with key $key '
          '(collection: $collectionPath, doc: $docId)',
          error: e,
          stackTrace: s,
        );
        // Do NOT delete on failure; keep it in queue to retry later.
      }
    }

    _updateSyncStatus();
  }

  /// Handles a single queued operation.
  Future<void> _handleOperation(Map<dynamic, dynamic> op) async {
    final collectionPath = op['collectionPath']?.toString();
    if (collectionPath == null || collectionPath.isEmpty) {
      throw ArgumentError('Missing collectionPath in offline operation.');
    }

    final operation = _parseOperation(op['operation']);
    final docId = op['docId']?.toString();

    final rawData = op['data'];
    final data = rawData == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(rawData as Map);

    switch (operation) {
      case OperationType.add:
        await _firestoreService.addDocument(collectionPath, data);
        break;

      case OperationType.update:
        if (docId == null) {
          throw ArgumentError('Missing docId for update operation.');
        }
        await _handleUpdate(collectionPath, docId, data);
        break;

      case OperationType.delete:
        if (docId == null) {
          throw ArgumentError('Missing docId for delete operation.');
        }
        await _firestoreService.deleteDocument(collectionPath, docId);
        break;
    }
  }

  /// Update logic with simple last-write-wins conflict resolution.
  ///
  /// Expects both local and server docs to have an `updatedAt` field
  /// comparable as Timestamp or int (millisecondsSinceEpoch).
  Future<void> _handleUpdate(
    String collectionPath,
    String docId,
    Map<String, dynamic> localData,
  ) async {
    final docRef = FirebaseFirestore.instance.collection(collectionPath).doc(docId);
    final serverDoc = await docRef.get();

    if (!serverDoc.exists) {
      // If the document doesn't exist on the server, treat it as a set.
      await _firestoreService.setDocument(
        collectionPath,
        docId,
        localData,
        merge: true,
      );
      _logger.i('Document $docId did not exist remotely. Created via set().');
      return;
    }

    final serverData = serverDoc.data() ?? <String, dynamic>{};

    final serverTimestamp = _parseTimestamp(serverData['updatedAt']);
    final localTimestamp = _parseTimestamp(localData['updatedAt']);

    // Conflict resolution: Last-write-wins (client-side timestamp takes precedence if newer)
    // If local data is newer than server data, or server data has no timestamp,
    // then apply the local update to the server.
    if (localTimestamp != null &&
        (serverTimestamp == null || localTimestamp > serverTimestamp)) {
      await _firestoreService.updateDocument(collectionPath, docId, localData);
      _logger.i('Local update applied to $docId as it was newer.');
    } else {
      // If server data is newer or equally new, discard local update and log.
      _logger.w(
        'Stale local data for document $docId detected (local: $localTimestamp, server: $serverTimestamp). '
        'Discarding local update in favor of server version.',
      );
    }
  }

  /// Parse operation value stored in the box.
  ///
  /// Supports both:
  /// - int index (current format)
  /// - string enum name (legacy format, e.g. "OperationType.add")
  OperationType _parseOperation(dynamic raw) {
    if (raw is int) {
      if (raw >= 0 && raw < OperationType.values.length) {
        return OperationType.values[raw];
      }
      throw ArgumentError('Invalid operation index: $raw');
    }

    if (raw is String) {
      if (raw == OperationType.add.toString()) return OperationType.add;
      if (raw == OperationType.update.toString()) return OperationType.update;
      if (raw == OperationType.delete.toString()) return OperationType.delete;
      throw ArgumentError('Unknown operation string: $raw');
    }

    throw ArgumentError('Unknown operation type: $raw (${raw.runtimeType})');
  }
}

/// Safely parse different timestamp types into millisecondsSinceEpoch.
int? _parseTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.millisecondsSinceEpoch;
  } else if (timestamp is int) {
    return timestamp;
  } else if (timestamp is String) {
    // Optional: parse string timestamps if you ever store them as ISO strings.
    final parsed = DateTime.tryParse(timestamp);
    return parsed?.millisecondsSinceEpoch;
  }
  return null;
}
