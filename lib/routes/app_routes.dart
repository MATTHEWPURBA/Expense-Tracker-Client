import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/logout_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/transactions/transaction_list_screen.dart';
import '../screens/transactions/add_transaction_screen.dart';
import '../screens/transactions/edit_transaction_screen.dart';
import '../screens/categories/category_list_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../models/transaction_model.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String addTransaction = '/add-transaction';
  static const String editTransaction = '/edit-transaction';
  static const String categories = '/categories';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String analytics = '/analytics';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      
      case logout:
        return MaterialPageRoute(builder: (_) => const LogoutScreen());
      
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      
      case transactions:
        return MaterialPageRoute(builder: (_) => const TransactionListScreen());
      
      case addTransaction:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AddTransactionScreen(
            initialType: args?['type'] as String?,
          ),
        );
      
      case editTransaction:
        final transaction = settings.arguments as TransactionModel;
        return MaterialPageRoute(
          builder: (_) => EditTransactionScreen(transaction: transaction),
        );
      
      case categories:
        return MaterialPageRoute(builder: (_) => const CategoryListScreen());
      
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      
      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      
      case analytics:
        return MaterialPageRoute(builder: (_) => const AnalyticsScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  // Navigation helpers
  static void navigateToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, login, (route) => false);
  }

  static void navigateToLogout(BuildContext context) {
    Navigator.pushNamed(context, logout);
  }

  static void navigateToDashboard(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, dashboard, (route) => false);
  }

  static Future<bool?> navigateToAddTransaction(BuildContext context, {String? type}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          initialType: type,
        ),
      ),
    );
    return result;
  }

  static void navigateToEditTransaction(BuildContext context, TransactionModel transaction) {
    Navigator.pushNamed(context, editTransaction, arguments: transaction);
  }

  static void navigateToProfile(BuildContext context) {
    Navigator.pushNamed(context, profile);
  }

  static void navigateToEditProfile(BuildContext context) {
    Navigator.pushNamed(context, editProfile);
  }

  static void navigateToTransactions(BuildContext context) {
    Navigator.pushNamed(context, transactions);
  }

  static void navigateToCategories(BuildContext context) {
    Navigator.pushNamed(context, categories);
  }

  static void navigateToAnalytics(BuildContext context) {
    Navigator.pushNamed(context, analytics);
  }
} 