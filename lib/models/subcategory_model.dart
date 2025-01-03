class Subcategory {
  int? id;
  int categoryId;
  String name;

  Subcategory({
    this.id,
    required this.categoryId,
    required this.name,
  });

  factory Subcategory.fromMap(Map<String, dynamic> map) {
    return Subcategory(
      id: map['id'],
      categoryId: map['category_id'],
      name: map['subcategory_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'subcategory_name': name,
    };
  }
}
