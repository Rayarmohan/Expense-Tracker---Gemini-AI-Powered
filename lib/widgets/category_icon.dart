import 'package:flutter/material.dart';
import 'package:expense_tracker/config/constants.dart';

class CategoryIcon extends StatelessWidget {
  final String category;
  final double size;

  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(AppConstants.categoryColors[category] ?? 0xFFDDA0DD);
    final icon = _getIcon(category);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }

  IconData _getIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Travel':
        return Icons.flight;
      case 'Utilities':
        return Icons.electrical_services;
      case 'Entertainment':
        return Icons.movie;
      default:
        return Icons.more_horiz;
    }
  }
}
