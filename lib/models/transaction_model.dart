class TransactionModel {
  final int? id;
  final String date;
  final double amount;
  final int? categoryId;
  final int? subcategoryId;
  final String? description;

  TransactionModel({
    this.id,
    required this.date,
    required this.amount,
    this.categoryId,
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

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      date: map['date'] as String,
      amount: map['amount'] as double,
      categoryId: map['category_id'] as int?,
      subcategoryId: map['subcategory_id'] as int?,
      description: map['description'] as String?,
    );
  }

  DateTime get dateTime => DateTime.parse(date);
}
