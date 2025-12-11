import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../controllers/order_controller.dart';
import '../widgets/order_card.dart';

class CompletedOrdersScreen extends StatefulWidget {
  @override
  _CompletedOrdersScreenState createState() => _CompletedOrdersScreenState();
}

class _CompletedOrdersScreenState extends State<CompletedOrdersScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final orderController = context.read<OrderController>();

    if (orderController.completedOrders.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        orderController.fetchCompletedOrders();
      });
    }

    _scrollController.addListener(_onScroll);

    // Search listener
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  void _onScroll() {
    final controller = context.read<OrderController>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !controller.isLoading &&
        controller.hasMoreCompletedOrders) {
      controller.fetchCompletedOrders(loadMore: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchAndRefresh(OrderController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // 🔍 Search Field
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or order ID',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 🔄 Refresh Button
          IconButton(
            tooltip: 'Refresh Orders',
            icon: const Icon(Icons.refresh, color: Colors.teal, size: 28),
            onPressed: () async {
              FocusScope.of(context).unfocus();
              EasyLoading.show(status: 'Refreshing...');
              controller.clearCompletedOrders();
              await controller.fetchCompletedOrders();
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
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Completed Orders',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<OrderController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.completedOrders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter by search query
          final filteredOrders = controller.completedOrders.where((order) {
            final nameMatch =
            order.customerName.toLowerCase().contains(_searchQuery);
            final idMatch = order.id.toLowerCase().contains(_searchQuery);
            return nameMatch || idMatch;
          }).toList();

          if (filteredOrders.isEmpty && !controller.isLoading) {
            return Column(
              children: [
                _buildSearchAndRefresh(controller),
                const Expanded(
                  child: Center(
                    child: Text(
                      'No completed orders found yet.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              _buildSearchAndRefresh(controller),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    controller.clearCompletedOrders();
                    await controller.fetchCompletedOrders();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: filteredOrders.length +
                        (controller.hasMoreCompletedOrders ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredOrders.length &&
                          controller.hasMoreCompletedOrders) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final order = filteredOrders[index];
                      return OrderCard(
                        order: order,
                        onViewOrder: () {
                          // TODO: Add navigation to order details if needed
                        },
                        onTrackOrder: () {},
                        onDelete: () {},
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
}
