import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';
import '../widgets/AllorderCard.dart';
import 'myjobs_screen.dart';
import 'pending_order_view.dart';
import 'completed_order_view.dart';
import 'order_details_screen.dart';

class AllOrdersScreen extends StatefulWidget {
  const AllOrdersScreen({super.key});

  @override
  State<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<AllOrdersScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _cancelCommentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final orderController = Provider.of<OrderController>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      orderController.fetchAllOrders();
    });

    _scrollController.addListener(() {
      final orderController = Provider.of<OrderController>(context, listen: false);
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          orderController.hasMoreAllOrders &&
          !orderController.isLoading) {
        orderController.fetchAllOrders(loadMore: true);
      }
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cancelCommentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showCancelDialog(BuildContext context, String orderId, OrderController controller) {
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_cancelCommentController.text.isNotEmpty) {
                EasyLoading.show(status: 'Cancelling...');
                final success =
                await controller.cancelOrder(orderId, _cancelCommentController.text);
                Navigator.pop(context);
                EasyLoading.dismiss();
                if (success) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Order cancelled')));
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

  Widget _buildSearchField(OrderController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // 🔍 Search bar
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or order ID',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 🔄 Refresh button beside search bar
          IconButton(
            tooltip: 'Refresh Orders',
            icon: const Icon(Icons.refresh, color: Colors.teal, size: 28),
            onPressed: () async {
              FocusScope.of(context).unfocus();
              EasyLoading.show(status: 'Refreshing...');
              controller.clearAllOrders(); // clears and resets pagination
              await controller.fetchAllOrders();
              EasyLoading.dismiss();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.teal;

    return Scaffold(
      body: Consumer<OrderController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.allOrders.isEmpty) {
            return _OrdersShimmerLoader();
          }

          if (controller.errorMessage != null && controller.allOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(controller.errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.fetchAllOrders(),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // 🔍 Filter orders based on search query
          final filteredOrders = controller.allOrders.where((order) {
            final nameMatch = order.customerName.toLowerCase().contains(_searchQuery);
            final idMatch = order.id.toLowerCase().contains(_searchQuery);
            return nameMatch || idMatch;
          }).toList();

          if (filteredOrders.isEmpty) {
            return Column(
              children: [
                _buildSearchField(controller),
                const Expanded(child: Center(child: Text('No jobs found'))),
              ],
            );
          }

          return Column(
            children: [
              _buildSearchField(controller),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => controller.fetchAllOrders(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    itemCount: filteredOrders.length + (controller.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredOrders.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final order = filteredOrders[index];
                      return JobCardWidget(
                        job: order,
                        onStatusUpdate: (newStatus) async {
                          if (newStatus != order.status) {
                            EasyLoading.show(status: 'Updating...');
                            await controller.updateOrderStatus(order.id, newStatus);
                            EasyLoading.dismiss();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Status updated to ${Order.fromJson({'status': newStatus}).statusText}'),
                            ));
                          }
                        },
                        onDelete: () => _showCancelDialog(context, order.id, controller),
                        onViewOrder: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailsScreen(orderId: order.id),
                            ),
                          );
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

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.extended(
              heroTag: 'myjobs_btn',
              backgroundColor: Colors.blueAccent,
              icon: const Icon(Icons.work_outline, color: Colors.white),
              label: const Text(
                'My Jobs',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyJobsScreen())
                );
              },
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'pending_btn',
              backgroundColor: Colors.orangeAccent,
              icon: const Icon(Icons.pending_actions, color: Colors.white),
              label: const Text(
                'Pending',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const PendingOrdersScreen()));
              },
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'completed_btn',
              backgroundColor: Colors.green,
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text(
                'Completed',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) =>   CompletedOrdersScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 🌟 Shimmer Loader for Orders List
class _OrdersShimmerLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(width: 50, height: 50, color: Colors.grey),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 12,
                        color: Colors.grey,
                        margin: const EdgeInsets.symmetric(vertical: 4)),
                    Container(
                        height: 12,
                        width: 80,
                        color: Colors.grey,
                        margin: const EdgeInsets.symmetric(vertical: 4)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 40, height: 12, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
