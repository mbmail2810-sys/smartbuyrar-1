import 'package:cloud_firestore/cloud_firestore.dart';

class Invite {
  final String id;
  final String listId;
  final String listTitle;
  final String role;
  final String createdBy;
  final int createdAt; // Stored as millisecondsSinceEpoch
  final String invitedUserEmail;

  Invite({
    required this.id,
    required this.listId,
    required this.listTitle,
    required this.role,
    required this.createdBy,
    required this.createdAt,
    required this.invitedUserEmail,
  });

  Map<String, dynamic> toMap() => {
        'listId': listId,
        'listTitle': listTitle,
        'role': role,
        'createdBy': createdBy,
        'createdAt': createdAt,
        'invitedUserEmail': invitedUserEmail,
      };

  factory Invite.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Invite(
      id: doc.id,
      listId: d['listId'],
      listTitle: d['listTitle'],
      role: d['role'],
      createdBy: d['createdBy'],
      createdAt: _parseTimestamp(d['createdAt']),
      invitedUserEmail: d['invitedUserEmail'] ?? '',
    );
  }
}

int _parseTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.millisecondsSinceEpoch;
  } else if (timestamp is int) {
    return timestamp;
  } else {
    return DateTime.now().millisecondsSinceEpoch;
  }
}
