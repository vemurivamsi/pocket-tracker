import 'subcategory_model.dart';

class Category {
  int? id;
  String name;
  List<Subcategory> subcategories;

  Category({
    this.id,
    required this.name,
    List<Subcategory>? subcategories,
  }) : subcategories = subcategories ?? [];

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['category_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_name': name,
    };
  }
}
