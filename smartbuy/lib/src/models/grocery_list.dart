import 'package:cloud_firestore/cloud_firestore.dart';

class GroceryList {
  final String id;
  final String title;
  final String ownerId;
  final List<String> members;
  final double? budget;
  final double? spent;
  final bool budgetControlEnabled;
  final int createdAt; // Stored as millisecondsSinceEpoch

  GroceryList({
    required this.id,
    required this.title,
    required this.ownerId,
    required this.members,
    this.budget,
    this.spent,
    this.budgetControlEnabled = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'ownerId': ownerId,
        'members': members,
        'budget': budget,
        'spent': spent,
        'budgetControlEnabled': budgetControlEnabled,
        'createdAt': createdAt,
      };

  factory GroceryList.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroceryList(
      id: doc.id,
      title: data['title'] ?? '',
      ownerId: data['ownerId'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      budget: (data['budget'] as num?)?.toDouble(),
      spent: (data['spent'] as num?)?.toDouble(),
      budgetControlEnabled: data['budgetControlEnabled'] ?? false,
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }
}

int _parseTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.millisecondsSinceEpoch;
  } else if (timestamp is int) {
    return timestamp;
  }
  // Fallback for cases where the timestamp is null or of an unexpected type
  return DateTime.now().millisecondsSinceEpoch;
}
