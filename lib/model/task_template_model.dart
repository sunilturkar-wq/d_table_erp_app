class TaskTemplateModel {
  final String id;
  final String title;
  final String? description;
  final String? category;
  final String? priority;
  final String? frequency;
  final List<dynamic>? checklistItems;
  final String? createdBy;
  final String? creatorFirstName;
  final String? creatorLastName;
  final DateTime? createdAt;

  TaskTemplateModel({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.priority,
    this.frequency,
    this.checklistItems,
    this.createdBy,
    this.creatorFirstName,
    this.creatorLastName,
    this.createdAt,
  });

  factory TaskTemplateModel.fromJson(Map<String, dynamic> json) {
    return TaskTemplateModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'],
      priority: json['priority'],
      frequency: json['frequency'] ?? 'Once',
      checklistItems: json['checklistItems'] is List ? json['checklistItems'] : [],
      createdBy: json['createdBy']?.toString(),
      creatorFirstName: json['creatorFirstName']?.toString(),
      creatorLastName: json['creatorLastName']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'frequency': frequency,
      'checklistItems': checklistItems,
    };
  }
}
