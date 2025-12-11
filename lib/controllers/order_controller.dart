import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/api_services.dart';

class OrderController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Order> _allOrders = [];
  List<Order> _pendingOrders = [];
  List<Order> _completedOrders = [];
  List<Order> _myJobs = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _allOrdersPage = 1;
  int _pendingOrdersPage = 1;
  int _completedOrdersPage = 1;
  int _myJobsPage = 1;
  bool _hasMoreAllOrders = true;
  bool _hasMorePendingOrders = true;
  bool _hasMoreCompletedOrders = true;
  bool _hasMoreMyJobs = true;

  List<Order> get allOrders => _allOrders;
  List<Order> get pendingOrders => _pendingOrders;
  List<Order> get completedOrders => _completedOrders;
  List<Order> get myJobs => _myJobs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMoreAllOrders => _hasMoreAllOrders;
  bool get hasMorePendingOrders => _hasMorePendingOrders;
  bool get hasMoreCompletedOrders => _hasMoreCompletedOrders;
  bool get hasMoreMyJobs => _hasMoreMyJobs;

  List<Order> _filteredPendingOrders = [];
  List<Order> get filteredPendingOrders =>
      _filteredPendingOrders.isEmpty ? _pendingOrders : _filteredPendingOrders;

  void filterPendingOrders(String query) {
    if (query.isEmpty) {
      _filteredPendingOrders = [];
    } else {
      _filteredPendingOrders = _pendingOrders
          .where((order) =>
      order.id.toLowerCase().contains(query.toLowerCase()) ||
          order.customerName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void clearAllOrders() {
    _allOrders.clear();
    _allOrdersPage = 1;
    _hasMoreAllOrders = true;
    _errorMessage = null;
    notifyListeners();
  }
  void clearMyJobs() {
    _myJobs.clear();
    _myJobsPage = 1;
    _hasMoreMyJobs = true;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchMyJobs({bool loadMore = false}) async {
    if (_isLoading) return;

    if (loadMore) {
      _myJobsPage++;
    } else {
      _myJobsPage = 1;
      _myJobs.clear();
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final orders = await _apiService.fetchMyJobs(
        page: _myJobsPage,
        limit: 10,
      );

      if (orders.isEmpty && _myJobs.isEmpty) {
        _errorMessage = 'No jobs available right now.';
      }

      _hasMoreMyJobs = orders.length >= 10;
      if (loadMore) {
        _myJobs.addAll(orders);
      } else {
        _myJobs = orders;
      }
    } catch (e) {
      // ✅ Actual backend message shown here
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _hasMoreMyJobs = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }



  Future<void> fetchAllOrders({bool loadMore = false}) async {
    if (_isLoading || (!loadMore && _allOrders.isNotEmpty)) return;
    if (loadMore) _allOrdersPage++;
    else _allOrdersPage = 1;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final orders = await _apiService.fetchAllOrders(page: _allOrdersPage, limit: 10);
      _hasMoreAllOrders = orders.length >= 10;
      if (loadMore) {
        _allOrders.addAll(orders);
      } else {
        _allOrders = orders;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _hasMoreAllOrders = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearPendingOrders() {
    _pendingOrders.clear();
    _pendingOrdersPage = 1;
    _hasMorePendingOrders = true;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchPendingOrders({bool loadMore = false}) async {
    if (_isLoading || (!loadMore && _pendingOrders.isNotEmpty)) return;
    if (loadMore) _pendingOrdersPage++;
    else _pendingOrdersPage = 1;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final orders = await _apiService.fetchPendingOrders(page: _pendingOrdersPage, limit: 10);
      _hasMorePendingOrders = orders.length >= 10;
      if (loadMore) {
        _pendingOrders.addAll(orders);
      } else {
        _pendingOrders = orders;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _hasMorePendingOrders = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateFullOrder(String orderId, Map<String, dynamic> orderData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.updateFullOrder(orderId, orderData);
      if (success) {
        final updatedOrder = Order.fromJson(orderData);
        _allOrders = _allOrders.map((order) => order.id == orderId ? updatedOrder : order).toList();
        _pendingOrders = _pendingOrders.map((order) => order.id == orderId ? updatedOrder : order).toList();
        _completedOrders = _completedOrders.map((order) => order.id == orderId ? updatedOrder : order).toList();
        _myJobs = _myJobs.map((order) => order.id == orderId ? updatedOrder : order).toList();
      } else {
        _errorMessage = 'Failed to update order';
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCompletedOrders() {
    _completedOrders.clear();
    _completedOrdersPage = 1;
    _hasMoreCompletedOrders = true;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchCompletedOrders({bool loadMore = false}) async {
    if (_isLoading || (!loadMore && _completedOrders.isNotEmpty)) return;
    if (loadMore) _completedOrdersPage++;
    else _completedOrdersPage = 1;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final orders = await _apiService.fetchCompletedOrders(page: _completedOrdersPage, limit: 10);
      _hasMoreCompletedOrders = orders.length >= 10;
      if (loadMore) {
        _completedOrders.addAll(orders);
      } else {
        _completedOrders = orders;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _hasMoreCompletedOrders = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptOrder(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.acceptOrder(orderId);
      if (success) {
        _allOrders = _allOrders.map((order) => order.id == orderId ? order.copyWith(status: 2) : order).toList();
        _pendingOrders = _pendingOrders.map((order) => order.id == orderId ? order.copyWith(status: 2) : order).toList();
        _myJobs = _myJobs.map((order) => order.id == orderId ? order.copyWith(status: 2) : order).toList();
      } else {
        _errorMessage = 'Failed to accept order';
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelOrder(String orderId, String reason) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.cancelOrder(orderId, reason);
      if (success) {
        _allOrders = _allOrders.where((order) => order.id != orderId).toList();
        _pendingOrders = _pendingOrders.where((order) => order.id != orderId).toList();
        _myJobs = _myJobs.where((order) => order.id != orderId).toList();
      } else {
        _errorMessage = 'Failed to cancel order';
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Order?> fetchOrderById(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final order = await _apiService.fetchOrderById(orderId);
      return order;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(String orderId, int newStatus) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.updateOrderStatus(orderId, newStatus);
      if (success) {
        _allOrders = _allOrders.map((order) => order.id == orderId ? order.copyWith(status: newStatus) : order).toList();
        _pendingOrders = _pendingOrders.map((order) => order.id == orderId ? order.copyWith(status: newStatus) : order).toList();
        _completedOrders = _completedOrders.map((order) => order.id == orderId ? order.copyWith(status: newStatus) : order).toList();
        _myJobs = _myJobs.map((order) => order.id == orderId ? order.copyWith(status: newStatus) : order).toList();
        print('OrderController: Status updated to $newStatus for order $orderId');
      } else {
        _errorMessage = 'Failed to update order status';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

extension on Order {
  Order copyWith({
    String? id,
    List<Item>? items,
    String? mode,
    List<Detail>? details,
    String? discount,
    String? shipping,
    int? totalAmount,
    UserId? userId,
    String? primary,
    int? payment,
    int? status,
    int? leadStatus,
    int? orderId,
    List<String>? category,
    int? type,
    BussId? bussId,
    SellId? sellId,
    WareId? wareId,
    String? longitude,
    String? latitude,
    String? razorpayOrderId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? v,
    String? razorpayPaymentId,
    String? razorpaySignature,
    RunnId? runnId,
  }) {
    return Order(
      id: id ?? this.id,
      items: items ?? this.items,
      mode: mode ?? this.mode,
      details: details ?? this.details,
      discount: discount ?? this.discount,
      shipping: shipping ?? this.shipping,
      totalAmount: totalAmount ?? this.totalAmount,
      userId: userId ?? this.userId,
      primary: primary ?? this.primary,
      payment: payment ?? this.payment,
      status: status ?? this.status,
      leadStatus: leadStatus ?? this.leadStatus,
      orderId: orderId ?? this.orderId,
      category: category ?? this.category,
      type: type ?? this.type,
      bussId: bussId ?? this.bussId,
      sellId: sellId ?? this.sellId,
      wareId: wareId ?? this.wareId,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      razorpaySignature: razorpaySignature ?? this.razorpaySignature,
      runnId: runnId ?? this.runnId,
    );
  }
}