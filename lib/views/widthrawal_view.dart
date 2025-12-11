import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import '../controllers/withdrawal_controller.dart';
import 'package:intl/intl.dart';
import '../services/api_services.dart';

class WithdrawalPage extends StatefulWidget {
  const WithdrawalPage({super.key, required this.userId});
  final String userId;

  @override
  State<WithdrawalPage> createState() => _WithdrawalPageState();
}

class _WithdrawalPageState extends State<WithdrawalPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  void showCustomDialog(BuildContext context, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Confirm Withdrawal",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("No"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onConfirm();
                        },
                        child: const Text("Yes"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    print('WithdrawalPage: initState called');
    _searchController.addListener(() {
      final controller = Provider.of<WithdrawalController>(context, listen: false);
      controller.setSearch(_searchController.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('WithdrawalPage: Triggering initial fetchWithdrawals');
      final controller = Provider.of<WithdrawalController>(context, listen: false);
      if (controller.withdrawals.isEmpty && !controller.isLoading) {
        _fetchWithdrawals();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  Future<void> _fetchWithdrawals() async {
    print('WithdrawalPage: _fetchWithdrawals called with userId: ${widget.userId}');
    final controller = Provider.of<WithdrawalController>(context, listen: false);
    controller.reset(); // Reset state before fetching
    try {
      EasyLoading.show(status: 'Fetching withdrawals...');
      await controller.fetchWithdrawals(userId: widget.userId);
      if (controller.errorMessage != null) {
        print('WithdrawalPage: Error from controller: ${controller.errorMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage!)),
        );
      } else {
        print('WithdrawalPage: Fetched ${controller.withdrawals.length} withdrawals');
      }
    } catch (e, stackTrace) {
      print('WithdrawalPage: Error in _fetchWithdrawals: $e');
      print('WithdrawalPage: StackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> _onRefresh() async {
    print('WithdrawalPage: _onRefresh called');
    await _fetchWithdrawals();
  }

  Future<void> _handleWithdrawal() async {
    print('WithdrawalPage: _handleWithdrawal called');
    final controller = Provider.of<WithdrawalController>(context, listen: false);
    try {
      EasyLoading.show(status: 'Processing withdrawal...');
      final result = await _apiService.requestWithdrawal(widget.userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Withdrawal request sent")),
      );
      await _fetchWithdrawals();
    } catch (e) {
      print('WithdrawalPage: Error in _handleWithdrawal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      EasyLoading.dismiss();
    }
  }
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<WithdrawalController>(context);
    print('WithdrawalPage: Building UI, isLoading: ${controller.isLoading}, filteredWithdrawals: ${controller.filteredWithdrawals.length}, totalPages: ${controller.totalPages}');

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Withdrawals"),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xff0f172a),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: controller.isLoading
                  ? null
                  : () {
                print('WithdrawalPage: Withdraw button pressed');
                showCustomDialog(
                  context,
                  "Are you sure you want to withdraw your points?",
                  _handleWithdrawal,
                );
              },
              icon: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 18),
              label: const Text("Withdraw", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DropdownButton<int>(
                    value: controller.limit,
                    items: const [
                      DropdownMenuItem(value: 10, child: Text("10")),
                      DropdownMenuItem(value: 20, child: Text("20")),
                      DropdownMenuItem(value: 50, child: Text("50")),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        print('WithdrawalPage: Changing limit to $value');
                        controller.setLimit(value, userId: widget.userId);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search by Transaction ID or Username",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            print('WithdrawalPage: Clearing search');
                            _searchController.clear();
                            controller.setSearch('');
                          },
                        )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: controller.isLoading
                        ? null
                        : () {
                      print('WithdrawalPage: Search button pressed');
                      _fetchWithdrawals();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0f172a),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Search"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: MediaQuery.of(context).size.height - kToolbarHeight - 200,
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : controller.errorMessage != null
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        controller.errorMessage!,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          print('WithdrawalPage: Retry button pressed');
                          _fetchWithdrawals();
                        },
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
                    : controller.filteredWithdrawals.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _searchController.text.isNotEmpty
                          ? "No withdrawals found for '${_searchController.text}'"
                          : "No withdrawal records available",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.filteredWithdrawals.length,
                  itemBuilder: (context, index) {
                    final w = controller.filteredWithdrawals[index];
                    print('WithdrawalPage: Rendering withdrawal $index: ${w.transactionId}, ${w.amount}, ${w.status}');
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Txn: ${w.transactionId}",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(w.createdAt),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            const Divider(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₹${w.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: w.amount <= 0 ? Colors.red : Colors.green,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: w.status == "Completed"
                                        ? Colors.green.shade100
                                        : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    w.status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: w.status == "Completed" ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "User: ${w.username.isEmpty ? 'Unknown User' : w.username}",
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 16),
                      onPressed: controller.currentPage > 1
                          ? () {
                        print('WithdrawalPage: Previous page button pressed');
                        controller.previousPage(userId: widget.userId);
                      }
                          : null,
                    ),
                    Text("Page ${controller.currentPage} of ${controller.totalPages}"),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: controller.currentPage < controller.totalPages
                          ? () {
                        print('WithdrawalPage: Next page button pressed');
                        controller.nextPage(userId: widget.userId);
                      }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}