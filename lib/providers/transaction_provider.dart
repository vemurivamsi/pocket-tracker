import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../helper/databasehelper.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseHelper _databaseService;
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  TransactionProvider(this._databaseService);

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  Future<void> loadTransactionsByDateRange(DateTime start, DateTime end) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _startDate = start;
    _endDate = end;

    try {
      final loadedTransactions =
          await _databaseService.getTransactionsByDateRange(start, end);

      if (!_isLoading) return; // Check if we're still mounted/loading

      _transactions = loadedTransactions;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _databaseService.insertTransaction(transaction);
      await loadTransactionsByDateRange(_startDate, _endDate);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding transaction: $e');
      rethrow;
    }
  }
}
