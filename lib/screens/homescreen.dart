import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../providers/dashboard_provider.dart';
import '../providers/income_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import 'addexpensescreen.dart';
import '../helper/databasehelper.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    final dashboardNotifier = ref.read(dashboardProvider.notifier);

    // Load initial data
    await Future.wait([
      dashboardNotifier.loadAvailableYears(),
      dashboardNotifier.loadAvailableMonths(),
    ]);

    // Then load the transaction and income data
    if (mounted) {
      await _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final dashboardNotifier = ref.read(dashboardProvider.notifier);
    final transactionNotifier = ref.read(transactionProvider.notifier);
    final incomeNotifier = ref.read(incomeProvider.notifier);

    final dateRange = dashboardNotifier.getDateRange();

    try {
      // Load data from both providers
      await Future.wait([
        transactionNotifier.loadTransactionsByDateRange(
          dateRange.start,
          dateRange.end,
        ),
        incomeNotifier.loadIncomeByMonth(
          dateRange.start.year,
          dateRange.start.month,
        ),
      ]);

      // Update dashboard data
      if (mounted) {
        final transactionState = ref.read(transactionProvider);
        final incomeState = ref.read(incomeProvider);

        final totalAmount = transactionState.transactions
            .fold(0.0, (sum, item) => sum + item.amount);
        final monthlyIncome = incomeState.incomeEntries
            .fold(0.0, (sum, item) => sum + item.amount);

        dashboardNotifier.updateDashboardData(totalAmount, monthlyIncome);

        // Update chart data
        final Map<String, double> categoryTotals = {};
        for (var transaction in transactionState.transactions) {
          final categoryDetails = await _getCategoryDetails(transaction);
          final categoryName = categoryDetails['category']!;
          categoryTotals.update(
            categoryName,
            (value) => value + transaction.amount,
            ifAbsent: () => transaction.amount,
          );
        }
        final chartData = categoryTotals.entries
            .map((entry) => ExpenseData(entry.key, entry.value))
            .toList();

        dashboardNotifier.updateChartData(chartData);
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _showCustomDatePicker() async {
    final dashboardNotifier = ref.read(dashboardProvider.notifier);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: dashboardNotifier.state.customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );

    if (picked != null) {
      dashboardNotifier.updateCustomDateRange(picked);
      dashboardNotifier.updateFilter('custom');
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final incomeState = ref.watch(incomeProvider);
    final dashboardState = ref.watch(dashboardProvider);

    final isLoading = transactionState.isLoading || incomeState.isLoading;

    return Scaffold(
      appBar: const CupertinoNavigationBar(
        middle: Text("Dashboard"),
        backgroundColor: Color.fromARGB(255, 246, 242, 247),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFilterTitle(dashboardState),
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
                            child: _buildAmountCard(
                              'Total Spent',
                              dashboardState.totalAmount,
                              Colors.blue[100]!,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildAmountCard(
                              'Remaining',
                              dashboardState.remainingAmount,
                              Colors.green[100]!,
                              isNegative: dashboardState.remainingAmount < 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Filter Cards
                      _buildFilterSection(dashboardState),

                      // Pie Chart
                      if (dashboardState.chartData.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildPieChart(dashboardState.chartData),
                      ],

                      // Transactions List
                      if (transactionState.transactions.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildTransactionsList(transactionState.transactions),
                      ] else ...[
                        _buildEmptyState(),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAmountCard(String title, double amount, Color color,
      {bool isNegative = false}) {
    return Card(
      elevation: 4,
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isNegative ? Colors.red : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(DashboardState dashboardState) {
    return Column(
      children: [
        Row(
          children: [
            _buildFilterButton('today', 'Today', dashboardState),
            const SizedBox(width: 8),
            _buildFilterButton('month', 'Month', dashboardState),
            const SizedBox(width: 8),
            _buildFilterButton('year', 'Year', dashboardState),
          ],
        ),
        const SizedBox(height: 12),
        if (dashboardState.selectedFilter == 'month' ||
            dashboardState.selectedFilter == 'year')
          _buildDateFilters(dashboardState),
        const SizedBox(height: 12),
        _buildCustomRangeButton(dashboardState),
      ],
    );
  }

  Widget _buildFilterButton(String filter, String label, DashboardState state) {
    final isSelected = state.selectedFilter == filter;
    return Expanded(
      child: Card(
        elevation: 4,
        color: isSelected ? Colors.blue[100] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        child: InkWell(
          onTap: () {
            ref.read(dashboardProvider.notifier).updateFilter(filter);
            _loadData();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check, size: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getFilterTitle(DashboardState state) {
    switch (state.selectedFilter) {
      case 'today':
        return 'Today\'s Overview';
      case 'month':
        return '${DateFormat('MMMM yyyy').format(DateTime(state.selectedYear, state.selectedMonth))} Overview';
      case 'year':
        return '${state.selectedYear} Overview';
      case 'custom':
        if (state.customDateRange != null) {
          return '${DateFormat('MMM dd').format(state.customDateRange!.start)} - ${DateFormat('MMM dd').format(state.customDateRange!.end)} Overview';
        }
        return 'Custom Overview';
      default:
        return 'Overview';
    }
  }

  Widget _buildPieChart(List<ExpenseData> chartData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expense Distribution',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
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
                xValueMapper: (ExpenseData data, _) => data.category,
                yValueMapper: (ExpenseData data, _) => data.amount,
                dataLabelSettings: const DataLabelSettings(
                  isVisible: true,
                  labelPosition: ChartDataLabelPosition.outside,
                  textStyle: TextStyle(fontSize: 12),
                ),
                enableTooltip: true,
                legendIconType: LegendIconType.circle,
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'No expenses found',
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
                  builder: (context) => const AddExpenseScreen(),
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
    );
  }

  Widget _buildDateFilters(DashboardState state) {
    return Row(
      children: [
        if (state.selectedFilter == 'year' ||
            state.selectedFilter == 'month') ...[
          Expanded(
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: DropdownButton<int>(
                  value: state.selectedYear,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: state.availableYears.map((int year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      ref.read(dashboardProvider.notifier).updateYear(newValue);
                      _loadData();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
        if (state.selectedFilter == 'month') ...[
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: DropdownButton<int>(
                  value: state.selectedMonth,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: state.availableMonths.map((int month) {
                    return DropdownMenuItem<int>(
                      value: month,
                      child: Text(
                          DateFormat('MMMM').format(DateTime(2023, month))),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      ref
                          .read(dashboardProvider.notifier)
                          .updateMonth(newValue);
                      _loadData();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCustomRangeButton(DashboardState state) {
    final isSelected = state.selectedFilter == 'custom';
    // Reset custom date range if another filter is selected
    if (!isSelected && state.customDateRange != null) {
      ref.read(dashboardProvider.notifier).updateCustomDateRange(DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ));
    }

    return Card(
      elevation: 4,
      color: isSelected ? Colors.blue[100] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: InkWell(
        onTap: _showCustomDatePicker,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.date_range),
              const SizedBox(width: 8),
              Text(
                state.customDateRange != null
                    ? '${DateFormat('MMM dd').format(state.customDateRange!.start)} - ${DateFormat('MMM dd').format(state.customDateRange!.end)}'
                    : 'Custom Range',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                const Icon(Icons.check, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<TransactionModel> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return FutureBuilder<Map<String, String>>(
              future: _getCategoryDetails(transaction),
              builder: (context, snapshot) {
                final categoryName =
                    snapshot.data?['category'] ?? 'Uncategorized';
                final subcategoryName =
                    snapshot.data?['subcategory'] ?? categoryName;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: const Icon(
                        Icons.receipt,
                        color: Colors.blue,
                      ),
                    ),
                    title: Text(
                      subcategoryName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat('MMM dd, yyyy')
                          .format(DateTime.parse(transaction.date)),
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: Text(
                      '₹${transaction.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<Map<String, String>> _getCategoryDetails(
      TransactionModel transaction) async {
    final Map<String, String> result = {
      'category': 'Uncategorized',
      'subcategory': '',
    };

    try {
      if (transaction.categoryId != null) {
        final categoryName = await DatabaseHelper.instance
            .getCategoryNameById(transaction.categoryId!);
        if (categoryName != null) {
          result['category'] = categoryName;
        }
      }

      if (transaction.subcategoryId != null) {
        final subcategoryName = await DatabaseHelper.instance
            .getSubcategoryNameById(transaction.subcategoryId);
        if (subcategoryName != null) {
          result['subcategory'] = subcategoryName;
        }
      }
    } catch (e) {
      debugPrint('Error fetching category details: $e');
    }

    return result;
  }

  @override
  void dispose() {
    if (_controller.isAnimating) {
      _controller.stop();
    }
    _controller.dispose();
    super.dispose();
  }
}
