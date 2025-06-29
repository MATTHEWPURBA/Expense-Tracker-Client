import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/category_model.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class CategoryProvider extends ChangeNotifier {
  final ApiService _apiService;
  
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;
  AuthProvider? _authProvider;
  bool _disposed = false;

  CategoryProvider(this._apiService);

  // Getters
  List<CategoryModel> get categories => _categories;
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
      
      _safeNotifyListeners();
    } on HttpException catch (e) {
      // Handle authentication errors specifically
      if (e.message.contains('401') || e.message.contains('Unauthorized')) {
        // User is not authenticated, load default categories without showing error
        _loadDefaultCategories();
        if (_categories.isNotEmpty) {
          _clearError();
        } else {
          _setError('Please log in to sync your categories');
        }
      } else {
        // Other HTTP errors - try to load default categories as fallback
        try {
          _loadDefaultCategories();
          // If default categories loaded successfully, clear the error
          if (_categories.isNotEmpty) {
            _clearError();
          } else {
            _setError('Unable to load categories: ${e.message}');
          }
        } catch (fallbackError) {
          _setError('Unable to load categories: ${e.message}');
        }
      }
    } catch (e) {
      // Try to load default categories as fallback
      try {
        _loadDefaultCategories();
        // If default categories loaded successfully, clear the error
        if (_categories.isNotEmpty) {
          _clearError();
        } else {
          _setError('Failed to load categories. Please check your connection.');
        }
      } catch (fallbackError) {
        _setError('Failed to load categories. Please check your connection.');
      }
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
      _safeNotifyListeners();
      
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
    // If categories are empty, try to load them synchronously
    if (_categories.isEmpty && !_disposed) {
      // Use Future.microtask to load categories without blocking
      Future.microtask(() {
        if (!_disposed) {
          loadCategories();
        }
      });
      // Return empty list for now, will update UI when loaded
      return [];
    }
    
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
    _safeNotifyListeners();
  }

  // Force load default categories (useful when API is not available)
  Future<void> loadDefaultCategories() async {
    _setLoading(true);
    _clearError();
    
    try {
      _loadDefaultCategories();
    } catch (e) {
      _setError('Failed to load default categories');
    } finally {
      _setLoading(false);
    }
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
    
    // Use Future.microtask to avoid setState during build
    Future.microtask(() {
      if (!_disposed && hasListeners) {
        try {
          notifyListeners();
        } catch (e) {
          // Provider was disposed during the call - ignore silently
        }
      }
    });
  }

  // Clear all data (useful for logout)
  void clear() {
    if (_disposed) return;
    _categories.clear();
    _clearError();
  }

  // Check if user is authenticated and load categories accordingly
  Future<void> loadCategoriesWithAuthCheck() async {
    _setLoading(true);
    _clearError();

    try {
      // Try to get a simple authenticated endpoint first
      await _apiService.get('/auth/profile/', includeAuth: true);
      // If successful, user is authenticated, load categories normally
      await loadCategories();
    } catch (e) {
      // User is not authenticated, load default categories
      _loadDefaultCategories();
      if (_categories.isEmpty) {
        _setError('Please log in to access your categories');
      }
    } finally {
      _setLoading(false);
    }
  }
} 