class DatabaseTables {
  static const String createCategoriesTable = '''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_name TEXT NOT NULL UNIQUE
    )
  ''';

  static const String createSubcategoriesTable = '''
    CREATE TABLE subcategories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_id INTEGER,
      subcategory_name TEXT NOT NULL,
      FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
      UNIQUE (category_id, subcategory_name)
    )
  ''';

  static const String createTransactionsTable = '''
    CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      amount REAL NOT NULL,
      category_id INTEGER,
      subcategory_id INTEGER,
      description TEXT,
      FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
      FOREIGN KEY (subcategory_id) REFERENCES subcategories(id) ON DELETE SET NULL
    )
  ''';

  static const String createIncomeTable = '''
    CREATE TABLE income (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL NOT NULL,
      date TEXT NOT NULL,
      description TEXT
    )
  ''';
}
