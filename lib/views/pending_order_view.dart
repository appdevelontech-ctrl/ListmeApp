  import 'dart:async';
  import 'package:flutter/material.dart';
  import 'package:listme_app/services/api_services.dart';
  import 'package:provider/provider.dart';
  import 'package:flutter_easyloading/flutter_easyloading.dart';
  import 'package:google_maps_flutter/google_maps_flutter.dart';
  import 'package:geolocator/geolocator.dart';
  import '../controllers/order_controller.dart';
  import '../models/order_model.dart';
  import '../widgets/order_card.dart';
  import 'order_details_screen.dart';
  import 'tracking_screen.dart';
  import '../controllers/socket_controller.dart';

  class PendingOrdersScreen extends StatefulWidget {
    const PendingOrdersScreen({super.key});

    @override
    State<PendingOrdersScreen> createState() => _PendingOrdersScreenState();
  }

  class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
    final ScrollController _scrollController = ScrollController();
    final TextEditingController _cancelCommentController = TextEditingController();
    final TextEditingController _searchController = TextEditingController();

    String _searchQuery = '';
    GoogleMapController? _mapController;
    LatLng? _currentPosition;
    StreamSubscription<Position>? _positionStream;
    Order? _trackedOrder;
    late SocketController _socketController;

    @override
    void initState() {
      super.initState();
      final orderController = Provider.of<OrderController>(context, listen: false);
      _socketController = Provider.of<SocketController>(context, listen: false);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        orderController.fetchPendingOrders();
      });

      _scrollController.addListener(() {
        final controller = Provider.of<OrderController>(context, listen: false);
        if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
            controller.hasMorePendingOrders &&
            !controller.isLoading) {
          controller.fetchPendingOrders(loadMore: true);
        }
      });

      _searchController.addListener(() {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      });

      _getCurrentLocation();
    }

    @override
    void dispose() {
      _scrollController.dispose();
      _cancelCommentController.dispose();
      _searchController.dispose();
      _mapController?.dispose();
      _positionStream?.cancel();
      super.dispose();
    }

    Future<void> _getCurrentLocation() async {
      bool serviceEnabled;
      LocationPermission permission;

      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
          return;
        }

        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied')),
          );
          return;
        }

        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });

        _positionStream = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 50,
          ),
        ).listen((Position position) {
          if (_trackedOrder != null && _currentPosition != null) {
            _sendSocketData(
                _trackedOrder!.id, LatLng(position.latitude, position.longitude));
            setState(() {
              _currentPosition = LatLng(position.latitude, position.longitude);
            });
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }

    void _sendSocketData(String orderId, LatLng currentLocation) {
      final sendMessage = {
        "userId": "${ApiService().getEmployeeId()}",
        "currentLocation": {
          "lat": currentLocation.latitude,
          "lng": currentLocation.longitude,
        },
        "type": "location",
        "orderId": orderId,
      };
      _socketController.sendLocationUpdate(currentLocation);
      print('Socket data sent: $sendMessage');
    }

    void _showMapScreen(String orderId) async {
      final orderController = Provider.of<OrderController>(context, listen: false);
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please wait for location access')),
        );
        return;
      }

      try {
        EasyLoading.show(status: 'Loading order details...');
        final order = await orderController.fetchOrderById(orderId);
        if (order == null) throw Exception('Order not found');
        EasyLoading.dismiss();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrackingScreen(
              order: order,
              initialCurrentPosition: _currentPosition!,
            ),
          ),
        );
      } catch (e) {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading map: $e')),
        );
      }
    }

    void _showCancelDialog(
        BuildContext context, String orderId, OrderController controller) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Order'),
          content: TextField(
            controller: _cancelCommentController,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (_cancelCommentController.text.isNotEmpty) {
                  EasyLoading.show(status: 'Cancelling...');
                  final success =
                  await controller.cancelOrder(orderId, _cancelCommentController.text);
                  Navigator.pop(context);
                  EasyLoading.dismiss();
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order cancelled')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(controller.errorMessage ?? 'Failed to cancel order')));
                  }
                  _cancelCommentController.clear();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      final primaryColor = Colors.teal;

      return Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: const Text('Pending Orders',
              style: TextStyle(fontWeight: FontWeight.bold)),
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () async {
                final controller =
                Provider.of<OrderController>(context, listen: false);
                controller.clearPendingOrders();
                await controller.fetchPendingOrders();
              },
            ),
          ],
        ),
        body: Consumer<OrderController>(
          builder: (context, controller, child) {
            if (controller.isLoading && controller.pendingOrders.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.errorMessage != null && controller.pendingOrders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(controller.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.fetchPendingOrders(),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // 🔍 Filter orders based on search query
            final filteredOrders = controller.pendingOrders.where((order) {
              final nameMatch =
              order.customerName.toLowerCase().contains(_searchQuery);
              final idMatch = order.id.toLowerCase().contains(_searchQuery);
              return nameMatch || idMatch;
            }).toList();

            if (filteredOrders.isEmpty) {
              return Column(
                children: [
                  _buildSearchField(),
                  const Expanded(
                      child: Center(child: Text('No pending orders found'))),
                ],
              );
            }

            return Column(
              children: [
                _buildSearchField(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      controller.clearPendingOrders();
                      await controller.fetchPendingOrders();
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      itemCount:
                      filteredOrders.length + (controller.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == filteredOrders.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child:
                            Center(child: CircularProgressIndicator()),
                          );
                        }

                        final order = filteredOrders[index];
                        return OrderCard(
                          order: order,
                          onViewOrder: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    OrderDetailsScreen(orderId: order.id),
                              ),
                            );
                          },
                          onTrackOrder: () => _showMapScreen(order.id),
                          onDelete: () =>
                              _showCancelDialog(context, order.id, controller),
                          onStatusChange: (newStatus) async {
                            if (newStatus != order.status) {
                              EasyLoading.show(status: 'Updating...');
                              try {
                                await controller.updateOrderStatus(
                                    order.id, newStatus);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content:
                                  Text('Status updated'),
                                ));
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                      Text('Failed to update status: $e')),
                                );
                              } finally {
                                EasyLoading.dismiss();
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    /// 🔍 Search Field Builder
    Widget _buildSearchField() {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by name or order ID',
            prefixIcon: const Icon(Icons.search, color: Colors.teal),
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          ),
        ),
      );
    }
  }
