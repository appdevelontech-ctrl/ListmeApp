import 'package:flutter/foundation.dart';
import '../models/WalletModel.dart';

import '../services/api_services.dart';

class WalletController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  WalletModel? wallet;
  String searchQuery = "";
  int currentPage = 1;
  int limit = 10;
  int totalPages = 1;
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchTransactions({String? userId}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final fetchedWallet = await _apiService.fetchAllTransactions(
        page: currentPage,
        limit: limit,
        userId: userId,
        search: searchQuery.isEmpty ? null : searchQuery,
      );
      wallet = fetchedWallet;
      totalPages = fetchedWallet.transactions.isNotEmpty
          ? 10
          : 1; // From API response
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      print('Error fetching transactions: $e');
    }
  }

  List<WalletTransaction> get filteredTransactions {
    if (wallet == null || searchQuery.isEmpty)
      return wallet?.transactions ?? [];
    return wallet!.transactions
        .where(
          (tx) =>
              tx.transactionId.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              tx.note.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  double get balance => wallet?.balance ?? 0.0;

  void setSearch(String query) {
    searchQuery = query;
    currentPage = 1;
    fetchTransactions();
  }

  void nextPage({String? userId}) {
    if (currentPage < totalPages) {
      currentPage++;
      fetchTransactions(userId: userId);
    }
  }

  void previousPage({String? userId}) {
    if (currentPage > 1) {
      currentPage--;
      fetchTransactions(userId: userId);
    }
  }

  void setLimit(int newLimit, {String? userId}) {
    limit = newLimit;
    currentPage = 1;
    fetchTransactions(userId: userId);
  }

  void addPoints() {
    // Implement add points logic (e.g., API call to add credits)
    notifyListeners();
  }

  void allPayments() {
    // Implement all payments logic
    notifyListeners();
  }
}
