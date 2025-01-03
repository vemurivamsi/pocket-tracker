import 'package:flutter/foundation.dart';
import '../helper/databasehelper.dart';
import '../models/income_model.dart';

class IncomeProvider extends ChangeNotifier {
  final DatabaseHelper _databaseService;
  List<IncomeModel> _incomeEntries = [];
  bool _isLoading = false;
  String? _error;

  IncomeProvider(this._databaseService);

  List<IncomeModel> get incomeEntries => _incomeEntries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadIncomeByMonth(int year, int month) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;

    try {
      final entries = await _databaseService.getIncomeByMonth(year, month);

      if (!_isLoading) return; // Check if we're still mounted/loading

      _incomeEntries = entries;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading income: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addIncome(IncomeModel income) async {
    try {
      await _databaseService.insertIncome(income);
      final now = DateTime.now();
      await loadIncomeByMonth(now.year, now.month);
    } catch (e) {
      debugPrint('Error adding income: $e');
      rethrow;
    }
  }
}
