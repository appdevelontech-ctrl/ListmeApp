import '../models/withrawal_model.dart';
import '../services/api_services.dart';

import 'package:flutter/material.dart';

class WithdrawalController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<WithdrawalModel> withdrawals = [];
  String searchQuery = "";
  int currentPage = 1;
  int limit = 10;
  static int totalPagesStatic = 1; // Temporary workaround to store totalPages
  int get totalPages => totalPagesStatic; // Getter for totalPages
  bool isLoading = false;
  String? errorMessage;
  Future<void> fetchWithdrawals({
    String? userId,
    String? search,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final fetchedWithdrawals = await _apiService.fetchAllWithdrawals(
        page: currentPage,
        limit: limit,
        userId: userId,
        search: searchQuery.isEmpty ? search : searchQuery,
      );
      withdrawals = fetchedWithdrawals;
      isLoading = false;
      // Only set errorMessage for actual errors, not for empty data
      if (fetchedWithdrawals.isEmpty && errorMessage == null) {
        print('WithdrawalController: No withdrawals found');
      }
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      withdrawals = []; // Ensure withdrawals is empty on error
      notifyListeners();
      print('Error fetching withdrawals: $e');
    }
  }

  List<WithdrawalModel> get filteredWithdrawals {
    if (searchQuery.isEmpty) return withdrawals;
    return withdrawals.where((w) =>
    w.transactionId.toLowerCase().contains(searchQuery.toLowerCase()) ||
        w.username.toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  void setSearch(String query) {
    searchQuery = query;
    currentPage = 1;
    fetchWithdrawals();
  }

  void nextPage({String? userId}) {
    if (currentPage < totalPages) {
      currentPage++;
      fetchWithdrawals(userId: userId);
    }
  }

  void previousPage({String? userId}) {
    if (currentPage > 1) {
      currentPage--;
      fetchWithdrawals(userId: userId);
    }
  }

  void setLimit(int newLimit, {String? userId}) {
    limit = newLimit;
    currentPage = 1;
    fetchWithdrawals(userId: userId);
  }
  void reset() {
    print('WithdrawalController: Resetting state');
    withdrawals = [];
    searchQuery = "";
    currentPage = 1;
    totalPagesStatic = 1;
    isLoading = false;
    errorMessage = null;
    notifyListeners();
  }
}