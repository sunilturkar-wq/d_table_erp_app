class ActivityModel {
  final String id;
  final String title;
  final String description;
  final String type;
  final String? relatedId; // taskId for navigation
  final DateTime? createdAt;
  final ActivityUser? user;

  ActivityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.relatedId,
    this.createdAt,
    this.user,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Unknown Activity',
      description: json['description'] ?? '',
      type: json['type'] ?? 'general',
      relatedId: json['relatedId']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      user: json['user'] != null ? ActivityUser.fromJson(json['user']) : null,
    );
  }
}

class ActivityUser {
  final String id;
  final String firstName;
  final String lastName;
  final String designation;

  ActivityUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.designation,
  });

  factory ActivityUser.fromJson(Map<String, dynamic> json) {
    return ActivityUser(
      id: json['userId'] ?? json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      designation: json['designation'] ?? 'Staff',
    );
  }
}
