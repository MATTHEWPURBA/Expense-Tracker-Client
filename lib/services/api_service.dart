import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/notification_model.dart';
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

  // Generic GET method
  Future<Map<String, dynamic>> get(String endpoint, {bool includeAuth = true}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api$endpoint'),
      headers: await _getHeaders(includeAuth: includeAuth),
    );

    _handleError(response);
    return json.decode(response.body);
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

  // Notification endpoints
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    bool? isRead,
    bool? isArchived,
    String? type,
    String? priority,
    String? search,
    String? startDate,
    String? endDate,
    bool includeExpired = false,
    String ordering = '-created_at',
  }) async {
    Map<String, String> queryParams = {'page': page.toString()};
    if (isRead != null) queryParams['is_read'] = isRead.toString();
    if (isArchived != null) queryParams['is_archived'] = isArchived.toString();
    if (type != null) queryParams['type'] = type;
    if (priority != null) queryParams['priority'] = priority;
    if (search != null) queryParams['search'] = search;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (includeExpired) queryParams['include_expired'] = 'true';
    queryParams['ordering'] = ordering;

    final uri = Uri.parse('$baseUrl/api/notifications/list/').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri, headers: await _getHeaders());
    _handleError(response);

    final data = json.decode(response.body);
    if (data['success'] == true) {
      final List<dynamic> notificationsList = data['data']['results'] ?? data['data'];
      return notificationsList.map((json) => NotificationModel.fromJson(json)).toList();
    }
    throw HttpException('Failed to load notifications');
  }

  Future<NotificationModel> getNotification(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notifications/$id/'),
      headers: await _getHeaders(),
    );

    _handleError(response);
    return NotificationModel.fromJson(json.decode(response.body));
  }

  Future<NotificationModel> updateNotification(int id, Map<String, dynamic> notificationData) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/notifications/$id/update/'),
      headers: await _getHeaders(),
      body: json.encode(notificationData),
    );

    _handleError(response);
    final data = json.decode(response.body);
    if (data['success'] == true) {
      return NotificationModel.fromJson(data['data']);
    }
    throw HttpException('Failed to update notification');
  }

  Future<void> deleteNotification(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/notifications/$id/delete/'),
      headers: await _getHeaders(),
    );

    _handleError(response);
  }

  Future<NotificationModel> markNotificationRead(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/notifications/$id/mark-read/'),
      headers: await _getHeaders(),
    );

    _handleError(response);
    final data = json.decode(response.body);
    if (data['success'] == true) {
      return NotificationModel.fromJson(data['data']);
    }
    throw HttpException('Failed to mark notification as read');
  }

  Future<int> markAllNotificationsRead() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/notifications/mark-all-read/'),
      headers: await _getHeaders(),
    );

    _handleError(response);
    final data = json.decode(response.body);
    if (data['success'] == true) {
      return data['data']['updated_count'];
    }
    throw HttpException('Failed to mark all notifications as read');
  }

  Future<int> bulkNotificationAction({
    required List<int> notificationIds,
    required String action,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/notifications/bulk-action/'),
      headers: await _getHeaders(),
      body: json.encode({
        'notification_ids': notificationIds,
        'action': action,
      }),
    );

    _handleError(response);
    final data = json.decode(response.body);
    if (data['success'] == true) {
      return data['data']['updated_count'];
    }
    throw HttpException('Failed to perform bulk action');
  }

  Future<NotificationStats> getNotificationStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notifications/stats/'),
      headers: await _getHeaders(),
    );

    _handleError(response);
    final data = json.decode(response.body);
    if (data['success'] == true) {
      return NotificationStats.fromJson(data['data']);
    }
    throw HttpException('Failed to load notification stats');
  }

  Future<NotificationPreference> getNotificationPreferences() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notifications/preferences/'),
      headers: await _getHeaders(),
    );

    _handleError(response);
    final data = json.decode(response.body);
    if (data['success'] == true) {
      return NotificationPreference.fromJson(data['data']);
    }
    throw HttpException('Failed to load notification preferences');
  }

  Future<NotificationPreference> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/notifications/preferences/'),
      headers: await _getHeaders(),
      body: json.encode(preferences),
    );

    _handleError(response);
    final data = json.decode(response.body);
    if (data['success'] == true) {
      return NotificationPreference.fromJson(data['data']);
    }
    throw HttpException('Failed to update notification preferences');
  }

  Future<Map<String, dynamic>> getNotificationTypes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notifications/types/'),
      headers: await _getHeaders(),
    );

    _handleError(response);
    final data = json.decode(response.body);
    if (data['success'] == true) {
      return data['data'];
    }
    throw HttpException('Failed to load notification types');
  }
} 