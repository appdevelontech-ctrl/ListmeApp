// import 'package:flutter/material.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:provider/provider.dart';
// import '../controllers/order_controller.dart';
// import '../models/order_model.dart';
// import '../services/api_services.dart';
// import '../widgets/AllorderCard.dart';
//
// class CompletedOrdersScreen extends StatefulWidget {
//   const CompletedOrdersScreen({super.key});
//
//   @override
//   State<CompletedOrdersScreen> createState() => _CompletedOrdersScreenState();
// }
//
// class _CompletedOrdersScreenState extends State<CompletedOrdersScreen> with WidgetsBindingObserver {
//   final TextEditingController _searchController = TextEditingController();
//   bool _isLoading = true;
//   String? _errorMessage;
//   List<Order> _filteredOrders = [];
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _fetchOrders();
//     _searchController.addListener(_filterOrders);
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       _fetchOrders();
//     }
//   }
//
//   Future<void> _fetchOrders() async {
//     final controller = Provider.of<OrderController>(context, listen: false);
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//     try {
//       EasyLoading.show(status: 'Fetching completed orders...');
//       await controller.fetchCompletedOrders();
//       setState(() {
//         _filteredOrders = controller.getOrders();
//         _isLoading = false;
//       });
//       _filterOrders();
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = controller.errorMessage ?? 'Failed to fetch completed orders';
//       });
//       Fluttertoast.showToast(
//         msg: _errorMessage!,
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//         fontSize: 16.0,
//       );
//     } finally {
//       EasyLoading.dismiss();
//     }
//   }
//
//   void _filterOrders() {
//     final controller = Provider.of<OrderController>(context, listen: false);
//     final query = _searchController.text.toLowerCase();
//     setState(() {
//       _filteredOrders = controller.getOrders().where((order) {
//         return order.id.toLowerCase().contains(query) ||
//             order.customerName.toLowerCase().contains(query) ||
//             order.items.any((item) => item.title.toLowerCase().contains(query));
//       }).toList();
//       _filteredOrders.sort((a, b) {
//         final dateA = DateTime.tryParse(a.createdAt) ?? DateTime(1970);
//         final dateB = DateTime.tryParse(b.createdAt) ?? DateTime(1970);
//         return dateB.compareTo(dateA);
//       });
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
//     final isTablet = screenWidth > 600;
//     final isSmallScreen = screenWidth < 400;
//     final padding = (screenWidth * 0.02).clamp(8.0, 12.0);
//     final fontSize = (screenWidth * 0.035).clamp(14.0, 16.0);
//     final iconSize = (screenWidth * 0.05).clamp(18.0, 22.0);
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Completed Orders'),
//         backgroundColor: isDarkMode ? Colors.tealAccent : Colors.teal,
//         foregroundColor: Colors.white,
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * (isTablet ? 0.8 : 0.6)),
//               child: TextField(
//                 controller: _searchController,
//                 decoration: InputDecoration(
//                   hintText: isSmallScreen ? 'Search Order' : 'Search by Order ID, Name, or Title',
//                   hintStyle: TextStyle(fontSize: fontSize * (isTablet ? 1.1 : 0.9), color: Colors.grey[600]),
//                   prefixIcon: Icon(Icons.search, size: iconSize, color: Colors.grey[600]),
//                   suffixIcon: _searchController.text.isNotEmpty
//                       ? IconButton(
//                     icon: Icon(Icons.clear, size: iconSize * 0.8, color: Colors.grey[600]),
//                     onPressed: () {
//                       _searchController.clear();
//                       _filterOrders();
//                     },
//                   )
//                       : null,
//                   contentPadding: EdgeInsets.symmetric(
//                     horizontal: padding * (isSmallScreen ? 1.0 : 1.2),
//                     vertical: padding * (isTablet ? 1.0 : 0.8),
//                   ),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
//                   enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
//                   focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 1.5)),
//                   filled: true,
//                   fillColor: Colors.white,
//                 ),
//                 style: TextStyle(fontSize: fontSize),
//               ),
//             ),
//             Expanded(
//               child: _isLoading
//                   ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E))))
//                   : _errorMessage != null
//                   ? Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.error_outline, size: iconSize * 2.5, color: Colors.red),
//                     SizedBox(height: padding * 1.5),
//                     Text(_errorMessage!, style: TextStyle(fontSize: fontSize * 1.2, color: Colors.grey[800], fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 2),
//                     SizedBox(height: padding * 1.5),
//                     ElevatedButton(
//                       onPressed: _fetchOrders,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue,
//                         foregroundColor: Colors.white,
//                         padding: EdgeInsets.symmetric(horizontal: padding * 2, vertical: padding),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
//                       ),
//                       child: const Text('Retry'),
//                     ),
//                   ],
//                 ),
//               )
//                   : _filteredOrders.isEmpty
//                   ? Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.inbox, size: iconSize * 2.5, color: Colors.grey[600]),
//                     SizedBox(height: padding * 1.5),
//                     Text("No completed orders found", style: TextStyle(fontSize: fontSize * 1.2, fontWeight: FontWeight.w500, color: Colors.grey[600])),
//                   ],
//                 ),
//               )
//                   : RefreshIndicator(
//                 onRefresh: _fetchOrders,
//                 color: const Color(0xFF1A237E),
//                 child: GridView.builder(
//                   physics: const AlwaysScrollableScrollPhysics(),
//                   padding: EdgeInsets.all(padding * (isTablet ? 1.5 : 1.0)),
//                   itemCount: _filteredOrders.length,
//                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: isLandscape ? 3 : 2,
//                     childAspectRatio: isLandscape ? 2.4 : 1.6,
//                     crossAxisSpacing: padding * 1.4,
//                     mainAxisSpacing: padding * 1.4,
//                   ),
//                   itemBuilder: (context, index) {
//                     final job = _filteredOrders[index];
//                     return JobCardWidget(job: job, onAccept: null); // No accept action for completed orders
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }