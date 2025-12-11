import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment.dart';
import '../services/api_services.dart';

class PaymentController extends ChangeNotifier {
  List<Payment> payments = [];
  int currentPage = 1;
  int totalPages = 1;
  int limit = 10;
  String search = '';
  bool isLoading = false;
  String? errorMessage;
  bool isPaymentSuccessful = false;
  final Razorpay _razorpay = Razorpay();
  static const String weburl = 'https://backend-olxs.onrender.com/';

  PaymentController() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<String?> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('employeeId');
  }

  Future<void> initiatePayment({
    String? userId,
    required int amount,
    required String note,
    required int local,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      isPaymentSuccessful = false;
      notifyListeners();

      final effectiveUserId = userId ?? await getEmployeeId();
      if (effectiveUserId == null) {
        throw Exception('User ID is missing and not found in SharedPreferences');
      }

      // Workaround: Adjust amount to compensate for server multiplying by 10 instead of 100
      final adjustedAmount = amount ~/ 10;
      print('Initiating payment for userId: $effectiveUserId, amount: ₹$amount, adjustedAmount: $adjustedAmount');

      final response = await ApiService.initiateRazorpayPayment(
        userId: effectiveUserId,
        amount: "$adjustedAmount",
        note: note,
        local: local,
      );

      print('Initiate Payment Response: $response');

      if (response['success'] == true) {
        final paymentData = response['Payment'] as Map<String, dynamic>?;
        final keyId = response['keyId'] as String?;
        final metaLogo = response['meta_logo'] as String?;

        if (paymentData == null || keyId == null) {
          throw Exception('Invalid payment data or keyId');
        }

        final payment = Payment.fromJson(paymentData);
        print('Parsed Payment: totalAmount=${payment.totalAmount}, razorpayOrderId=${payment.razorpayOrderId}');

        final expectedAmount = amount * 100; // in paise
        if (payment.totalAmount != expectedAmount) {
          print('Warning: Server returned totalAmount=${payment.totalAmount}, expected=$expectedAmount.');
        }

        final options = {
          'key': keyId,
          'amount': payment.totalAmount ?? 0,
          'order_id': payment.razorpayOrderId,
          'name': 'The Helply',
          'description': payment.note,
          'prefill': {'contact': '', 'email': ''},
          'image': metaLogo,
          // ❌ callback_url Removed
        };

        print('Razorpay Options: $options');
        _razorpay.open(options);

        payments.insert(0, payment);
        notifyListeners();
      } else {
        throw Exception('Payment initiation failed: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e, stackTrace) {
      errorMessage = 'Error initiating payment: $e';
      print('Error in initiatePayment: $e\nStackTrace: $stackTrace');
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      print('Payment Success Received: orderId=${response.orderId}, paymentId=${response.paymentId}, signature=${response.signature}');

      final verifyResponse = await ApiService.verifyRazorpayPayment(
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
      );

      if (verifyResponse['success'] == true) {
        errorMessage = "✅ Payment Successful!";
        isPaymentSuccessful = true;

        // Optional: Toast show here only if not already shown
        if (!(verifyResponse['message'].toString().contains("302"))) {
          Fluttertoast.showToast(
            msg: "✅ Payment Successfully",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }

        // Clear message after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          errorMessage = null;
          notifyListeners();
        });
      } else {
        print("❌ Payment Verification Failed: ${verifyResponse['message']}");
        Fluttertoast.showToast(
          msg: "❌ Payment Verification Failed",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }

      notifyListeners();
    } catch (e, stackTrace) {
      errorMessage = 'Error verifying payment: $e';
      isPaymentSuccessful = false;
      print('Error in _handlePaymentSuccess: $e\nStackTrace: $stackTrace');
      notifyListeners();
    }
  }
  void _handlePaymentError(PaymentFailureResponse response) {
    errorMessage = 'Payment failed: ${response.message ?? 'Unknown error'}';
    isPaymentSuccessful = false;
    notifyListeners();
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    errorMessage = 'External wallet selected: ${response.walletName}';
    isPaymentSuccessful = false;
    notifyListeners();
  }



  void setSearch(String value) {
    search = value;
    currentPage = 1;
    notifyListeners();
  }





  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}
