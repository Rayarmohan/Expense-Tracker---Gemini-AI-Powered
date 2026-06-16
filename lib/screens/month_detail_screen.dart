import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/bloc/expense_bloc.dart';
import 'package:expense_tracker/config/constants.dart';
import 'package:expense_tracker/models/expense.dart';

class MonthDetailScreen extends StatefulWidget {
  const MonthDetailScreen({super.key});

  @override
  State<MonthDetailScreen> createState() => _MonthDetailScreenState();
}

class _MonthDetailScreenState extends State<MonthDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('This Month'),
        centerTitle: true,
      ),
      body: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          if (state is! ExpenseLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final now = DateTime.now();
          final thisMonth = state.expenses.where((e) =>
              e.date.month == now.month && e.date.year == now.year).toList();
          final total = thisMonth.fold(0.0, (sum, e) => sum + e.amount);

          final categoryData = _buildCategoryData(thisMonth);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTotalCard(theme, currencyFormat, total, thisMonth.length),
                      const SizedBox(height: 24),
                      _buildPieChart(theme, categoryData),
                      const SizedBox(height: 24),
                      _buildCategoryBreakdown(theme, currencyFormat, categoryData, total),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalCard(ThemeData theme, NumberFormat currencyFormat, double total, int count) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.secondary,
              theme.colorScheme.secondary.withAlpha(180),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.secondary.withAlpha(80),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Total Spent',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSecondary.withAlpha(200),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(total),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count transaction${count != 1 ? 's' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondary.withAlpha(180),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_CategoryData> _buildCategoryData(List<Expense> expenses) {
    final map = <String, double>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map.entries.map((e) {
      return _CategoryData(
        category: e.key,
        amount: e.value,
        color: Color(AppConstants.categoryColors[e.key] ?? 0xFFDDA0DD),
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  Widget _buildPieChart(ThemeData theme, List<_CategoryData> data) {
    if (data.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'No expenses this month',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Spending Breakdown',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: _buildPieSections(data),
              ),
              duration: const Duration(milliseconds: 800),
            ),
          ),
          if (_touchedIndex >= 0 && _touchedIndex < data.length)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '${data[_touchedIndex].category}: ${NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(data[_touchedIndex].amount)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: data[_touchedIndex].color,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(List<_CategoryData> data) {
    final total = data.fold(0.0, (sum, d) => sum + d.amount);
    return data.asMap().entries.map((entry) {
      final i = entry.key;
      final d = entry.value;
      final isTouched = i == _touchedIndex;
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

  Widget _buildCategoryBreakdown(
    ThemeData theme,
    NumberFormat currencyFormat,
    List<_CategoryData> data,
    double total,
  ) {
    if (data.isEmpty) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.list_alt, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Category Details',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ...data.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              final percentage = total > 0 ? (d.amount / total * 100) : 0.0;
              final delay = Duration(milliseconds: 100 * i);

              return _buildCategoryItem(
                theme, currencyFormat, d, percentage, delay,
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    ThemeData theme,
    NumberFormat currencyFormat,
    _CategoryData data,
    double percentage,
    Duration delay,
  ) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final elapsed = _animController.value * 800;
        final itemDelay = delay.inMilliseconds.toDouble();
        final opacity = elapsed > itemDelay
            ? ((elapsed - itemDelay) / 300).clamp(0.0, 1.0)
            : 0.0;
        final offset = elapsed > itemDelay
            ? ((elapsed - itemDelay) / 300).clamp(0.0, 1.0)
            : 0.0;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - offset)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: data.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data.category,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              currencyFormat.format(data.amount),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryData {
  final String category;
  final double amount;
  final Color color;

  _CategoryData({
    required this.category,
    required this.amount,
    required this.color,
  });
}
