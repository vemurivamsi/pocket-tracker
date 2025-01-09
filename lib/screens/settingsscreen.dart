import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helper/settingdatabasehelper.dart';
import 'category_management_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  String selectedTheme = "Light";
  String salaryCreditDate = "";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsDatabaseHelper().getSettings();
    setState(() {
      _nameController.text = settings['name'] ?? '';
      selectedTheme = settings['theme'] ?? 'Light';
      salaryCreditDate = settings['salary_date'] ?? '';
    });
  }

  Future<void> _saveSettings() async {
    await SettingsDatabaseHelper().updateSettings({
      'name': _nameController.text,
      'theme': selectedTheme,
      'salary_date': salaryCreditDate,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully!')),
    );
  }

  Future<void> showCustomDayPicker({
    required BuildContext context,
    required String currentDay,
    required ValueChanged<String> onDaySelected,
  }) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 270,
        color: Colors.white,
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem:
                      currentDay.isEmpty ? 0 : int.parse(currentDay) - 1,
                ),
                itemExtent: 32,
                onSelectedItemChanged: (int value) {
                  onDaySelected((value + 1).toString());
                },
                children: List<Widget>.generate(31, (int index) {
                  return Center(
                    child: Text(
                      "Day ${index + 1}",
                      style: const TextStyle(fontSize: 18),
                    ),
                  );
                }),
              ),
            ),
            CupertinoButton(
              child: const Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CupertinoNavigationBar(
        middle: Text("Settings"),
        backgroundColor: Color.fromARGB(255, 246, 242, 247),
      ),
      body: Column(
        children: [
          // Fixed Header Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Name",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _nameController,
                    placeholder: "Enter your name",
                    prefix: const Icon(CupertinoIcons.person,
                        color: CupertinoColors.systemGrey),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Manage Categories Button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CategoryManagementScreen(),
                          ),
                        );
                      },
                      child: _buildCard(
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Categories",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Icon(
                              CupertinoIcons.right_chevron,
                              color: CupertinoColors.systemGrey,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Theme Selection
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Theme",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CupertinoRadioButton(
                                    value: "Light",
                                    groupValue: selectedTheme,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedTheme = value!;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  const Text("Light"),
                                ],
                              ),
                              Row(
                                children: [
                                  CupertinoRadioButton(
                                    value: "Dark",
                                    groupValue: selectedTheme,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedTheme = value!;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  const Text("Dark"),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Salary Credit Date
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Salary Credited on every month",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                salaryCreditDate.isEmpty
                                    ? "Not Set"
                                    : salaryCreditDate,
                                style: const TextStyle(
                                    color: CupertinoColors.systemGrey),
                              ),
                              CupertinoButton(
                                onPressed: () async {
                                  await showCustomDayPicker(
                                    context: context,
                                    currentDay: salaryCreditDate,
                                    onDaySelected: (selectedDay) {
                                      setState(() {
                                        salaryCreditDate = selectedDay;
                                      });
                                    },
                                  );
                                },
                                child: const Text("Pick Day"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Save Button
                    CupertinoButton.filled(
                      onPressed: _saveSettings,
                      child: const Text("Save"),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CupertinoRadioButton<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final ValueChanged<T?>? onChanged;

  const CupertinoRadioButton({
    super.key,
    required this.value,
    required this.groupValue,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged?.call(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 30,
        width: 30,
        decoration: BoxDecoration(
          color: isSelected
              ? CupertinoColors.activeBlue.withOpacity(0.6)
              : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? CupertinoColors.activeBlue.withOpacity(0.6)
                : CupertinoColors.systemGrey,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: CupertinoColors.activeBlue.withOpacity(0.4),
                    // spreadRadius: 1,
                    blurRadius: 8,
                  )
                ]
              : [],
        ),
        child: Center(
          child: isSelected
              ? Container(
                  height: 12, // Adjust the size of the white dot
                  width: 12,
                  decoration: const BoxDecoration(
                    color: Colors.white, // White dot color
                    shape: BoxShape.circle,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
