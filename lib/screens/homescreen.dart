import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../providers/dashboard_provider.dart';
import '../providers/income_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../providers/dashboard_provider.dart'
    show DashboardProvider, ExpenseData;
import 'addexpensescreen.dart';
import '../helper/databasehelper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
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

    final dashboardProvider = context.read<DashboardProvider>();

    // Load initial data
    await Future.wait([
      dashboardProvider.loadAvailableYears(),
      dashboardProvider.loadAvailableMonths(),
    ]);

    // Then load the transaction and income data
    if (mounted) {
      await _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final dashboardProvider = context.read<DashboardProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final incomeProvider = context.read<IncomeProvider>();

    final dateRange = dashboardProvider.getDateRange();

    try {
      // Load data from both providers
      await Future.wait([
        transactionProvider.loadTransactionsByDateRange(
          dateRange.start,
          dateRange.end,
        ),
        incomeProvider.loadIncomeByMonth(
          dateRange.start.year,
          dateRange.start.month,
        ),
      ]);

      // Update dashboard data
      if (mounted) {
        final totalAmount = transactionProvider.transactions
            .fold(0.0, (sum, item) => sum + item.amount);
        final monthlyIncome = incomeProvider.incomeEntries
            .fold(0.0, (sum, item) => sum + item.amount);
        final remainingAmount = monthlyIncome - totalAmount;

        dashboardProvider.updateAmounts(
          total: totalAmount,
          monthly: monthlyIncome,
          remaining: remainingAmount,
        );

        // Update chart data
        await dashboardProvider
            .updateChartData(transactionProvider.transactions);
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _showCustomDatePicker() async {
    final dashboardProvider = context.read<DashboardProvider>();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: dashboardProvider.customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );

    if (picked != null) {
      dashboardProvider.updateCustomDateRange(picked);
      dashboardProvider.updateFilter('custom');
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final incomeProvider = context.watch<IncomeProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();

    final isLoading = transactionProvider.isLoading || incomeProvider.isLoading;

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
                        _getFilterTitle(dashboardProvider),
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
                              dashboardProvider.totalAmount,
                              Colors.blue[100]!,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildAmountCard(
                              'Remaining',
                              dashboardProvider.remainingAmount,
                              Colors.green[100]!,
                              isNegative: dashboardProvider.remainingAmount < 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Filter Cards
                      _buildFilterSection(dashboardProvider),

                      // Pie Chart
                      if (dashboardProvider.chartData.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildPieChart(dashboardProvider.chartData),
                      ],

                      // Transactions List
                      if (transactionProvider.transactions.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildTransactionsList(
                            transactionProvider.transactions),
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

  Widget _buildFilterSection(DashboardProvider dashboardProvider) {
    return Column(
      children: [
        Row(
          children: [
            _buildFilterButton('today', 'Today', dashboardProvider),
            const SizedBox(width: 8),
            _buildFilterButton('month', 'Month', dashboardProvider),
            const SizedBox(width: 8),
            _buildFilterButton('year', 'Year', dashboardProvider),
          ],
        ),
        const SizedBox(height: 12),
        if (dashboardProvider.selectedFilter == 'month' ||
            dashboardProvider.selectedFilter == 'year')
          _buildDateFilters(dashboardProvider),
        const SizedBox(height: 12),
        _buildCustomRangeButton(dashboardProvider),
      ],
    );
  }

  Widget _buildFilterButton(
      String filter, String label, DashboardProvider provider) {
    final isSelected = provider.selectedFilter == filter;
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
            provider.updateFilter(filter);
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

  String _getFilterTitle(DashboardProvider provider) {
    switch (provider.selectedFilter) {
      case 'today':
        return 'Today\'s Overview';
      case 'month':
        return '${DateFormat('MMMM yyyy').format(DateTime(provider.selectedYear, provider.selectedMonth))} Overview';
      case 'year':
        return '${provider.selectedYear} Overview';
      case 'custom':
        if (provider.customDateRange != null) {
          return '${DateFormat('MMM dd').format(provider.customDateRange!.start)} - ${DateFormat('MMM dd').format(provider.customDateRange!.end)} Overview';
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

  Widget _buildDateFilters(DashboardProvider provider) {
    return Row(
      children: [
        if (provider.selectedFilter == 'year' ||
            provider.selectedFilter == 'month') ...[
          Expanded(
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: DropdownButton<int>(
                  value: provider.selectedYear,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: provider.availableYears.map((int year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      provider.updateYear(newValue);
                      _loadData();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
        if (provider.selectedFilter == 'month') ...[
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: DropdownButton<int>(
                  value: provider.selectedMonth,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: provider.availableMonths.map((int month) {
                    return DropdownMenuItem<int>(
                      value: month,
                      child: Text(
                          DateFormat('MMMM').format(DateTime(2023, month))),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      provider.updateMonth(newValue);
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

  Widget _buildCustomRangeButton(DashboardProvider provider) {
    final isSelected = provider.selectedFilter == 'custom';
    // Reset custom date range if another filter is selected
    if (!isSelected && provider.customDateRange != null) {
      provider.updateCustomDateRange(DateTimeRange(
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
                provider.customDateRange != null
                    ? '${DateFormat('MMM dd').format(provider.customDateRange!.start)} - ${DateFormat('MMM dd').format(provider.customDateRange!.end)}'
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
