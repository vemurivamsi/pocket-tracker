import 'package:flutter/material.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:pocket_watcher/screens/addexpensescreen.dart';
import 'package:pocket_watcher/screens/homescreen.dart';
import 'package:pocket_watcher/screens/reportscreen.dart';
import 'package:pocket_watcher/screens/settingsscreen.dart';

class ExpenseTrackerHome extends StatefulWidget {
  final VoidCallback toggleTheme;

  const ExpenseTrackerHome({super.key, required this.toggleTheme});

  @override
  State<ExpenseTrackerHome> createState() => _ExpenseTrackerHomeState();
}

class _ExpenseTrackerHomeState extends State<ExpenseTrackerHome> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const AddExpenseScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: MotionTabBar(
        initialSelectedTab: "Home",
        labels: const ["Home", "Expense", "Reports", "Settings"],
        icons: const [Icons.home, Icons.add, Icons.pie_chart, Icons.settings],
        onTabItemSelected: (int value) {
          setState(() {
            _currentIndex = value;
          });
        },
        textStyle: const TextStyle(color: Colors.black),
      ),
    );
  }
}
