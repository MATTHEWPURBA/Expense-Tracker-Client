import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../utils/constants.dart';

class ApiService {
  static const String baseUrl = AppConstants.baseUrl;
  
  // Get headers with authentication token
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (includeAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }

  // Generic error handling
  void _handleError(http.Response response) {
    if (response.statusCode >= 400) {
      try {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw HttpException('${response.statusCode}: ${errorData['message'] ?? errorData['error'] ?? errorData.toString()}');
      } catch (e) {
        // If response body is not valid JSON
        throw HttpException('${response.statusCode}: ${response.body}');
      }
    }
  }

  // Authentication endpoints
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String? firstName,
    String? lastName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register/'),
      headers: await _getHeaders(includeAuth: false),
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
        'password_confirm': passwordConfirm,
        'first_name': firstName ?? '',
        'last_name': lastName ?? '',
      }),
    );

    _handleError(response);
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login/'),
      headers: await _getHeaders(includeAuth: false),
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    _handleError(response);
    return json.decode(response.body);
  }

  Future<void> logout(String refreshToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/logout/'),
      headers: await _getHeaders(),
      body: json.encode({
        'refresh_token': refreshToken,
      }),
    );

    _handleError(response);
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/refresh/'),
      headers: await _getHeaders(includeAuth: false),
      body: json.encode({
        'refresh': refreshToken,
      }),
    );

    _handleError(response);
    return json.decode(response.body);
  }

  // User profile endpoints
  Future<UserModel> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/profile/'),
      headers: await _getHeaders(),
    );

    _handleError(response);
    final data = json.decode(response.body);
    return UserModel.fromJson(data['user']);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> profileData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/auth/profile/'),
      headers: await _getHeaders(),
      body: json.encode(profileData),
    );

    _handleError(response);
    final data = json.decode(response.body);
    return UserModel.fromJson(data['user']);
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/password/change/'),
      headers: await _getHeaders(),
      body: json.encode({
        'old_password': oldPassword,
        'new_password': newPassword,
        'new_password_confirm': newPasswordConfirm,
      }),
    );

    _handleError(response);
  }

  // Transaction endpoints
  Future<List<TransactionModel>> getTransactions({
    int page = 1,
    String? category,
    String? startDate,
    String? endDate,
  }) async {
    Map<String, String> queryParams = {'page': page.toString()};
    if (category != null) queryParams['category'] = category;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final uri = Uri.parse('$baseUrl/api/transactions/list/').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri, headers: await _getHeaders());
    _handleError(response);

    final data = json.decode(response.body);
    final List<dynamic> transactionsList = data['results'] ?? data;
    return transactionsList.map((json) => TransactionModel.fromJson(json)).toList();
  }

  Future<TransactionModel> createTransaction(Map<String, dynamic> transactionData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/transactions/create/'),
      headers: await _getHeaders(),
      body: json.encode(transactionData),
    );

    _handleError(response);
    return TransactionModel.fromJson(json.decode(response.body));
  }

  Future<TransactionModel> updateTransaction(int id, Map<String, dynamic> transactionData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/transactions/$id/update/'),
      headers: await _getHeaders(),
      body: json.encode(transactionData),
    );

    _handleError(response);
    return TransactionModel.fromJson(json.decode(response.body));
  }

  Future<void> deleteTransaction(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/transactions/$id/delete/'),
      headers: await _getHeaders(),
    );

    _handleError(response);
  }

  // Category endpoints
  Future<List<CategoryModel>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/categories/list/'),
      headers: await _getHeaders(),
    );

    _handleError(response);
    final List<dynamic> categoriesList = json.decode(response.body);
    return categoriesList.map((json) => CategoryModel.fromJson(json)).toList();
  }

  Future<CategoryModel> createCategory(Map<String, dynamic> categoryData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/categories/create/'),
      headers: await _getHeaders(),
      body: json.encode(categoryData),
    );

    _handleError(response);
    return CategoryModel.fromJson(json.decode(response.body));
  }

  // Analytics endpoints
  Future<Map<String, dynamic>> getAnalytics({
    String? period,
    String? startDate,
    String? endDate,
  }) async {
    Map<String, String> queryParams = {};
    if (period != null) queryParams['period'] = period;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final uri = Uri.parse('$baseUrl/api/analytics/summary/').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri, headers: await _getHeaders());
    _handleError(response);

    return json.decode(response.body);
  }
} 