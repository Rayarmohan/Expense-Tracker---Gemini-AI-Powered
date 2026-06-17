import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_tracker/models/category_data.dart';
import 'package:expense_tracker/config/constants.dart';
import 'package:expense_tracker/models/expense.dart';

List<CategoryData> buildCategoryData(List<Expense> expenses) {
  final map = <String, double>{};
  for (final e in expenses) {
    map[e.category] = (map[e.category] ?? 0) + e.amount;
  }
  return map.entries.map((e) {
    return CategoryData(
      category: e.key,
      amount: e.value,
      color: Color(AppConstants.categoryColors[e.key] ?? 0xFFDDA0DD),
    );
  }).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
}

List<PieChartSectionData> buildPieSections(
  List<CategoryData> data,
  int touchedIndex,
) {
  final total = data.fold(0.0, (sum, d) => sum + d.amount);
  return data.asMap().entries.map((entry) {
    final i = entry.key;
    final d = entry.value;
    final isTouched = i == touchedIndex;
    final percentage = total > 0 ? (d.amount / total * 100) : 0.0;
    final radius = isTouched ? 65.0 : 55.0;

    return PieChartSectionData(
      color: d.color,
      value: d.amount,
      title: '${percentage.toStringAsFixed(0)}%',
      radius: radius,
      titleStyle: TextStyle(
        fontSize: isTouched ? 14 : 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
      ),
      badgeWidget: isTouched
          ? Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: d.color,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.circle, size: 8, color: Colors.white),
            )
          : null,
      badgePositionPercentageOffset: 1.3,
    );
  }).toList();
}
