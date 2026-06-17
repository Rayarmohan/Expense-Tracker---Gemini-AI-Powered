class AppConstants {
  static const String appName = 'Smart Spend';
  static const String geminiApiKeyKey = 'GEMINI_API_KEY';
  static const String expensesBoxKey = 'expenses_box';
  static const String expensesListKey = 'expenses_list';

  static const List<String> categories = [
    'Food',
    'Shopping',
    'Travel',
    'Utilities',
    'Entertainment',
    'Others',
  ];

  static const Map<String, int> categoryColors = {
    'Food': 0xFFFF6B6B,
    'Shopping': 0xFF4ECDC4,
    'Travel': 0xFF45B7D1,
    'Utilities': 0xFF96CEB4,
    'Entertainment': 0xFFFFEAA7,
    'Others': 0xFFDDA0DD,
  };
}
