// controllers/dashboard_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import '../models/auth/user_model.dart';
import '../services/api_services.dart';
import '../views/auth/login_page.dart';
import 'auth/login_controller.dart';

class DashboardController extends ChangeNotifier {
  String _walletBalance = '0';
  String? _errorMessage;
  bool _isOnline = false;
  String? _latitude;
  String? _longitude;
  Timer? _statusTimer;

  double get walletBalance => double.tryParse(_walletBalance) ?? 0.0;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _isOnline;

  final ApiService _apiService = ApiService();

  DashboardController() {
    _loadWalletBalance();
    refreshWalletBalance();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      print('startStatusPolling: Polling user status');
      refreshWalletBalance();
    });
  }

  Future<void> _loadWalletBalance() async {
    print('loadWalletBalance: Loading wallet balance and user status from SharedPreferences');
    try {
      final user = await LoginController.getSavedUser();
      if (user != null) {
        _walletBalance = user.wallet.toString();
        _isOnline = user.status == '1';
        _latitude = user.latitude;
        _longitude = user.longitude;
        print('loadWalletBalance: Success, Wallet Balance: $_walletBalance, Online: $_isOnline, Latitude: $_latitude, Longitude: $_longitude');
        _errorMessage = null;
        notifyListeners();
      } else {
        print('loadWalletBalance: No user data found in SharedPreferences');
        _errorMessage = 'No user data found';
        notifyListeners();
      }
    } catch (e) {
      print('loadWalletBalance: Error: $e');
      _errorMessage = 'Failed to load user data: $e';
      notifyListeners();
    }
  }

  Future<void> refreshWalletBalance() async {
    print('refreshWalletBalance: Starting wallet balance and user status refresh');
    try {
      final employeeId = await _apiService.getEmployeeId();
      if (employeeId != null) {
        print('refreshWalletBalance: Fetching user data for employeeId: $employeeId');
        final response = await _apiService.fetchUserData(employeeId);
        _walletBalance = response.wallet.toString();
        _isOnline = response.status == '1';
        _latitude = response.latitude;
        _longitude = response.longitude;
        print('refreshWalletBalance: Success, Wallet Balance: $_walletBalance, Online: $_isOnline, Latitude: $_latitude, Longitude: $_longitude');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userData', json.encode(response.toJson()));
        print('refreshWalletBalance: Updated SharedPreferences with user data: ${json.encode(response.toJson())}');

        _errorMessage = null;
        notifyListeners();
      } else {
        throw Exception('No employeeId found in SharedPreferences');
      }
    } catch (e) {
      print('refreshWalletBalance: Error: $e');
      _errorMessage = e.toString();

      final user = await LoginController.getSavedUser();
      if (user != null) {
        _walletBalance = user.wallet.toString();
        _isOnline = user.status == '1';
        _latitude = user.latitude;
        _longitude = user.longitude;
        print('refreshWalletBalance: Fallback to SharedPreferences, Wallet Balance: $_walletBalance, Online: $_isOnline, Latitude: $_latitude, Longitude: $_longitude');
      } else {
        print('refreshWalletBalance: Fallback failed, no user data in SharedPreferences');
        _walletBalance = '0';
        _isOnline = false;
      }
      notifyListeners();
    }
  }

  Future<void> toggleOnlineStatus(BuildContext context, bool value) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          throw Exception('Location permissions denied');
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _latitude = position.latitude.toString();
      _longitude = position.longitude.toString();
      _isOnline = value;

      final employeeId = await _apiService.getEmployeeId();
      if (employeeId != null) {
        print('toggleOnlineStatus: Updating status for employeeId: $employeeId, Online: $value, Latitude: $_latitude, Longitude: $_longitude');
        await _apiService.updateUserMeta(
          employeeId,
          latitude: _latitude!,
          longitude: _longitude!,
          online: value ? 1 : 0,
        );

        final prefs = await SharedPreferences.getInstance();
        final userData = await prefs.getString('userData');
        if (userData != null) {
          final userJson = json.decode(userData);
          userJson['latitude'] = _latitude;
          userJson['longitude'] = _longitude;
          userJson['status'] = value ? '1' : '0';
          await prefs.setString('userData', json.encode(userJson));
          print('toggleOnlineStatus: Updated SharedPreferences with user data: ${json.encode(userJson)}');
        }
        notifyListeners();
      } else {
        throw Exception('No employeeId found');
      }
    } catch (e) {
      print('toggleOnlineStatus: Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
      _isOnline = !value;
      notifyListeners();
    }
  }

  Future<void> logout(BuildContext context) async {
    print('logout: Initiating logout');
    await LoginController.logout();
    _statusTimer?.cancel();
    print('logout: Navigating to LoginPage');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}