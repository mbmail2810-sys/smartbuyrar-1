import 'package:cloud_firestore/cloud_firestore.dart';

class GroceryItem {
  final String id;
  final String name;
  final String? description;
  final double? price;
  final int quantity;
  final String category;
  final bool checked;
  final List<Map<String, dynamic>>? priceHistory;
  final List<Map<String, dynamic>>? usageLog;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;

  GroceryItem({
    required this.id,
    required this.name,
    this.description,
    this.price,
    required this.quantity,
    required this.category,
    this.checked = false,
    this.priceHistory = const [],
    this.usageLog = const [],
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
        'quantity': quantity,
        'category': category,
        'checked': checked,
        'priceHistory': priceHistory?.map((e) => {
          'date': Timestamp.fromDate(e['date']),
          'price': e['price'],
        }).toList(),
        'usageLog': usageLog,
        'createdAt': Timestamp.fromDate(createdAt), // This will be overridden by FieldValue.serverTimestamp() in FirestoreService
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'createdBy': createdBy,
      };

  factory GroceryItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return GroceryItem(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] as String?,
      price: (data['price'] as num?)?.toDouble(),
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      category: data['category'] ?? 'General',
      checked: data['checked'] ?? false,
      priceHistory: (data['priceHistory'] as List<dynamic>?)
          ?.map((item) => {
                'date': _parseTimestamp(item['date']) ?? DateTime.now(),
                'price': (item['price'] as num?)?.toDouble() ?? 0.0,
              })
          .toList(),
      usageLog: (data['usageLog'] as List?)?.cast<Map<String, dynamic>>(),
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(data['updatedAt']),
      createdBy: data['createdBy'] ?? '', // Default to empty string if not found
    );
  }

  GroceryItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? quantity,
    String? category,
    bool? checked,
    List<Map<String, dynamic>>? priceHistory,
    List<Map<String, dynamic>>? usageLog,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      checked: checked ?? this.checked,
      priceHistory: priceHistory ?? this.priceHistory,
      usageLog: usageLog ?? this.usageLog,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

DateTime? _parseTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.toDate();
  } else if (timestamp is int) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  } else if (timestamp is String) {
    return DateTime.tryParse(timestamp);
  }
  return null;
}
