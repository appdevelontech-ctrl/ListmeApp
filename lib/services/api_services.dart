import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/withdrawal_controller.dart';
import '../models/WalletModel.dart';
import '../models/auth/user_model.dart';
import '../models/order_model.dart' hide User;
import '../models/withrawal_model.dart';
import 'package:logger/logger.dart';

class ApiService {
  static const String baseUrl = "https://listmein.onrender.com";
  static const String analyticsUrl = '$baseUrl/get-all-analytics';
  Future<String?> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('employeeId');
  }

  final Logger _logger = Logger();

  /// Fetches analytics data from the server.
  /// Returns a Map containing the analytics data or throws an exception on failure.
  Future<Map<String, dynamic>> fetchAnalytics() async {
    try {
      final response = await http.get(Uri.parse(analyticsUrl));
      _logger.d('API Response: Status ${response.statusCode}, Body: ${response.body}');

      // Check for successful response
      if (response.statusCode == 200) {
        // Parse JSON response
        final data = jsonDecode(response.body);
        _logger.d('Parsed Data: $data');

        // Validate response format
        if (data is List && data.isNotEmpty && data[0]['data'] != null) {
          return data[0]['data'] as Map<String, dynamic>;
        } else if (data is Map<String, dynamic> && data['data'] != null) {
          // Handle case where response is a single object with a data field
          return data['data'] as Map<String, dynamic>;
        } else {
          throw Exception('Invalid response format: Expected a non-empty list or object with a "data" field, got: ${response.body}');
        }
      } else {
        throw Exception('Failed to load analytics: HTTP ${response.statusCode} - ${response.body}');
      }
    } on http.ClientException catch (e) {
      _logger.e('Network error: $e');
      throw Exception('Network error: Unable to connect to the server. Please check your internet connection.');
    } on FormatException catch (e) {
      _logger.e('JSON parsing error: $e');
      throw Exception('JSON parsing error: Invalid data format received from the server.');
    } catch (e) {
      _logger.e('Unexpected error: $e');
      throw Exception('Error fetching analytics: $e');
    }
  }

  Future<List<Order>> fetchAllOrders({int page = 1, int limit = 10}) async {
    final employeeId = await getEmployeeId();
    if (employeeId == null) throw Exception("User not logged in");
    final url = "$baseUrl/admin/all-order?page=$page&limit=$limit&employeeId=$employeeId&job=All";
    print('fetchAllOrders: Fetching all orders from $url');
    return fetchOrders(url);
  }

  Future<List<Order>> fetchPendingOrders({int page = 1, int limit = 10}) async {
    final employeeId = await getEmployeeId();
    if (employeeId == null) throw Exception("User not logged in");
    final url = "$baseUrl/admin/all-order?page=$page&limit=$limit&employeeId=$employeeId&status=1,2,3,4";
    print('fetchPendingOrders: Fetching pending orders from $url');
    return fetchOrders(url);
  }

  Future<List<Order>> fetchCompletedOrders({int page = 1, int limit = 10}) async {
    final employeeId = await getEmployeeId();
    if (employeeId == null) throw Exception("User not logged in");
    final url = "$baseUrl/admin/all-order?page=$page&limit=$limit&employeeId=$employeeId&status=7";
    print('fetchCompletedOrders: Fetching completed orders from $url');
    return fetchOrders(url);
  }

  Future<List<Order>> fetchOrders(String url) async {
    print('_fetchOrders: Fetching orders from $url');
    try {
      final response = await http.get(Uri.parse(url));
      _logger.d('_fetchOrders: Status Code: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List ordersJson = jsonData['Order'] ?? [];
          _logger.d('_fetchOrders: Success, Parsed ${ordersJson.length} orders');
          return ordersJson.map((e) => Order.fromJson(e)).toList();
        } else {
          final error = jsonData['message'] ?? 'No orders found';
          _logger.w('_fetchOrders: Error response: $error');
          throw Exception(error);
        }
      } else {
        final jsonData = json.decode(response.body);
        final error = jsonData['message'] ?? 'Error fetching orders: ${response.statusCode}';
        _logger.e('_fetchOrders: HTTP Error: $error');
        throw Exception(error);
      }
    } on http.ClientException catch (e) {
      _logger.e('_fetchOrders: Network error: $e');
      throw Exception('Network error: Unable to connect to the server. Please check your internet connection.');
    } on FormatException catch (e) {
      _logger.e('_fetchOrders: JSON parsing error: $e');
      throw Exception('JSON parsing error: Invalid data format received from the server.');
    } catch (e) {
      _logger.e('_fetchOrders: Unexpected error: $e');
      throw Exception('Error fetching orders: $e');
    }
  }

  Future<WalletModel> fetchAllTransactions({
    int page = 1,
    int limit = 10,
    String? userId,
    String? search,
  }) async {
    final employeeId = await getEmployeeId();
    if (employeeId == null && userId == null) {
      throw Exception("User not logged in and no userId provided");
    }

    final effectiveUserId = userId ?? employeeId;
    final url = "$baseUrl/all-transaction?page=$page&limit=$limit${search != null ? '&search=$search' : ''}&userId=$effectiveUserId";
    print('fetchAllTransactions: Fetching transactions for userId: $effectiveUserId');
    final response = await http.get(Uri.parse(url));
    print('fetchAllTransactions: Status Code: ${response.statusCode}, Body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      print('fetchAllTransactions: Success, Data: ${json.encode(jsonData)}');
      return WalletModel.fromJson(jsonData);
    } else {
      try {
        final jsonData = json.decode(response.body);
        throw Exception(jsonData['message'] ?? 'Error fetching transactions: ${response.statusCode}');
      } catch (e) {
        throw Exception('Error fetching transactions: ${response.statusCode}, Response: ${response.body}');
      }
    }
  }

  Future<List<WithdrawalModel>> fetchAllWithdrawals({
    int page = 1,
    int limit = 10,
    String? userId,
    String? search,
  }) async {
    final employeeId = await getEmployeeId();
    final effectiveUserId = userId ?? employeeId;
    if (effectiveUserId == null) {
      throw Exception("User not logged in and no userId provided");
    }

    // Build the URL with proper query parameters
    final queryParameters = {
      'page': page.toString(),
      'limit': limit.toString(),
      'userId': effectiveUserId,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final url = Uri.parse('$baseUrl/admin/all-Withdrawal').replace(queryParameters: queryParameters);
    print('ApiService: Fetching withdrawals from URL: $url');

    try {
      final response = await http.get(url);
      print('ApiService: fetchAllWithdrawals Status Code: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List withdrawalsJson = jsonData['myData'] ?? [];
          final totalPages = jsonData['totalPages'] ?? 1;
          print('ApiService: Parsed ${withdrawalsJson.length} withdrawals, Total pages: $totalPages');

          // Store totalPages in a static variable or return it separately if needed
          WithdrawalController.totalPagesStatic = totalPages;
          return withdrawalsJson.map((e) => WithdrawalModel.fromJson(e)).toList();
        } else {
          final error = jsonData['message'] ?? 'No withdrawal records found';
          print('ApiService: Error response: $error');
          // Instead of throwing, return an empty list to indicate no data
          WithdrawalController.totalPagesStatic = 1;
          return [];
        }
      } else {
        final jsonData = json.decode(response.body);
        final error = jsonData['message'] ?? 'Error fetching withdrawals: ${response.statusCode}';
        print('ApiService: Error response: $error');
        throw Exception(error);
      }
    } catch (e) {
      print('ApiService: Exception during fetchAllWithdrawals: $e');
      throw Exception('Error fetching withdrawals: $e');
    }
  }

  Future<Order> fetchOrderById(String orderId) async {
    final employeeId = await getEmployeeId();
    if (employeeId == null) throw Exception("User not logged in");
    final url = "$baseUrl/user-orders-view/$orderId";
    print('fetchOrderById: Fetching order: $orderId');
    final response = await http.get(Uri.parse(url));
    print('fetchOrderById: Status Code: ${response.statusCode}, Body: ${response.body}');
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      print('fetchOrderById: Success, Order Data: ${json.encode(jsonData["userOrder"])}');
      return Order.fromJson(jsonData["userOrder"]);
    } else {
      try {
        final jsonData = json.decode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to fetch order $orderId: ${response.statusCode}');
      } catch (e) {
        throw Exception('Failed to fetch order $orderId: ${response.statusCode}, Response: ${response.body}');
      }
    }
  }
  Future<bool> acceptOrder(String orderId) async {
    final employeeId = await getEmployeeId();
    if (employeeId == null) throw Exception("User not logged in");

    final url = '$baseUrl/admin/employee/accept-job';
    print('acceptOrder: Accepting order $orderId for employeeId: $employeeId');
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"OrderId": orderId, "UserId": employeeId}),
    );
    print('acceptOrder: Status Code: ${response.statusCode}, Body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData["success"] == true) {
        print('acceptOrder: Success for order $orderId');
        return true;
      } else {
        throw Exception(jsonData["message"] ?? "Failed to accept order");
      }
    } else {
      try {
        final jsonData = json.decode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to accept order: ${response.statusCode}');
      } catch (e) {
        throw Exception('Failed to accept order: ${response.statusCode}, Response: ${response.body}');
      }
    }
  }
  Future<bool> cancelOrder(String orderId, String comment) async {
    final url = "$baseUrl/cancel-order/$orderId";
    print('cancelOrder: Cancelling order $orderId with comment: $comment');
    final response = await http.put(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"comment": comment}),
    );
    print('cancelOrder: Status Code: ${response.statusCode}, Body: ${response.body}');
    if (response.statusCode == 200) {
      print('cancelOrder: Success for order $orderId');
      return true;
    } else {
      try {
        final jsonData = json.decode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to cancel order: ${response.statusCode}');
      } catch (e) {
        throw Exception('Failed to cancel order: ${response.statusCode}, Response: ${response.body}');
      }
    }
  }
  Future<List<Order>> fetchMyJobs({
    required int page,
    int limit = 10,
  }) async {
    final employeeId = await getEmployeeId();
    if (employeeId == null) throw Exception("User not logged in");

    final url = '$baseUrl/admin/all-order?page=$page&type=&limit=$limit&search=&status=&jobId=$employeeId';
    print('📡 fetchMyJobs → $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      print('📦 Response (${response.statusCode}): ${response.body}');

      final jsonData = json.decode(response.body);

      // ✅ Handle success
      if (response.statusCode == 200 && jsonData['success'] == true) {
        final ordersData = (jsonData['Order'] ?? []) as List<dynamic>;
        return ordersData
            .map((orderJson) => Order.fromJson(orderJson as Map<String, dynamic>))
            .toList();
      }

      // ❌ Handle failure with backend message
      final message = jsonData['message'] ??
          'Failed to fetch jobs (code: ${response.statusCode})';
      throw Exception(message);
    } catch (e) {
      print('❌ fetchMyJobs error: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // New method to update order status
  Future<bool> updateOrderStatus(String orderId, int newStatus) async {
    final employeeId = await getEmployeeId();
    if (employeeId == null) throw Exception("User not logged in");

    final url = "$baseUrl/admin/update-order/$orderId";
    print('updateOrderStatus: Updating order $orderId to status $newStatus for employeeId: $employeeId');
    final response = await http.put(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"status": newStatus.toString()}), // Convert to String as per API
    );
    print('updateOrderStatus: Status Code: ${response.statusCode}, Body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData["success"] == true) {
        print('updateOrderStatus: Success for order $orderId');
        return true;
      } else {
        throw Exception(jsonData["message"] ?? "Failed to update order status");
      }
    } else {
      try {
        final jsonData = json.decode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to update order status: ${response.statusCode}');
      } catch (e) {
        throw Exception('Failed to update order status: ${response.statusCode}, Response: ${response.body}');
      }
    }
  }


  Future<bool> updateFullOrder(String orderId, Map<String, dynamic> orderData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/update-full-order/$orderId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 200) {
        print("Response is : ${response.body.toString()}");
        return true;
      } else {
        throw Exception('Failed to update order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating order: $e');
    }
  }



  Future<Map<String, dynamic>> fetchZonesAndCategories() async {
    final url = "$baseUrl/get-all-zones-category";
    print('fetchZonesAndCategories: Fetching zones and categories');
    final response = await http.get(Uri.parse(url));
    print('fetchZonesAndCategories: Status Code: ${response.statusCode}, Body: ${response.body}');
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      print('fetchZonesAndCategories: Success, Data: ${json.encode(jsonData)}');
      return jsonData;
    } else {
      try {
        final jsonData = json.decode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to fetch zones and categories: ${response.statusCode}');
      } catch (e) {
        throw Exception('Failed to fetch zones and categories: ${response.statusCode}, Response: ${response.body}');
      }
    }
  }

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final fcmToken = prefs.getString('fcmToken') ?? '';
    _logger.d("FCM Token is $fcmToken");

    final url = "$baseUrl/user-login-all";
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "email": email,
        "password": password,
        "fcm": fcmToken,
      }),
    );


    _logger.d("Response is: ${response.body}");
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData["success"] == true) {
        final userData = jsonData["admin"] ?? jsonData["existingUser"];
        if (userData != null) {
          return {
            'statusCode': response.statusCode,
            'body': response.body,
            'data': userData,
          };
        } else {
          throw Exception("No user data returned");
        }
      } else {
        throw Exception(jsonData["message"] ?? "Invalid email or password");
      }
    } else {
      throw Exception('Failed: ${response.statusCode}, ${response.body}');
    }
  }

  Future<User> fetchUserData(String employeeId) async {
    final url = "$baseUrl/auth-user";
    _logger.d('fetchUserData: Fetching user data for employeeId: $employeeId');
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"id": employeeId}),
    );
    _logger.d('fetchUserData: Status Code: ${response.statusCode}, Body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['success'] == true && jsonData['existingUser'] != null) {
        return User.fromJson(jsonData['existingUser']);
      } else {
        throw Exception(jsonData['message'] ?? 'User not found');
      }
    } else {
      try {
        final jsonData = json.decode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to fetch user data');
      } catch (e) {
        throw Exception('Failed to fetch user data: ${response.statusCode}, Response: ${response.body}');
      }
    }
  }
  Future<User?> updateProfile({
    required String username,
    required String phone,
    required String email,
    String? password,
    String? confirmPassword,
    required String pincode,
    required String gender,
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
    final employeeId = await getEmployeeId();
    if (employeeId == null) throw Exception("User not logged in");
    final url = "$baseUrl/update-user-vendor/$employeeId";
    _logger.d('updateProfile: Updating profile for employeeId: $employeeId');
    var request = http.MultipartRequest('PUT', Uri.parse(url));

    // Add text fields
    request.fields['username'] = username;
    request.fields['phone'] = phone;
    request.fields['email'] = email;
    if (password != null && password.isNotEmpty) {
      request.fields['password'] = password;
      request.fields['confirm_password'] = confirmPassword ?? password; // Ensure confirmPassword is sent
    }
    request.fields['pincode'] = pincode;
    request.fields['gender'] = gender;
    request.fields['dob'] = dob;
    request.fields['address'] = address;
    request.fields['state'] = state;
    request.fields['statename'] = statename;
    request.fields['city'] = city;
    request.fields['removeProfileImage'] = removeProfileImage.toString();

    // Add coverage and department as arrays
    for (var cov in coverage) {
      request.fields['coverage[]'] = cov;
    }
    for (var dep in department) {
      request.fields['department[]'] = dep;
    }

    // Add files
    if (profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath('profile', profileImage.path));
    }
    if (doc1 != null) {
      request.files.add(await http.MultipartFile.fromPath('Doc1', doc1.path));
    }
    if (doc2 != null) {
      request.files.add(await http.MultipartFile.fromPath('Doc2', doc2.path));
    }
    if (doc3 != null) {
      request.files.add(await http.MultipartFile.fromPath('Doc3', doc3.path));
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    _logger.d('updateProfile: Status Code: ${response.statusCode}, Body: $responseBody');

    if (response.statusCode == 200) {
      final jsonData = json.decode(responseBody);
      if (jsonData['success'] == true) {
        final userData = jsonData['user'];
        if (userData == null) {
          _logger.d('updateProfile: Success, but no user data returned');
          return null;
        }
        _logger.d('updateProfile: Success, User Data: ${json.encode(userData)}');
        return User.fromJson(userData);
      } else {
        throw Exception(jsonData['message'] ?? 'Failed to update profile');
      }
    } else {
      try {
        final jsonData = json.decode(responseBody);
        throw Exception(jsonData['message'] ?? 'Failed to update profile: ${response.statusCode}');
      } catch (e) {
        throw Exception('Failed to update profile: ${response.statusCode}, Response: $responseBody');
      }
    }
  }
  Future<User> updateUserMeta(String userId, {required String latitude, required String longitude, required int online}) async {
    final url = "$baseUrl/admin/update-user-meta/$userId";
    _logger.d('updateUserMeta: Updating user meta for userId: $userId');
    final response = await http.put(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "latitude": latitude,
        "longitude": longitude,
        "status": "$online",
      }),
    );
    _logger.d('updateUserMeta: Status Code: ${response.statusCode}, Body: ${response.body}');
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['success'] == true && jsonData['user'] != null) {
        _logger.d('updateUserMeta: Success, User Data: ${json.encode(jsonData['user'])}');
        return User.fromJson(jsonData['user']);
      } else {
        throw Exception(jsonData['message'] ?? 'Failed to update user meta');
      }
    } else {
      try {
        final jsonData = json.decode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to update user meta: ${response.statusCode}');
      } catch (e) {
        throw Exception('Failed to update user meta: ${response.statusCode}, Response: ${response.body}');
      }
    }
  }

  static Future<Map<String, dynamic>> initiateRazorpayPayment({
    required String userId,
    required String amount,
    required String note,
    required int local,
  }) async {
    final url = Uri.parse('$baseUrl/checkout-wallet');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'amount': '${amount}', // API expects amount as String
        'note': note,
        'Local': local.toString(), // API expects Local as String
      }),
    );

    print('Request URL: $url'); // Debug
    print('Request Body: ${json.encode({
      'userId': userId,
      'amount': '${amount}',
      'note': note,
      'Local': local.toString(),
    })}'); // Debug
    print('Response Status: ${response.statusCode}'); // Debug
    print('Response Body: ${response.body}'); // Debug

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse is Map<String, dynamic>) {
        print('Parsed JSON Response: $jsonResponse'); // Debug
        return jsonResponse;
      } else {
        throw Exception('Invalid API response format: Expected a Map');
      }
    } else {
      throw Exception('Failed to initiate payment: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final url = Uri.parse('$baseUrl/wallet-payment-verification');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      }),
    );

    print("Verify API Status: ${response.statusCode}");
    print("Verify API Body: ${response.body}");

    if (response.statusCode == 200) {
      // ✅ Payment verified successfully
      return {
        "success": true,
        "message": "Payment verified successfully."
      };
    } else if (response.statusCode == 302) {
      // ✅ Special case: 302 = Payment already verified or redirect success
      Fluttertoast.showToast(
        msg: "✅ Payment Successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      return {
        "success": true,
        "message": "Payment successfully (302 redirect)."
      };
    } else {
      // ❌ Failure case
      return {
        "success": false,
        "message": "Payment verification failed: ${response.body}"
      };
    }
  }

  Future<Map<String, dynamic>> requestWithdrawal(String? userId) async {
    final url = Uri.parse("$baseUrl/admin/withdrawal/$userId");
    print('requestWithdrawal: Sending withdrawal request for userId: $userId');

    try {
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print('requestWithdrawal: Status Code: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return {
            "success": true,
            "message": jsonData['message'] ?? "Withdrawal successful",
            "data": jsonData,
          };
        } else {
          return {
            "success": false,
            "message": jsonData['message'] ?? "Withdrawal failed",
            "data": jsonData,
          };
        }
      } else {
        final jsonData = json.decode(response.body);
        return {
          "success": false,
          "message": jsonData['message'] ?? "Failed to request withdrawal: ${response.statusCode}",
          "data": jsonData,
        };
      }
    } catch (e) {
      print('requestWithdrawal: Exception - $e');
      return {
        "success": false,
        "message": "Something went wrong: $e",
        "data": null,
      };
    }
  }
}