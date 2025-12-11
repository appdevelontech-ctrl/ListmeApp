// controllers/auth/login_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/auth/user_model.dart';
import '../../services/api_services.dart';

class LoginController extends ChangeNotifier {
  User? user;
  final ApiService _apiService = ApiService();
  String? _errorMessage;
  bool _isLoading = false;

  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  void _initUserIfNull() {
    if (user == null) {
      user = User(
        id: '',
        username: '',
        phone: '',
        email: '',
        password: '',
        type: 0,
        empType: 0,
        state: '',
        statename: '',
        city: '',
        address: '',
        verified: 0,
        pincode: '',
        dob: '',
        about: '',
        department: [],
        doc1: '',
        doc2: '',
        doc3: '',
        profile: '',
        pHealthHistory: '',
        cHealthStatus: '',
        coverage: [],
        gallery: [],
        images: [],
        mId: [],
        dynamicUsers: [],
        wallet: 0,
        longitude: '',
        latitude: '',
        calls: [],
        status: '',
        orders: [],
        createdAt: '',
        updatedAt: '',
        v: 0, cHealthHistory: '',
      );
    }
  }

  void setEmail(String email) {
    _initUserIfNull();
    user = user!.copyWith(email: email);
    notifyListeners();
  }

  void setPassword(String password) {
    _initUserIfNull();
    user = user!.copyWith(password: password);
    notifyListeners();
  }

  bool validate() {
    if (user == null || user!.email.isEmpty || user!.password.isEmpty) {
      _errorMessage = 'Please enter both email and password';
      notifyListeners();
      return false;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(user!.email)) {
      _errorMessage = 'Please enter a valid email address';
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<bool> login(BuildContext context) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    if (!validate()) {
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      // Step 1: Call login API
      final loginResponse = await _apiService.loginUser(
          user!.email, user!.password);
      if (loginResponse['statusCode'] == 200 && loginResponse['data'] != null) {
        final userData = loginResponse['data'];
        final userId = userData['_id'];

        // Step 2: Authenticate with auth-user API
        final authUser = await _apiService.fetchUserData(userId);
        user = authUser;

        // Step 3: Save user data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('employeeId', user!.id);
        await prefs.setString('userData', json.encode(user!.toJson()));
        await prefs.setBool('isLoggedIn', true);

        print('✅ Login success, userId: ${user!.id}, username: ${user!
            .username}');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage =
            loginResponse['message'] ?? 'Login failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      String errorMsg = 'Something went wrong. Please try again.';

      try {
        // अगर response JSON है, decode करके message निकालो
        final decoded = json.decode(e.toString());
        if (decoded is Map && decoded['message'] != null) {
          errorMsg = decoded['message'];
        }
      } catch (_) {
        // fallback: अगर e.toString() में known keywords हैं
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('password')) {
          errorMsg = 'Invalid email or password';
        } else if (errStr.contains('email')) {
          errorMsg = 'Email is not registered';
        } else if (errStr.contains('timeout')) {
          errorMsg = 'Request timed out. Please try again.';
        }
      }

      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
    static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  static Future<User?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('userData');
    if (userData != null) {
      return User.fromJson(json.decode(userData));
    }
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final fcmToken = prefs.getString('fcmToken');
    print('logout: Current FCM Token before clearing: $fcmToken');
    await prefs.clear();
    print('logout: Cleared SharedPreferences');
    if (fcmToken != null) {
      await prefs.setString('fcmToken', fcmToken);
      print('logout: Restored FCM Token -> $fcmToken');
    }
  }
}