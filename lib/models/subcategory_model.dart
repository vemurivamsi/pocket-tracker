class Subcategory {
  final int? id;
  final String? name;
  final int? categoryId;

  Subcategory({
    this.id,
    this.name,
    this.categoryId,
  });

  Subcategory copyWith({
    int? id,
    String? name,
    int? categoryId,
  }) {
    return Subcategory(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  factory Subcategory.fromMap(Map<String, dynamic> map) {
    return Subcategory(
      id: map['id'],
      name: map['subcategory_name'],
      categoryId: map['category_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subcategory_name': name,
      'category_id': categoryId,
    };
  }
}
