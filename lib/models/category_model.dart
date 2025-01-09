import 'subcategory_model.dart';

class Category {
  int? id;
  String name;
  List<Subcategory>? subcategories;

  Category({
    this.id,
    required this.name,
    this.subcategories,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['category_name'] ?? '',
      subcategories: (map['subcategories'] as List<dynamic>?)
          ?.map((item) => Subcategory.fromMap(item))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_name': name,
      'subcategories': subcategories?.map((item) => item.toMap()).toList(),
    };
  }
}
