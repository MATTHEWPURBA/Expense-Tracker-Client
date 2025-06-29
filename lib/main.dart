import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/category_provider.dart';
import 'providers/currency_provider.dart';
import 'routes/app_routes.dart';
import 'services/api_service.dart';
import 'utils/theme.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider(ApiService()),
        ),
        ChangeNotifierProvider(
          create: (context) => CurrencyProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TransactionProvider>(
          create: (context) => TransactionProvider(ApiService()),
          update: (context, auth, previous) {
            // Reuse the previous provider instance if it exists
            if (previous != null) {
              previous.updateAuth(auth);
              return previous;
            }
            // Create new instance only if previous doesn't exist
            return TransactionProvider(ApiService())..updateAuth(auth);
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, CategoryProvider>(
          create: (context) => CategoryProvider(ApiService()),
          update: (context, auth, previous) {
            // Reuse the previous provider instance if it exists
            if (previous != null) {
              previous.updateAuth(auth);
              return previous;
            }
            // Create new instance only if previous doesn't exist
            return CategoryProvider(ApiService())..updateAuth(auth);
          },
        ),
      ],
      child: MaterialApp(
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
} 