import 'package:hive_flutter/hive_flutter.dart';
import 'package:expense_tracker/config/constants.dart';
import 'package:expense_tracker/models/expense.dart';

class ExpenseRepository {
  late Box<Expense> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Expense>(AppConstants.expensesBoxKey);
  }

  List<Expense> getAll() {
    return _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> add(Expense expense) async {
    await _box.put(expense.id, expense);
  }

  Future<void> update(Expense expense) async {
    await _box.put(expense.id, expense);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Expense? getById(String id) {
    return _box.get(id);
  }

  double getTotal() {
    return _box.values.fold(0.0, (sum, e) => sum + e.amount);
  }

  Map<String, double> getCategoryTotals() {
    final totals = <String, double>{};
    for (final expense in _box.values) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  List<Expense> getByDateRange(DateTime start, DateTime end) {
    return _box.values.where((e) {
      return e.date.isAfter(start.subtract(const Duration(days: 1))) &&
          e.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  List<Expense> getByMonth(int year, int month) {
    return _box.values.where((e) {
      return e.date.year == year && e.date.month == month;
    }).toList();
  }

  double getTotalByMonth(int year, int month) {
    return getByMonth(year, month).fold(0.0, (sum, e) => sum + e.amount);
  }
}
