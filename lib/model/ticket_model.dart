class TicketModel {
  final String id;
  final String title;
  final String? description;
  final String type;
  final String priority;
  final String status;
  final String raisedBy;
  final String? raisedByName;
  final List<String>? screenshotUrls;
  final String createdAt;

  TicketModel({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.priority,
    required this.status,
    required this.raisedBy,
    this.raisedByName,
    this.screenshotUrls,
    required this.createdAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      type: json['type'] ?? 'General',
      priority: json['priority'] ?? 'Medium',
      status: json['status'] ?? 'Open',
      raisedBy: json['raisedBy'] ?? '',
      raisedByName: json['raisedByFirstName'] != null 
          ? '${json['raisedByFirstName']} ${json['raisedByLastName'] ?? ''}'.trim() 
          : null,
      screenshotUrls: json['screenshotUrls'] != null 
          ? List<String>.from(json['screenshotUrls']) 
          : null,
      createdAt: json['createdAt'] ?? '',
    );
  }
}
