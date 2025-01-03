class IncomeModel {
  final int? id;
  final double amount;
  final String date;
  final String? description;

  IncomeModel({
    this.id,
    required this.amount,
    required this.date,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date,
      'description': description,
    };
  }

  static IncomeModel fromMap(Map<String, dynamic> map) {
    return IncomeModel(
      id: map['id'],
      amount: map['amount'],
      date: map['date'],
      description: map['description'],
    );
  }
}
