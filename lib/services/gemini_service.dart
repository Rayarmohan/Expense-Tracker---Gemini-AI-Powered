import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:expense_tracker/config/constants.dart';
import 'package:expense_tracker/models/expense.dart';

class GeminiService {
  GenerativeModel? _model;

  GenerativeModel get model {
    if (_model != null) return _model!;
    final apiKey = dotenv.env[AppConstants.geminiApiKeyKey];
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'replace_with_your_gemini_api_key') {
      throw Exception('Gemini API key not configured. Add it to .env file.');
    }
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    return _model!;
  }

  Future<Map<String, dynamic>> scanReceipt(File imageFile) async {
    debugPrint('========== GEMINI SCAN START ==========');
    debugPrint('Image path: ${imageFile.path}');
    debugPrint('Image exists: ${imageFile.existsSync()}');
    debugPrint('Image size: ${imageFile.lengthSync()} bytes');
    try {
      final imageBytes = await imageFile.readAsBytes();
      debugPrint('Image bytes read: ${imageBytes.length} bytes');
      final content = [
        Content.multi([
          TextPart(
            'Extract information from this receipt image. '
            'Return ONLY valid JSON with these fields: '
            'merchant_name, date (YYYY-MM-DD), amount (numeric), category '
            '(one of: Food, Shopping, Travel, Utilities, Entertainment, Others). '
            'If you cannot determine a value, use null. '
            'Do not include any other text or markdown formatting.',
          ),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      debugPrint('Sending request to Gemini...');
      final response = await model.generateContent(content);
      final text = response.text?.trim() ?? '';
      debugPrint('Gemini response text: "$text"');

      final result = _parseReceiptResponse(text);
      debugPrint('Parsed result: $result');
      debugPrint('========== GEMINI SCAN END ==========');
      return result;
    } catch (e) {
      debugPrint('========== GEMINI SCAN ERROR ==========');
      debugPrint('Error: $e');
      debugPrint('=======================================');
      final errMsg = e.toString();
      String userFriendlyError;
      if (errMsg.contains('SocketException') || errMsg.contains('failed host lookup')) {
        userFriendlyError = 'No internet connection. Please check your network and try again.';
      } else if (errMsg.contains('API key')) {
        userFriendlyError = 'Invalid API key. Please check your .env configuration.';
      } else {
        userFriendlyError = 'Failed to scan receipt. Please try again.';
      }
      return {
        'merchant_name': null,
        'date': null,
        'amount': null,
        'category': null,
        'error': userFriendlyError,
      };
    }
  }

  Map<String, dynamic> _parseReceiptResponse(String text) {
    debugPrint('Parsing Gemini response: "$text"');
    try {
      String jsonStr = text;
      if (jsonStr.startsWith('```')) {
        final lines = jsonStr.split('\n');
        lines.removeAt(0);
        jsonStr = lines.join('\n');
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final result = {
        'merchant_name': json['merchant_name']?.toString(),
        'date': json['date']?.toString(),
        'amount': json['amount'] != null
            ? double.tryParse(json['amount'].toString())
            : null,
        'category': json['category']?.toString(),
      };
      debugPrint('Parsed result: $result');
      return result;
    } catch (e) {
      debugPrint('Parse error: $e');
      return {
        'merchant_name': null,
        'date': null,
        'amount': null,
        'category': null,
        'error': 'Failed to parse receipt data',
      };
    }
  }
Future<String> generateInsights(List<Expense> expenses) async {
  if (expenses.isEmpty) {
    const message =
        'No expenses to analyze. Start adding expenses to get insights!';
    debugPrint(message);
    return message;
  }

  try {
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);

    final categoryTotals = <String, double>{};
    for (final e in expenses) {
      categoryTotals[e.category] =
          (categoryTotals[e.category] ?? 0) + e.amount;
    }

    final sortedByAmount = List<Expense>.from(expenses)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final topExpenses = sortedByAmount.take(3).toList();

    final now = DateTime.now();

    final thisMonth = expenses
        .where(
          (e) => e.date.year == now.year && e.date.month == now.month,
        )
        .toList();

    final lastMonth = expenses.where((e) {
      final last = DateTime(now.year, now.month - 1, 1);
      return e.date.year == last.year && e.date.month == last.month;
    }).toList();

    final thisMonthTotal =
        thisMonth.fold(0.0, (sum, e) => sum + e.amount);

    final lastMonthTotal =
        lastMonth.fold(0.0, (sum, e) => sum + e.amount);

    final categoryBreakdown = categoryTotals.entries
        .map((e) => '${e.key}: ₹${e.value.toStringAsFixed(2)}')
        .join('\n');

    final topExpensesStr = topExpenses
        .map(
          (e) =>
              '${e.title}: ₹${e.amount.toStringAsFixed(2)} on ${e.date.toString().substring(0, 10)}',
        )
        .join('\n');

    final prompt = '''
You are a financial analyst. Analyze this spending data and provide insights.

Total Spending: ₹${total.toStringAsFixed(2)}
Number of Transactions: ${expenses.length}

Category-wise Breakdown:
$categoryBreakdown

Top 3 Expenses:
$topExpensesStr

This Month Total: ₹${thisMonthTotal.toStringAsFixed(2)}
Last Month Total: ₹${lastMonthTotal.toStringAsFixed(2)}

Provide a natural-language spending report that includes:
1. Total spending summary
2. Category-wise breakdown insights
3. Largest expenses analysis
4. Spending trends (compare this month vs last month)
5. At least one actionable recommendation

Keep it concise and helpful (max 150 words). Use Indian Rupee (₹) format.
''';

    debugPrint('========== GEMINI PROMPT ==========');
    debugPrint(prompt);
    debugPrint('===================================');

    final response =
        await model.generateContent([Content.text(prompt)]);

    debugPrint('========== GEMINI RESPONSE ==========');
    debugPrint(response.text);
    debugPrint('=====================================');

    return response.text?.trim() ??
        'Unable to generate insights at this time.';
  } catch (e, stackTrace) {
    debugPrint('========== GEMINI ERROR ==========');
    debugPrint('Error: $e');
    debugPrint('StackTrace:');
    debugPrint(stackTrace.toString());
    debugPrint('==================================');

    return 'Failed to generate insights: $e';
  }
}
}
