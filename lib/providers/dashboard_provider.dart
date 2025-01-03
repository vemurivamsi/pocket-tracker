import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../helper/databasehelper.dart';

class DashboardProvider extends ChangeNotifier {
  String _selectedFilter = 'today';
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  DateTimeRange? _customDateRange;
  List<int> _availableYears = [];
  List<int> _availableMonths = [];
  List<ExpenseData> _chartData = [];
  double _totalAmount = 0.0;
  double _remainingAmount = 0.0;
  double _monthlyIncome = 0.0;

  // Getters
  String get selectedFilter => _selectedFilter;
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  DateTimeRange? get customDateRange => _customDateRange;
  List<int> get availableYears => _availableYears;
  List<int> get availableMonths => _availableMonths;
  List<ExpenseData> get chartData => _chartData;
  double get totalAmount => _totalAmount;
  double get remainingAmount => _remainingAmount;
  double get monthlyIncome => _monthlyIncome;

  // Update filter
  void updateFilter(String filter) {
    _selectedFilter = filter;
    // Reset custom date range when switching to other filters
    if (filter != 'custom') {
      _customDateRange = null;
    }
    notifyListeners();
  }

  // Update year
  void updateYear(int year) {
    _selectedYear = year;
    notifyListeners();
  }

  // Update month
  void updateMonth(int month) {
    _selectedMonth = month;
    notifyListeners();
  }

  // Update custom date range
  void updateCustomDateRange(DateTimeRange range) {
    _customDateRange = range;
    notifyListeners();
  }

  // Update available years
  Future<void> loadAvailableYears() async {
    final years = await DatabaseHelper.instance.getUniqueTransactionYears();
    _availableYears = years.isEmpty ? [DateTime.now().year] : years;
    notifyListeners();
  }

  // Update available months
  Future<void> loadAvailableMonths() async {
    final months =
        await DatabaseHelper.instance.getUniqueMonthsForYear(_selectedYear);
    _availableMonths = months.isEmpty ? [DateTime.now().month] : months;
    notifyListeners();
  }

  // Update chart data
  Future<void> updateChartData(List<TransactionModel> transactions) async {
    if (transactions.isEmpty) {
      _chartData = [];
      notifyListeners();
      return;
    }

    Map<String, double> categoryTotals = {};

    for (var transaction in transactions) {
      if (transaction.categoryId != null) {
        final categoryName = await DatabaseHelper.instance
                .getCategoryNameById(transaction.categoryId!) ??
            'Uncategorized';

        categoryTotals[categoryName] =
            (categoryTotals[categoryName] ?? 0) + transaction.amount;
      }
    }

    _chartData = categoryTotals.entries
        .map((entry) => ExpenseData(entry.key, entry.value))
        .toList();

    notifyListeners();
  }

  // Update amounts
  void updateAmounts({
    required double total,
    required double monthly,
    required double remaining,
  }) {
    _totalAmount = total;
    _monthlyIncome = monthly;
    _remainingAmount = remaining;
    notifyListeners();
  }

  // Get date range based on current filter
  DateTimeRange getDateRange() {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (_selectedFilter) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'month':
        startDate = DateTime(_selectedYear, _selectedMonth, 1);
        endDate = DateTime(_selectedYear, _selectedMonth + 1, 0);
        break;
      case 'year':
        startDate = DateTime(_selectedYear, 1, 1);
        endDate = DateTime(_selectedYear, 12, 31);
        break;
      case 'custom':
        if (_customDateRange != null) {
          startDate = _customDateRange!.start;
          endDate = _customDateRange!.end;
        } else {
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        }
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }

    return DateTimeRange(start: startDate, end: endDate);
  }
}

class ExpenseData {
  final String category;
  final double amount;

  ExpenseData(this.category, this.amount);
}
