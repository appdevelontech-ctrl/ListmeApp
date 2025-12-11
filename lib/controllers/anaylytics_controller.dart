import 'package:flutter/material.dart';

import 'package:logger/logger.dart';


import '../models/anyliticsModel.dart';
import '../services/api_services.dart';

class AnalyticsProvider with ChangeNotifier {
  bool _isLoading = true;
  Analytics? _analytics;
  String _errorMessage = '';
  final Logger _logger = Logger();

  bool get isLoading => _isLoading;
  Analytics? get analytics => _analytics;
  String get errorMessage => _errorMessage;

  AnalyticsProvider() {
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final data = await ApiService().fetchAnalytics();
      _analytics = Analytics.fromJson(data);
      _logger.d('Parsed Analytics: $_analytics');
    } catch (e) {
      _errorMessage = e.toString();
      _logger.e('Error in fetchAnalytics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retry fetching analytics
  void retryFetchAnalytics() {
    fetchAnalytics();
  }
}