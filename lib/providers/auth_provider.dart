import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'currency_provider.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  
  UserModel? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._apiService) {
    _checkAuthStatus();
  }

  // Getters
  UserModel? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Check if user is already authenticated
  Future<void> _checkAuthStatus() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(AppConstants.isLoggedInKey) ?? false;
      final accessToken = prefs.getString(AppConstants.accessTokenKey);
      final userDataString = prefs.getString(AppConstants.userDataKey);

      if (isLoggedIn && accessToken != null && userDataString != null) {
        _user = UserModel.fromJson(json.decode(userDataString));
        _isAuthenticated = true;
        
        // Try to refresh user data from server
        try {
          await refreshUserData();
        } catch (e) {
          // If refresh fails, logout user
          await logout();
        }
      }
    } catch (e) {
      _setError('Failed to check authentication status');
    } finally {
      _setLoading(false);
    }
  }

  // Register new user
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String? firstName,
    String? lastName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.register(
        username: username,
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
        firstName: firstName,
        lastName: lastName,
      );

      await _handleAuthSuccess(response);
      return true;
    } on HttpException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Registration failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login user
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.login(
        username: username,
        password: password,
      );

      await _handleAuthSuccess(response);
      return true;
    } on HttpException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Login failed. Please check your credentials.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
      
      if (refreshToken != null) {
        try {
          await _apiService.logout(refreshToken);
        } catch (e) {
          // Continue with logout even if API call fails
        }
      }

      // Clear local storage
      await prefs.clear();
      
      _user = null;
      _isAuthenticated = false;
      _clearError();
      
      notifyListeners();
    } catch (e) {
      _setError('Logout failed');
    }
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    try {
      _user = await _apiService.getProfile();
      
      // Update stored user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userDataKey, json.encode(_user!.toJson()));
      
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to refresh user data');
    }
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _apiService.updateProfile(profileData);
      
      // Update stored user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userDataKey, json.encode(_user!.toJson()));
      
      notifyListeners();
      return true;
    } on HttpException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to update profile');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user currency
  Future<bool> updateCurrency(String currencyCode) async {
    print('🔄 DEBUG: updateCurrency called with: $currencyCode');
    _setLoading(true);
    _clearError();

    try {
      // Create profile data with only the currency update
      final profileData = {
        'currency': currencyCode,
      };
      
      print('🔄 DEBUG: Sending profile data: $profileData');
      _user = await _apiService.updateProfile(profileData);
      print('🔄 DEBUG: Profile update successful, new currency: ${_user?.profile?.currency}');
      
      // Update stored user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userDataKey, json.encode(_user!.toJson()));
      
      notifyListeners();
      return true;
    } on HttpException catch (e) {
      print('🔴 ERROR: HttpException during currency update: ${e.message}');
      _setError(e.message);
      return false;
    } catch (e) {
      print('🔴 ERROR: General exception during currency update: $e');
      _setError('Failed to update currency');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user monthly budget
  Future<bool> updateMonthlyBudget(double? monthlyBudget) async {
    print('🔄 DEBUG: updateMonthlyBudget called with: $monthlyBudget');
    _setLoading(true);
    _clearError();

    try {
      // Create profile data with only the monthly budget update
      final profileData = {
        'monthly_budget': monthlyBudget,
      };
      
      print('🔄 DEBUG: Sending profile data: $profileData');
      _user = await _apiService.updateProfile(profileData);
      print('🔄 DEBUG: Profile update successful, new monthly budget: ${_user?.profile?.monthlyBudget}');
      
      // Update stored user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userDataKey, json.encode(_user!.toJson()));
      
      notifyListeners();
      return true;
    } on HttpException catch (e) {
      print('🔴 ERROR: HttpException during monthly budget update: ${e.message}');
      _setError(e.message);
      return false;
    } catch (e) {
      print('🔴 ERROR: General exception during monthly budget update: $e');
      _setError('Failed to update monthly budget');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Change password
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _apiService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        newPasswordConfirm: newPasswordConfirm,
      );
      
      return true;
    } on HttpException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to change password');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Handle successful authentication
  Future<void> _handleAuthSuccess(Map<String, dynamic> response) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Store tokens
    final tokens = response['tokens'];
    await prefs.setString(AppConstants.accessTokenKey, tokens['access']);
    await prefs.setString(AppConstants.refreshTokenKey, tokens['refresh']);
    
    // Store user data
    _user = UserModel.fromJson(response['user']);
    await prefs.setString(AppConstants.userDataKey, json.encode(_user!.toJson()));
    
    // Set authentication status
    await prefs.setBool(AppConstants.isLoggedInKey, true);
    _isAuthenticated = true;
    
    notifyListeners();
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

  // Get current user's currency symbol
  String getCurrencySymbol(CurrencyProvider? currencyProvider) {
    if (_user?.profile?.currency != null) {
      final currencyCode = _user!.profile!.currency!;
      
      // Try to get symbol from CurrencyProvider first
      if (currencyProvider != null) {
        try {
          final symbol = currencyProvider.getCurrencySymbol(currencyCode);
          if (symbol.isNotEmpty && (symbol != '\$' || currencyCode == 'USD')) {
            return symbol;
          }
        } catch (e) {
          // Fall through to hardcoded mappings
        }
      }
      
      // Fallback to hardcoded mappings if CurrencyProvider doesn't have it
      switch (currencyCode) {
        case 'USD': return '\$';
        case 'EUR': return '€';
        case 'GBP': return '£';
        case 'JPY': return '¥';
        case 'CAD': return 'C\$';
        case 'AUD': return 'A\$';
        case 'CHF': return 'CHF';
        case 'CNY': return '¥';
        case 'INR': return '₹';
        case 'SGD': return 'S\$';
        case 'IDR': return 'Rp'; // Indonesian Rupiah (standard code)
        case 'RP': return 'RP'; // Indonesian Rupiah (your custom code)
        case 'THB': return '฿'; // Thai Baht
        case 'MYR': return 'RM'; // Malaysian Ringgit
        case 'PHP': return '₱'; // Philippine Peso
        case 'VND': return '₫'; // Vietnamese Dong
        default: return '\$';
      }
    }
    return '\$';
  }

  // Backward compatibility getter - will be deprecated
  String get currencySymbol {
    return getCurrencySymbol(null);
  }
} 