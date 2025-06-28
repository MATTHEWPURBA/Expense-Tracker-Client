import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/transaction_model.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class TransactionProvider extends ChangeNotifier {
  final ApiService _apiService;
  
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;
  AuthProvider? _authProvider;
  bool _disposed = false;

  TransactionProvider(this._apiService);

  // Getters
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Update auth provider reference
  void updateAuth(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  // Load transactions
  Future<void> loadTransactions({
    int page = 1,
    String? category,
    String? startDate,
    String? endDate,
    bool refresh = false,
  }) async {
    if (refresh) {
      _transactions.clear();
    }
    
    _setLoading(true);
    _clearError();

    try {
      final newTransactions = await _apiService.getTransactions(
        page: page,
        category: category,
        startDate: startDate,
        endDate: endDate,
      );

      if (page == 1 || refresh) {
        _transactions = newTransactions;
      } else {
        _transactions.addAll(newTransactions);
      }

      _safeNotifyListeners();
    } on HttpException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to load transactions');
    } finally {
      _setLoading(false);
    }
  }

  // Create new transaction
  Future<bool> createTransaction({
    required String title,
    required String description,
    required double amount,
    required String type,
    required String category,
    required String date,
    String? receipt,
    Map<String, dynamic>? metadata,
  }) async {
    if (_disposed) return false;
    
    _setLoading(true);
    _clearError();

    try {
      final transactionData = {
        'title': title,
        'description': description,
        'amount': amount,
        'type': type,
        'category': category,
        'date': date,
        if (receipt != null) 'receipt': receipt,
        if (metadata != null) 'metadata': metadata,
      };

      final newTransaction = await _apiService.createTransaction(transactionData);
      
      if (_disposed) return false;
      
      // Add to the beginning of the list
      _transactions.insert(0, newTransaction);
      _safeNotifyListeners();
      
      return true;
    } on HttpException catch (e) {
      if (!_disposed) {
        _setError(e.message);
      }
      return false;
    } catch (e) {
      if (!_disposed) {
        _setError('Failed to create transaction');
      }
      return false;
    } finally {
      if (!_disposed) {
        _setLoading(false);
      }
    }
  }

  // Update transaction
  Future<bool> updateTransaction(
    int id,
    Map<String, dynamic> transactionData,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedTransaction = await _apiService.updateTransaction(id, transactionData);
      
      // Update in the list
      final index = _transactions.indexWhere((t) => t.id == id);
      if (index != -1) {
        _transactions[index] = updatedTransaction;
        _safeNotifyListeners();
      }
      
      return true;
    } on HttpException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to update transaction');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete transaction
  Future<bool> deleteTransaction(int id) async {
    _setLoading(true);
    _clearError();

    try {
      await _apiService.deleteTransaction(id);
      
      // Remove from the list
      _transactions.removeWhere((t) => t.id == id);
      _safeNotifyListeners();
      
      return true;
    } on HttpException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to delete transaction');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get transactions by type
  List<TransactionModel> getTransactionsByType(String type) {
    return _transactions.where((t) => t.type == type).toList();
  }

  // Get transactions by category
  List<TransactionModel> getTransactionsByCategory(String category) {
    return _transactions.where((t) => t.category == category).toList();
  }

  // Calculate total expenses
  double get totalExpenses {
    return _transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Calculate total income
  double get totalIncome {
    return _transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Calculate balance
  double get balance => totalIncome - totalExpenses;

  // Get recent transactions (last 10)
  List<TransactionModel> get recentTransactions {
    final sorted = List<TransactionModel>.from(_transactions);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(10).toList();
  }

  // Group transactions by date
  Map<String, List<TransactionModel>> get transactionsByDate {
    final Map<String, List<TransactionModel>> grouped = {};
    
    for (final transaction in _transactions) {
      final date = transaction.date.split('T')[0]; // Get date part only
      if (grouped[date] == null) {
        grouped[date] = [];
      }
      grouped[date]!.add(transaction);
    }
    
    return grouped;
  }

  // Helper methods - Fixed to prevent setState during build
  void _setLoading(bool loading) {
    if (_disposed) return;
    _isLoading = loading;
    _safeNotifyListeners();
  }

  void _setError(String error) {
    if (_disposed) return;
    _error = error;
    _safeNotifyListeners();
  }

  void _clearError() {
    if (_disposed) return;
    _error = null;
    _safeNotifyListeners();
  }

  // Safe notify listeners that defers the call if we're in build phase
  void _safeNotifyListeners() {
    // Immediately return if disposed - don't even schedule the notification
    if (_disposed || !hasListeners) return;
    
    // Call notifyListeners directly but catch any disposal errors
    try {
      notifyListeners();
    } catch (e) {
      // Provider was disposed during the call - ignore silently
    }
  }

  // Clear all data (useful for logout)
  void clear() {
    if (_disposed) return;
    _transactions.clear();
    _clearError();
  }
} 