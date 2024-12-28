class Subcategory {
  int? id; // Optional to support auto-increment IDs
  int categoryId; // Foreign key to the Category table
  String name;

  Subcategory({this.id, required this.categoryId, required this.name});

  // Convert a Subcategory object to a Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'subcategory_name': name,
    };
  }

  // Create a Subcategory object from a Map (retrieved from the database)
  factory Subcategory.fromMap(Map<String, dynamic> map) {
    return Subcategory(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int,
      name: map['subcategory_name'] as String,
    );
  }
}
