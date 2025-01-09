import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:pocket_watcher/screens/addexpensescreen.dart';
import 'package:pocket_watcher/screens/settingsscreen.dart';
import 'homescreen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const AddExpenseScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: MotionTabBar(
        initialSelectedTab: "Home",
        labels: const ["Home", "Expense", "Settings"],
        icons: const [
          Icons.home,
          Icons.add,
          Icons.settings,
        ],
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
