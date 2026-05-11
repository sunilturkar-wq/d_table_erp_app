class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String createdBy;
  final int memberCount;
  final List<dynamic>? members; // Can map to UserModel list if needed
  final String? createdAt;
  final String? updatedAt;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.createdBy,
    required this.memberCount,
    this.members,
    this.createdAt,
    this.updatedAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'];
    final derivedCount = rawMembers is List ? rawMembers.length : 0;
    return GroupModel(
      id: json['id']?.toString() ?? json['groupId']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl']?.toString(),
      createdBy: json['createdBy'] ?? '',
      memberCount: json['memberCount'] is int
          ? json['memberCount'] as int
          : int.tryParse('${json['memberCount'] ?? derivedCount}') ?? derivedCount,
      members: rawMembers is List ? rawMembers : null,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? createdBy,
    int? memberCount,
    List<dynamic>? members,
    String? createdAt,
    String? updatedAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      memberCount: memberCount ?? this.memberCount,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'memberCount': memberCount,
      'members': members,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
