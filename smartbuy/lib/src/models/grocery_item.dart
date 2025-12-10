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
    final rawData = doc.data();
    if (rawData == null) {
      return GroceryItem(
        id: doc.id,
        name: 'Unknown Item',
        quantity: 1,
        category: 'General',
        createdAt: DateTime.now(),
        createdBy: '',
      );
    }
    
    final data = rawData as Map<String, dynamic>;

    List<Map<String, dynamic>>? parsedPriceHistory;
    try {
      parsedPriceHistory = (data['priceHistory'] as List<dynamic>?)
          ?.map((item) {
            if (item is! Map) return <String, dynamic>{};
            return {
              'date': _parseTimestamp(item['date']) ?? DateTime.now(),
              'price': (item['price'] as num?)?.toDouble() ?? 0.0,
            };
          })
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      parsedPriceHistory = null;
    }

    List<Map<String, dynamic>>? parsedUsageLog;
    try {
      parsedUsageLog = (data['usageLog'] as List<dynamic>?)
          ?.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      parsedUsageLog = null;
    }

    return GroceryItem(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString(),
      price: (data['price'] as num?)?.toDouble(),
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      category: data['category']?.toString() ?? 'General',
      checked: data['checked'] == true,
      priceHistory: parsedPriceHistory,
      usageLog: parsedUsageLog,
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(data['updatedAt']),
      createdBy: data['createdBy']?.toString() ?? '',
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroceryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
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
