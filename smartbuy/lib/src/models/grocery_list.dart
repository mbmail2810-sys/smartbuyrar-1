import 'package:cloud_firestore/cloud_firestore.dart';

enum MemberRole { owner, editor, viewer }

class ListMember {
  final String userId;
  final MemberRole role;
  final int joinedAt;

  ListMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'role': role.name,
    'joinedAt': joinedAt,
  };

  factory ListMember.fromMap(Map<String, dynamic> data) {
    return ListMember(
      userId: data['userId'] ?? '',
      role: MemberRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => MemberRole.viewer,
      ),
      joinedAt: _parseTimestamp(data['joinedAt']),
    );
  }
}

class GroceryList {
  final String id;
  final String title;
  final String ownerId;
  final List<String> members;
  final Map<String, MemberRole> memberRoles;
  final double? budget;
  final double? spent;
  final bool budgetControlEnabled;
  final String? lastAlertStatus;
  final List<Map<String, dynamic>>? purchaseLog;
  final String? category;
  final String? categoryEmoji;
  final int createdAt;

  GroceryList({
    required this.id,
    required this.title,
    required this.ownerId,
    required this.members,
    Map<String, MemberRole>? memberRoles,
    this.budget,
    this.spent,
    this.budgetControlEnabled = false,
    this.lastAlertStatus,
    this.purchaseLog,
    this.category,
    this.categoryEmoji,
    required this.createdAt,
  }) : memberRoles = memberRoles ?? {};

  bool isOwner(String userId) => ownerId == userId;
  
  bool isEditor(String userId) {
    if (isOwner(userId)) return true;
    final role = memberRoles[userId];
    return role == MemberRole.editor || role == MemberRole.owner;
  }
  
  bool isViewer(String userId) {
    return members.contains(userId);
  }

  bool canEdit(String userId) => isEditor(userId);
  bool canDelete(String userId) => isOwner(userId);
  bool canShare(String userId) => isOwner(userId);
  bool canRemoveMembers(String userId) => isOwner(userId);

  MemberRole getRoleForUser(String userId) {
    if (isOwner(userId)) return MemberRole.owner;
    return memberRoles[userId] ?? MemberRole.viewer;
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'ownerId': ownerId,
    'members': members,
    'memberRoles': memberRoles.map((k, v) => MapEntry(k, v.name)),
    'budget': budget,
    'spent': spent,
    'budgetControlEnabled': budgetControlEnabled,
    'lastAlertStatus': lastAlertStatus,
    'purchaseLog': purchaseLog,
    'category': category,
    'categoryEmoji': categoryEmoji,
    'createdAt': createdAt,
  };

  factory GroceryList.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final rawRoles = data['memberRoles'] as Map<String, dynamic>? ?? {};
    final memberRoles = rawRoles.map((k, v) => MapEntry(
      k,
      MemberRole.values.firstWhere(
        (r) => r.name == v,
        orElse: () => MemberRole.viewer,
      ),
    ));

    return GroceryList(
      id: doc.id,
      title: data['title'] ?? '',
      ownerId: data['ownerId'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      memberRoles: memberRoles,
      budget: (data['budget'] as num?)?.toDouble(),
      spent: (data['spent'] as num?)?.toDouble(),
      budgetControlEnabled: data['budgetControlEnabled'] ?? false,
      lastAlertStatus: data['lastAlertStatus'] as String?,
      purchaseLog: (data['purchaseLog'] as List?)?.cast<Map<String, dynamic>>(),
      category: data['category'] as String?,
      categoryEmoji: data['categoryEmoji'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  GroceryList copyWith({
    String? id,
    String? title,
    String? ownerId,
    List<String>? members,
    Map<String, MemberRole>? memberRoles,
    double? budget,
    double? spent,
    bool? budgetControlEnabled,
    String? lastAlertStatus,
    List<Map<String, dynamic>>? purchaseLog,
    String? category,
    String? categoryEmoji,
    int? createdAt,
  }) {
    return GroceryList(
      id: id ?? this.id,
      title: title ?? this.title,
      ownerId: ownerId ?? this.ownerId,
      members: members ?? this.members,
      memberRoles: memberRoles ?? this.memberRoles,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      budgetControlEnabled: budgetControlEnabled ?? this.budgetControlEnabled,
      lastAlertStatus: lastAlertStatus ?? this.lastAlertStatus,
      purchaseLog: purchaseLog ?? this.purchaseLog,
      category: category ?? this.category,
      categoryEmoji: categoryEmoji ?? this.categoryEmoji,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

int _parseTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.millisecondsSinceEpoch;
  } else if (timestamp is int) {
    return timestamp;
  }
  return DateTime.now().millisecondsSinceEpoch;
}
