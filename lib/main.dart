import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:expense_tracker/config/theme.dart';
import 'package:expense_tracker/data/expense_repository.dart';
import 'package:expense_tracker/bloc/expense_bloc.dart';
import 'package:expense_tracker/bloc/theme_cubit.dart';
import 'package:expense_tracker/services/gemini_service.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/screens/main_shell.dart';
import 'package:expense_tracker/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseAdapter());
  final repository = ExpenseRepository();
  await repository.init();

  final geminiService = GeminiService();

  final settingsBox = await Hive.openBox('app_settings');
  final onboardingDone = settingsBox.get('onboarding_done', defaultValue: false) as bool;

  runApp(
    ExpenseTrackerApp(
      repository: repository,
      geminiService: geminiService,
      onboardingDone: onboardingDone,
    ),
  );
}

class ExpenseTrackerApp extends StatelessWidget {
  final ExpenseRepository repository;
  final GeminiService geminiService;
  final bool onboardingDone;

  const ExpenseTrackerApp({
    super.key,
    required this.repository,
    required this.geminiService,
    required this.onboardingDone,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ExpenseBloc(
            repository: repository,
            geminiService: geminiService,
          ),
        ),
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'Expense Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeMode,
            initialRoute: onboardingDone ? '/home' : '/onboarding',
            routes: {
              '/home': (_) => const MainShell(),
              '/onboarding': (_) => const OnboardingScreen(),
            },
          );
        },
      ),
    );
  }
}
