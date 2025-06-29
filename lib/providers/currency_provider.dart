import 'package:flutter/material.dart';
import '../services/api_service.dart';

class Currency {
  final String code;
  final String name;
  final String symbol;

  Currency({
    required this.code,
    required this.name,
    required this.symbol,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'symbol': symbol,
    };
  }
}

class CurrencyProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Currency> _currencies = [];
  bool _isLoading = false;
  String? _error;

  List<Currency> get currencies => _currencies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fallback currencies in case API fails
  static const List<Map<String, String>> _fallbackCurrencies = [
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'C\$'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$'},
    {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'CHF'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥'},
    {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': 'S\$'},
  ];

  Future<void> loadCurrencies({bool refresh = false}) async {
    if (_currencies.isNotEmpty && !refresh) {
      print('💱 DEBUG: Using cached currencies (${_currencies.length} items)');
      return;
    }

    print('💱 DEBUG: Loading currencies from API (refresh: $refresh)...');
    _setLoading(true);
    _setError(null);

    try {
      // Try to fetch from API first
      print('💱 DEBUG: Making API call to /currencies/list/');
      final response = await _apiService.get('/currencies/list/');
      print('💱 DEBUG: API response received: $response');
      
      if (response['success'] == true && response['data'] != null) {
        final currencyList = response['data'] as List;
        _currencies = currencyList.map((item) => Currency.fromJson(item)).toList();
        print('💱 SUCCESS: Loaded ${_currencies.length} currencies from API');
        
        // Log the actual currency names to verify database data
        for (var currency in _currencies) {
          print('💱 DEBUG: Currency: ${currency.code} - ${currency.name} (${currency.symbol})');
        }
        
        // Clear any previous error since API call succeeded
        _setError(null);
      } else {
        throw Exception('API returned unsuccessful response: ${response}');
      }
    } catch (e) {
      print('💱 ERROR: Failed to load currencies from API: $e');
      
      // Only use fallback currencies if we don't have any currencies yet
      if (_currencies.isEmpty) {
        print('💱 DEBUG: Using fallback currencies as backup...');
        _currencies = _fallbackCurrencies.map((item) => Currency.fromJson(item)).toList();
        _setError('Using offline currencies. Check your connection and try again.');
      } else {
        print('💱 DEBUG: Keeping existing currencies, failed to refresh');
        _setError('Failed to refresh currencies. Using cached data.');
      }
    }

    _setLoading(false);
  }

  Currency? getCurrencyByCode(String code) {
    try {
      return _currencies.firstWhere((currency) => currency.code == code);
    } catch (e) {
      return null;
    }
  }

  String getCurrencySymbol(String code) {
    final currency = getCurrencyByCode(code);
    return currency?.symbol ?? '\$';
  }

  String getCurrencyName(String code) {
    final currency = getCurrencyByCode(code);
    return currency?.name ?? 'Unknown Currency';
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    _safeNotifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    try {
      notifyListeners();
    } catch (e) {
      print('💱 WARNING: Error notifying listeners: $e');
    }
  }

  // Initialize with fallback currencies immediately
  void initializeWithFallback() {
    if (_currencies.isEmpty) {
      _currencies = _fallbackCurrencies.map((item) => Currency.fromJson(item)).toList();
      print('💱 DEBUG: Initialized with ${_currencies.length} fallback currencies');
      _safeNotifyListeners();
    }
  }
} 