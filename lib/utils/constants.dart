class AppConstants {
  // Database Constants
  static const String dbName = 'categories_subcategories.db';
  static const String settingsDbName = 'settings.db';

  // Table Names
  static const String categoriesTable = 'categories';
  static const String subcategoriesTable = 'subcategories';
  static const String transactionsTable = 'transactions';
  static const String incomeTable = 'income';
  static const String settingsTable = 'settings';

  // Theme Constants
  static const String lightTheme = 'Light';
  static const String darkTheme = 'Dark';

  // Message Constants
  static const String errorLoadingData = 'Error loading data';
  static const String successMessage = 'Operation completed successfully';
  static const String errorMessage = 'An error occurred';
  static const String deleteConfirmation = 'Are you sure you want to delete?';
  static const String categoryExists = 'Category already exists';
  static const String subcategoryExists = 'Subcategory already exists';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardElevation = 4.0;
  static const double borderRadius = 12.0;
}
