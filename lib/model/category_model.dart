class CategoryModel {
  String? id;
  String name;
  String color;
  String? createdBy;

  CategoryModel({
    this.id,
    required this.name,
    required this.color,
    this.createdBy,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      color: json['color'] ?? '',
      createdBy: json['createdBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "color": color,
      "createdBy": createdBy,
    };
  }
}
