// controllers/profile_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/auth/user_model.dart';
import '../services/api_services.dart';

class ProfileController extends ChangeNotifier {
  User? user;
  String? _errorMessage;
  bool _isLoading = false;

  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  final ApiService _apiService = ApiService();

  Future<void> fetchProfile(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      user = await _apiService.fetchUserData(userId);
      print('fetchProfile: Success, fetched user: ${user!.username}');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('fetchProfile: Error: $e');
      _errorMessage = 'Failed to fetch profile: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> updateProfile({
    required String username,
    required String phone,
    required String email,
    String? password,
    String? confirmPassword,
    required String pincode,
    required String gender, // Added gender
    required String dob,
    required String address,
    required List<String> coverage,
    required List<String> department,
    required String state,
    required String statename,
    required String city,
    File? profileImage,
    bool removeProfileImage = false,
    File? doc1,
    File? doc2,
    File? doc3,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _apiService.updateProfile(
        username: username,
        phone: phone,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        pincode: pincode,
        gender: gender, // Pass gender instead of status
        dob: dob,
        address: address,
        coverage: coverage,
        department: department,
        state: state,
        statename: statename,
        city: city,
        profileImage: profileImage,
        removeProfileImage: removeProfileImage,
        doc1: doc1,
        doc2: doc2,
        doc3: doc3,
      );
      if (updatedUser != null) {
        user = updatedUser;
        print('updateProfile: Success, updated user: ${user!.username}');
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('updateProfile: Error: $e');
      _errorMessage = 'Failed to update profile: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
}