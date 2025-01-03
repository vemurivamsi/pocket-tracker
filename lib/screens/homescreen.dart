import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pocket_watcher/models/income_model.dart';
import 'package:pocket_watcher/models/transaction_model.dart';
import 'package:pocket_watcher/helper/databasehelper.dart';
import 'package:intl/intl.dart';
import 'package:pocket_watcher/screens/addexpensescreen.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double totalAmount = 0.0;
  double remainingAmount = 0.0;
  double monthlyIncome = 0.0;
  List<TransactionModel> currentMonthTransactions = [];
  bool isLoading = true;
  List<ExpenseData> chartData = [];
  String selectedFilter = 'today'; // 'today', 'month', 'year', 'custom'
  DateTimeRange? customDateRange;
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  List<int> availableYears = [];
  List<int> availableMonths = [];
  final Map<String, bool> _expandedCategories = {};

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate;

      switch (selectedFilter) {
        case 'today':
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          // Get total expenses for today
          totalAmount = await DatabaseHelper.instance
              .getTotalExpensesByMonth(now.year, now.month);
          // Get income for the current month
          monthlyIncome = await DatabaseHelper.instance
              .getTotalIncomeByMonth(now.year, now.month);
          break;
        case 'month':
          startDate = DateTime(selectedYear, selectedMonth, 1);
          endDate = DateTime(selectedYear, selectedMonth + 1, 0);
          // Get total expenses for selected month
          totalAmount = await DatabaseHelper.instance
              .getTotalExpensesByMonth(selectedYear, selectedMonth);

          // Get total income for selected month
          monthlyIncome = await DatabaseHelper.instance
              .getTotalIncomeByMonth(selectedYear, selectedMonth);

          break;
        case 'year':
          startDate = DateTime(selectedYear, 1, 1);
          endDate = DateTime(selectedYear, 12, 31);
          totalAmount =
              await DatabaseHelper.instance.getTotalByYear(selectedYear);
          print('YearlyExpense : $totalAmount');
          // Get total income for the year
          monthlyIncome =
              await DatabaseHelper.instance.getTotalIncomeByYear(selectedYear);
          print('YearlyIncome : $monthlyIncome');
          break;
        case 'custom':
          if (customDateRange != null) {
            startDate = customDateRange!.start;
            endDate = customDateRange!.end;
            totalAmount = await DatabaseHelper.instance
                .getTotalByDateRange(startDate, endDate);
            // Get income for the date range
            monthlyIncome = await DatabaseHelper.instance
                .getTotalIncomeByDateRange(startDate, endDate);
          } else {
            return;
          }
          break;
        default:
          return;
      }

      // Calculate remaining amount
      remainingAmount = monthlyIncome - totalAmount;

      // Get transactions for selected period
      currentMonthTransactions = await DatabaseHelper.instance
          .getTransactionsByDateRange(startDate, endDate);

      print(
          'Loaded ${currentMonthTransactions.length} transactions'); // Debug print

      // Update chart data
      if (currentMonthTransactions.isNotEmpty) {
        final Map<String, double> categoryTotals = {};

        // Group transactions by category name
        for (var transaction in currentMonthTransactions) {
          if (transaction.categoryId != null) {
            // Get category name from database
            final categoryName = await DatabaseHelper.instance
                .getCategoryNameById(transaction.categoryId!);

            if (categoryName != null) {
              categoryTotals[categoryName] =
                  (categoryTotals[categoryName] ?? 0) + transaction.amount;
            }
          }
        }

        chartData = categoryTotals.entries
            .map((e) => ExpenseData(e.key, e.value))
            .toList();
      } else {
        chartData = [];
      }
    } catch (e, stackTrace) {
      print('Error loading data: $e');
      print(
          'Stack trace: $stackTrace'); // Added stack trace for better debugging
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _showCustomDatePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() {
        customDateRange = picked;
        selectedFilter = 'custom';
      });
      _loadData();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _loadYears();
    _loadMonths();
    _checkMonthlyIncome();
    _loadData();
  }

  Future<void> _loadYears() async {
    final years = await DatabaseHelper.instance.getUniqueTransactionYears();
    setState(() {
      availableYears = years.isEmpty ? [DateTime.now().year] : years;
      selectedYear = years.isEmpty ? DateTime.now().year : years.first;
    });
  }

  Future<void> _loadMonths() async {
    final months =
        await DatabaseHelper.instance.getUniqueMonthsForYear(selectedYear);
    setState(() {
      availableMonths = months.isEmpty ? [DateTime.now().month] : months;
      selectedMonth = months.isEmpty ? DateTime.now().month : months.first;
    });
  }

  String _getMonthName(int month) {
    return DateFormat('MMMM').format(DateTime(2024, month));
  }

  String _getFilterTitle() {
    switch (selectedFilter) {
      case 'today':
        return 'Today\'s Overview';
      case 'month':
        return '${DateFormat('MMMM yyyy').format(DateTime(selectedYear, selectedMonth))} Overview';
      case 'year':
        return '$selectedYear Overview';
      case 'custom':
        if (customDateRange != null) {
          return '${DateFormat('MMM dd').format(customDateRange!.start)} - ${DateFormat('MMM dd').format(customDateRange!.end)} Overview';
        }
        return 'Custom Overview';
      default:
        return 'Overview';
    }
  }

  Future<Map<String, List<TransactionModel>>>
      _groupTransactionsByCategory() async {
    final Map<String, List<TransactionModel>> grouped = {};

    for (var transaction in currentMonthTransactions) {
      if (transaction.categoryId != null) {
        final categoryName = await DatabaseHelper.instance
                .getCategoryNameById(transaction.categoryId) ??
            'Uncategorized';

        grouped.putIfAbsent(categoryName, () => []);
        grouped[categoryName]!.add(transaction);
      }
    }

    // Sort transactions within each category by date
    for (var transactions in grouped.values) {
      transactions.sort((a, b) => b.date.compareTo(a.date));
    }

    return grouped;
  }

  Map<DateTime, List<TransactionModel>> groupTransactionsByDate(
      List<TransactionModel> transactions) {
    final Map<DateTime, List<TransactionModel>> grouped = {};

    for (var transaction in transactions) {
      final date = DateTime.parse(transaction.date);
      final dateWithoutTime = DateTime(date.year, date.month, date.day);

      grouped.putIfAbsent(dateWithoutTime, () => []);
      grouped[dateWithoutTime]!.add(transaction);
    }

    // Sort dates in descending order
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, grouped[key]!)),
    );
  }

  Future<void> _checkMonthlyIncome() async {
    final now = DateTime.now();
    final currentMonthIncome =
        await DatabaseHelper.instance.getIncomeByMonth(now.year, now.month);

    if (currentMonthIncome.isEmpty) {
      if (mounted) {
        _showIncomeDialog();
      }
    }
  }

  Future<void> _showIncomeDialog() async {
    final TextEditingController incomeController = TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Monthly Income'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter your monthly income:'),
              TextField(
                controller: incomeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Income Amount',
                  prefixText: '₹',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                final amount = double.tryParse(incomeController.text);
                if (amount != null && amount > 0) {
                  final now = DateTime.now();
                  await DatabaseHelper.instance.insertIncome(
                    IncomeModel(
                      date: now.toString(),
                      amount: amount,
                    ),
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                    _loadData(); // Reload dashboard data
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CupertinoNavigationBar(
        middle: Text("Dashboard"),
        backgroundColor: Color.fromARGB(255, 246, 242, 247),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFilterTitle(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Amount Cards
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 4,
                              color: Colors.blue[100],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Spent',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '₹${totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Card(
                              elevation: 4,
                              color: Colors.green[100],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Remaining',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '₹${remainingAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: remainingAmount < 0
                                            ? Colors.red
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Filter Cards Section
                      Column(
                        children: [
                          // Time period filters
                          Row(
                            children: [
                              Expanded(
                                child: Card(
                                  elevation: 4,
                                  color: selectedFilter == 'today'
                                      ? Colors.blue[100]
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: Colors.grey[300]!, width: 1),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() => selectedFilter = 'today');
                                      _loadData();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 12.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Today',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                                  selectedFilter == 'today'
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                          if (selectedFilter == 'today') ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.check, size: 16),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Card(
                                  elevation: 4,
                                  color: selectedFilter == 'month'
                                      ? Colors.blue[100]
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: Colors.grey[300]!, width: 1),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() => selectedFilter = 'month');
                                      _loadMonths();
                                      _loadData();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 12.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Month',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                                  selectedFilter == 'month'
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                          if (selectedFilter == 'month') ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.check, size: 16),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Card(
                                  elevation: 4,
                                  color: selectedFilter == 'year'
                                      ? Colors.blue[100]
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: Colors.grey[300]!, width: 1),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() => selectedFilter = 'year');
                                      _loadData();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 12.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Year',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                                  selectedFilter == 'year'
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                          if (selectedFilter == 'year') ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.check, size: 16),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Month and Year filters with horizontal scroll
                          if (selectedFilter == 'month' ||
                              selectedFilter == 'year')
                            SizedBox(
                              height: 48,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    if (selectedFilter == 'month')
                                      ...availableMonths
                                          .map((month) => Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8),
                                                child: Card(
                                                  margin: EdgeInsets.zero,
                                                  elevation: 4,
                                                  color: selectedMonth == month
                                                      ? Colors.amber[100]
                                                      : Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    side: BorderSide(
                                                        color:
                                                            Colors.grey[300]!,
                                                        width: 1),
                                                  ),
                                                  child: InkWell(
                                                    onTap: () {
                                                      setState(() =>
                                                          selectedMonth =
                                                              month);
                                                      _loadData();
                                                    },
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 16.0,
                                                        vertical: 8.0,
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            _getMonthName(
                                                                month),
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  selectedMonth ==
                                                                          month
                                                                      ? FontWeight
                                                                          .bold
                                                                      : FontWeight
                                                                          .normal,
                                                            ),
                                                          ),
                                                          if (selectedMonth ==
                                                              month) ...[
                                                            const SizedBox(
                                                                width: 8),
                                                            const Icon(
                                                                Icons.check,
                                                                size: 18),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    if (selectedFilter == 'year')
                                      ...availableYears
                                          .map((year) => Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8),
                                                child: Card(
                                                  margin: EdgeInsets.zero,
                                                  elevation: 4,
                                                  color: selectedYear == year
                                                      ? Colors.amber[100]
                                                      : Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    side: BorderSide(
                                                        color:
                                                            Colors.grey[300]!,
                                                        width: 1),
                                                  ),
                                                  child: InkWell(
                                                    onTap: () {
                                                      setState(() =>
                                                          selectedYear = year);
                                                      _loadData();
                                                    },
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 16.0,
                                                        vertical: 8.0,
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            year.toString(),
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: selectedYear ==
                                                                      year
                                                                  ? FontWeight
                                                                      .bold
                                                                  : FontWeight
                                                                      .normal,
                                                            ),
                                                          ),
                                                          if (selectedYear ==
                                                              year) ...[
                                                            const SizedBox(
                                                                width: 8),
                                                            const Icon(
                                                                Icons.check,
                                                                size: 18),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          // Custom Range button (right-aligned)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Card(
                                elevation: 4,
                                color: selectedFilter == 'custom'
                                    ? Colors.deepPurple[100]
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: Colors.grey[300]!, width: 1),
                                ),
                                child: InkWell(
                                  onTap: _showCustomDatePicker,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 12.0,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                          color: selectedFilter == 'custom'
                                              ? Colors.deepPurple
                                              : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Custom Range',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: selectedFilter == 'custom'
                                                ? Colors.deepPurple
                                                : Colors.grey[600],
                                            fontWeight:
                                                selectedFilter == 'custom'
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                        if (selectedFilter == 'custom') ...[
                                          const SizedBox(width: 8),
                                          const Icon(Icons.check, size: 18),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Add this new section after the filters
                      if (currentMonthTransactions.isEmpty) ...[
                        const SizedBox(height: 60),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No expenses found for ${_getFilterTitle().toLowerCase()}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AddExpenseScreen(),
                                    ),
                                  ).then((_) => _loadData());
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Expense'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Pie Chart (Moved above Recent Transactions)
                      if (chartData.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 300,
                          child: SfCircularChart(
                            legend: Legend(
                              isVisible: true,
                              position: LegendPosition.bottom,
                              orientation: LegendItemOrientation.horizontal,
                              overflowMode: LegendItemOverflowMode.wrap,
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            series: <CircularSeries>[
                              PieSeries<ExpenseData, String>(
                                dataSource: chartData,
                                xValueMapper: (ExpenseData data, _) =>
                                    data.category,
                                yValueMapper: (ExpenseData data, _) =>
                                    data.amount,
                                dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                  labelPosition: ChartDataLabelPosition.outside,
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                      // Recent Transactions Section
                      if (currentMonthTransactions.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<Map<String, List<TransactionModel>>>(
                          future: _groupTransactionsByCategory(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final groupedTransactions = snapshot.data!;
                            final categories =
                                groupedTransactions.keys.toList();

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final categoryName = categories[index];
                                final transactions =
                                    groupedTransactions[categoryName]!;
                                final totalAmount = transactions.fold<double>(
                                    0, (sum, item) => sum + item.amount);

                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: ExpansionTile(
                                    title: Text(
                                      categoryName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      '₹${totalAmount.toStringAsFixed(2)}',
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                    children: [
                                      ...groupTransactionsByDate(transactions)
                                          .entries
                                          .map((dateEntry) {
                                        final date = dateEntry.key;
                                        final dateTransactions =
                                            dateEntry.value;

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              child: Text(
                                                DateFormat('MMMM dd, yyyy')
                                                    .format(date),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                            ...dateTransactions
                                                .map((transaction) {
                                              return ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 0,
                                                ),
                                                title: Text(
                                                    transaction.description ??
                                                        ""),
                                                trailing: Text(
                                                  '₹${transaction.amount.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              );
                                            }).toList(),
                                            const Divider(),
                                          ],
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ExpenseData {
  final String category;
  final double amount;

  ExpenseData(this.category, this.amount);
}
