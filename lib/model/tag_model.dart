class TagModel {
  final String id;
  final String name;
  final String color;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TagModel({
    required this.id,
    required this.name,
    required this.color,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? '#10b981', // default green color as per web
      createdBy: json['createdBy']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'createdBy': createdBy,
    };
  }
}
