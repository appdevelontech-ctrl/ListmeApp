import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/wallet_controller.dart';
import '../controllers/paymentcontroller.dart';
import '../models/WalletModel.dart';

class WalletView extends StatefulWidget {
  const WalletView({super.key, this.userId});

  final String? userId;

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  late Razorpay _razorpay;
  int? selectedAmount;
  final TextEditingController _customAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _customAmountController.addListener(_updateSelectedAmount);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final walletController = Provider.of<WalletController>(context, listen: false);
      if (walletController.wallet == null && !walletController.isLoading) {
        final userId = widget.userId ?? await getEmployeeId();
        if (userId != null) {
          await _fetchTransactions(userId);
        } else {
          EasyLoading.showError('User ID is missing! Please log in.');
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    });
  }

  void _updateSelectedAmount() {
    final customValue = int.tryParse(_customAmountController.text.replaceAll(',', ''));
    if (customValue != null && customValue > 0) {
      setState(() {
        selectedAmount = customValue;
      });
    }
  }

  Future<String?> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('employeeId');
  }

  Future<void> _fetchTransactions(String userId) async {
    final walletController = Provider.of<WalletController>(context, listen: false);
    try {
      EasyLoading.show(status: 'Fetching transactions...');
      await walletController.fetchTransactions(userId: userId);
    } catch (e) {
      EasyLoading.showError('Error fetching transactions: $e');
    } finally {
      EasyLoading.dismiss();
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _customAmountController.dispose();
    super.dispose();
  }

  void _showAmountSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Select or Enter Amount to Add Points',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _customAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter Custom Amount (₹)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixText: '₹',
                  ),
                  onChanged: (value) {
                    _updateSelectedAmount();
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Or Select a Predefined Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildAmountButton(2000),
                    _buildAmountButton(3000),
                    _buildAmountButton(4000),
                    _buildAmountButton(5000),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: selectedAmount == null || selectedAmount! <= 0
                      ? null
                      : () {
                    Navigator.of(context).pop();
                    _initiatePayment();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmountButton(int amount) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedAmount = amount;
          _customAmountController.text = amount.toString();
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: selectedAmount == amount ? Colors.black : Colors.grey[300],
        foregroundColor: selectedAmount == amount ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text('₹$amount'),
    );
  }

  void _initiatePayment() async {
    if (selectedAmount == null || selectedAmount! <= 0) {
      EasyLoading.showError('Please select or enter a valid amount!');
      return;
    }

    final paymentController = Provider.of<PaymentController>(context, listen: false);
    final walletController = Provider.of<WalletController>(context, listen: false);
    final userId = widget.userId ?? await getEmployeeId();

    if (userId == null) {
      EasyLoading.showError('User ID is missing! Please log in.');
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      EasyLoading.show(status: 'Initiating payment...');
      await paymentController.initiatePayment(
        userId: userId,
        amount: selectedAmount!,
        note: 'Add Points to Wallet',
        local: 0,
      );

      // Show toast for success or error
      if (paymentController.isPaymentSuccessful) {
        EasyLoading.showSuccess(
          'Payment Successful!',
          duration: const Duration(seconds: 3),
        );
        // Refresh transactions after successful payment
        await _fetchTransactions(userId);
      } else if (paymentController.errorMessage != null) {
        EasyLoading.showError(
          paymentController.errorMessage!,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      EasyLoading.showError('Error initiating payment: $e');
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> _refreshTransactions() async {
    final _ = Provider.of<WalletController>(context, listen: false);
    final userId = widget.userId ?? await getEmployeeId();
    if (userId != null) {
      await _fetchTransactions(userId);
    } else {
      EasyLoading.showError('User ID is missing! Please log in.');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletController = Provider.of<WalletController>(context);
    final paymentController = Provider.of<PaymentController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Wallet transaction"),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [


          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: RefreshIndicator(
              onRefresh: _refreshTransactions,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: walletController.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : walletController.filteredTransactions.isEmpty
                        ? const Center(
                      child: Text(
                        "No Transactions Found",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                        : ListView.builder(
                      itemCount: walletController.filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = walletController.filteredTransactions[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Txn: ${tx.transactionId}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMM dd, yyyy').format(tx.createdAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        tx.note,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      tx.amount < 0
                                          ? "Debit ${tx.amount.toStringAsFixed(2)}"
                                          : "Credit +${tx.amount.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: tx.amount < 0 ? Colors.red : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tx.type == 0 ? "Credit" : "Debit",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: tx.type == 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (paymentController.isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}