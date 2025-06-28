import 'dart:io';
import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class CategoryProvider extends ChangeNotifier {
  final ApiService _apiService;
  
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;
  AuthProvider? _authProvider;

  CategoryProvider(this._apiService);

  // Getters
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Update auth provider reference
  void updateAuth(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  // Load categories
  Future<void> loadCategories({bool refresh = false}) async {
    if (refresh) {
      _categories.clear();
    }
    
    _setLoading(true);
    _clearError();

    try {
      _categories = await _apiService.getCategories();
      
      // If no categories exist, initialize with default categories
      if (_categories.isEmpty) {
        await _initializeDefaultCategories();
      }
      
      notifyListeners();
    } on HttpException catch (e) {
      _setError(e.message);
      // If API fails, load default categories for offline use
      _loadDefaultCategories();
    } catch (e) {
      _setError('Failed to load categories');
      // If API fails, load default categories for offline use
      _loadDefaultCategories();
    } finally {
      _setLoading(false);
    }
  }

  // Create new category
  Future<bool> createCategory({
    required String name,
    required String description,
    String? icon,
    String? color,
    required String type,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final categoryData = {
        'name': name,
        'description': description,
        'type': type,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
      };

      final newCategory = await _apiService.createCategory(categoryData);
      
      _categories.add(newCategory);
      notifyListeners();
      
      return true;
    } on HttpException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to create category');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get categories by type
  List<CategoryModel> getCategoriesByType(String type) {
    return _categories.where((c) {
      if (type == 'expense') {
        return c.isExpenseCategory;
      } else if (type == 'income') {
        return c.isIncomeCategory;
      }
      return true;
    }).toList();
  }

  // Get expense categories
  List<CategoryModel> get expenseCategories => getCategoriesByType('expense');

  // Get income categories
  List<CategoryModel> get incomeCategories => getCategoriesByType('income');

  // Find category by name
  CategoryModel? findCategoryByName(String name) {
    try {
      return _categories.firstWhere((c) => c.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  // Find category by id
  CategoryModel? findCategoryById(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Initialize default categories
  Future<void> _initializeDefaultCategories() async {
    final defaultExpenseCategories = CategoryModel.getDefaultExpenseCategories();
    final defaultIncomeCategories = CategoryModel.getDefaultIncomeCategories();
    
    final allDefaultCategories = [...defaultExpenseCategories, ...defaultIncomeCategories];
    
    for (final category in allDefaultCategories) {
      try {
        await createCategory(
          name: category.name,
          description: category.description,
          icon: category.icon,
          color: category.color,
          type: category.type,
        );
      } catch (e) {
        // Continue with other categories if one fails
        continue;
      }
    }
  }

  // Load default categories for offline use
  void _loadDefaultCategories() {
    _categories = [
      ...CategoryModel.getDefaultExpenseCategories(),
      ...CategoryModel.getDefaultIncomeCategories(),
    ];
    notifyListeners();
  }

  // Get category names for dropdown
  List<String> getCategoryNames(String type) {
    return getCategoriesByType(type).map((c) => c.name).toList();
  }

  // Get category color
  Color getCategoryColor(String categoryName) {
    final category = findCategoryByName(categoryName);
    if (category?.color != null) {
      try {
        final colorString = category!.color!.replaceFirst('#', '');
        return Color(int.parse('FF$colorString', radix: 16));
      } catch (e) {
        return Colors.grey;
      }
    }
    return Colors.grey;
  }

  // Get category icon
  String getCategoryIcon(String categoryName) {
    final category = findCategoryByName(categoryName);
    return category?.icon ?? '📋';
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all data (useful for logout)
  void clear() {
    _categories.clear();
    _clearError();
    notifyListeners();
  }
} 