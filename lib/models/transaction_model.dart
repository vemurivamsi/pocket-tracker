class TransactionModel {
  final int? id;
  final String date;
  final double amount;
  final int categoryId;
  final int? subcategoryId;
  final String? description;

  TransactionModel({
    this.id,
    required this.date,
    required this.amount,
    required this.categoryId,
    this.subcategoryId,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'amount': amount,
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'description': description,
    };
  }

  static TransactionModel fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      date: map['date'],
      amount: map['amount'],
      categoryId: map['category_id'],
      subcategoryId: map['subcategory_id'],
      description: map['description'],
    );
  }
}
