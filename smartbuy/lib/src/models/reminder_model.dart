import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  final String? id;
  final String title;
  final int datetime; // Stored as millisecondsSinceEpoch
  final bool active;
  final String createdBy;
  final String listId;

  Reminder({
    this.id,
    required this.title,
    required this.datetime,
    required this.active,
    required this.createdBy,
    required this.listId,
  });

  Reminder copyWith({
    String? id,
    String? title,
    int? datetime,
    bool? active,
    String? createdBy,
    String? listId,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      datetime: datetime ?? this.datetime,
      active: active ?? this.active,
      createdBy: createdBy ?? this.createdBy,
      listId: listId ?? this.listId,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'datetime': datetime,
        'active': active,
        'createdBy': createdBy,
        'listId': listId,
      };

  factory Reminder.fromFirestore(Map<String, dynamic> data, String documentId) {
    // Perform a robust check for Timestamp and convert, otherwise handle int
    final datetime = data['datetime'];
    final int msSinceEpoch;
    if (datetime is Timestamp) {
      msSinceEpoch = datetime.millisecondsSinceEpoch;
    } else if (datetime is int) {
      msSinceEpoch = datetime;
    } else {
      // Fallback for safety, though data should be consistent
      msSinceEpoch = DateTime.now().millisecondsSinceEpoch;
    }

    return Reminder(
      id: documentId,
      title: data['title'] ?? '',
      datetime: msSinceEpoch,
      active: data['active'] ?? true,
      createdBy: data['createdBy'] ?? '',
      listId: data['listId'] ?? '',
    );
  }
}
