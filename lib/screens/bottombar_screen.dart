import 'package:flutter/material.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:pocket_watcher/screens/addexpensescreen.dart';
import 'package:pocket_watcher/screens/reportscreen.dart';
import 'package:pocket_watcher/screens/settingsscreen.dart';
import 'homescreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const AddExpenseScreen(),
    // const ReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: MotionTabBar(
        initialSelectedTab: "Home",
        labels: const ["Home", "Expense", "Settings"], //"Reports",
        icons: const [
          Icons.home,
          Icons.add,
          Icons.settings
        ], // Icons.pie_chart,
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
