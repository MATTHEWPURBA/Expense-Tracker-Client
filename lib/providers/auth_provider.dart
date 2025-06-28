import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

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
  String get currencySymbol {
    if (_user?.profile?.currency != null) {
      final currency = AppConstants.currencies.firstWhere(
        (c) => c['code'] == _user!.profile!.currency,
        orElse: () => {'symbol': '\$'},
      );
      return currency['symbol']!;
    }
    return '\$';
  }
} 