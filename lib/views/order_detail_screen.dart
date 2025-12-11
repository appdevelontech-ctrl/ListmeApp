// import 'package:flutter/material.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:provider/provider.dart';
// import '../controllers/order_controller.dart';
// import '../models/order_model.dart';
//
// class OrderDetailScreen extends StatefulWidget {
//   final String orderId;
//   final OrderController controller;
//
//   const OrderDetailScreen({
//     super.key,
//     required this.orderId,
//     required this.controller,
//   });
//
//   @override
//   State<OrderDetailScreen> createState() => _OrderDetailScreenState();
// }
//
// class _OrderDetailScreenState extends State<OrderDetailScreen> with SingleTickerProviderStateMixin {
//   bool _isLoading = true;
//   Order? _order;
//   String? _errorMessage;
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   late AnimationController _animationController;
//   late Animation<double> _blinkAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1000),
//     )..repeat(reverse: true);
//     _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(_animationController);
//     _fetchOrder();
//     _syncTimerState();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _syncTimerState() async {
//     try {
//       EasyLoading.show(status: 'Syncing timer state...'); // Show loader
//       final controller = Provider.of<OrderController>(context, listen: false);
//       await controller.init();
//       if (controller.getActiveOrderId() == widget.orderId && controller.jobStartTime != null) {
//         controller.isTimerRunning = true;
//         controller.startTimer(); // Fixed typo: startTimer -> _startTimer
//         print('syncTimerState: Timer synced for order ${widget.orderId}');
//       }
//     } catch (e) {
//       print('syncTimerState: Error syncing timer state: $e');
//     } finally {
//       EasyLoading.dismiss(); // Hide loader
//     }
//   }
//
//   Future<void> _fetchOrder() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//     if (widget.orderId.isEmpty) {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = "Invalid order ID";
//       });
//       return;
//     }
//     try {
//       EasyLoading.show(status: 'Fetching order...'); // Show loader
//       final order = await widget.controller.fetchOrderById(widget.orderId);
//       setState(() {
//         _order = order;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = e.toString();
//       });
//     } finally {
//       EasyLoading.dismiss(); // Hide loader
//     }
//   }
//
//   Future<void> _startJob() async {
//     final TextEditingController otpController = TextEditingController();
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: const Text("Enter OTP"),
//         content: TextField(
//           controller: otpController,
//           keyboardType: TextInputType.number,
//           decoration: const InputDecoration(labelText: "OTP"),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: const Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () async {
//               final otp = otpController.text.trim();
//               if (otp.isEmpty) {
//                 if (mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Please enter OTP")),
//                   );
//                 }
//                 return;
//               }
//               Navigator.pop(dialogContext);
//               if (!mounted) return;
//               setState(() {
//                 _isLoading = true;
//               });
//               try {
//                 EasyLoading.show(status: 'Starting job...'); // Show loader
//                 final controller = Provider.of<OrderController>(context, listen: false);
//                 await controller.startJob(widget.orderId, otp);
//                 final updatedOrder = await controller.fetchOrderById(widget.orderId);
//                 if (mounted) {
//                   setState(() {
//                     _order = updatedOrder;
//                     _isLoading = false;
//                   });
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Job timer started successfully")),
//                   );
//                 }
//               } catch (e) {
//                 if (mounted) {
//                   setState(() {
//                     _isLoading = false;
//                   });
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text("Error starting job: $e")),
//                   );
//                 }
//               } finally {
//                 EasyLoading.dismiss(); // Hide loader
//               }
//             },
//             child: const Text("Submit"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _endJob() async {
//     if (!mounted) return;
//     setState(() {
//       _isLoading = true;
//     });
//     try {
//       EasyLoading.show(status: 'Ending job...'); // Show loader
//       final controller = Provider.of<OrderController>(context, listen: false);
//       await controller.endJob(widget.orderId);
//       final updatedOrder = await controller.fetchOrderById(widget.orderId);
//       if (mounted) {
//         setState(() {
//           _order = updatedOrder;
//           _isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Job ended successfully")),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Error ending job: $e")),
//         );
//       }
//     } finally {
//       EasyLoading.dismiss(); // Hide loader
//     }
//   }
//
//   Widget _buildSectionTitle(String title) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
//       child: Text(
//         title,
//         style: TextStyle(
//           fontSize: screenWidth * 0.045,
//           fontWeight: FontWeight.bold,
//           color: Colors.black87,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(String label, String value) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text("$label: ", style: TextStyle(fontWeight: FontWeight.w600, fontSize: screenWidth * 0.035)),
//           Expanded(child: Text(value, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: screenWidth * 0.035))),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildItemCard(OrderItem item) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     return Card(
//       margin: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ListTile(
//         leading: ClipRRect(
//           borderRadius: BorderRadius.circular(8),
//           child: Image.network(
//             item.image.isNotEmpty ? item.image : "https://via.placeholder.com/50",
//             width: screenWidth * 0.12,
//             height: screenWidth * 0.12,
//             fit: BoxFit.cover,
//             errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, size: screenWidth * 0.1),
//           ),
//         ),
//         title: Text(item.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: screenWidth * 0.04)),
//         subtitle: Text("Qty: ${item.quantity}", style: TextStyle(fontSize: screenWidth * 0.035)),
//         trailing: Text("₹${item.price}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: screenWidth * 0.035)),
//       ),
//     );
//   }
//
//   Widget _buildSummaryCard() {
//     final screenWidth = MediaQuery.of(context).size.width;
//     return Card(
//       margin: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: EdgeInsets.all(screenWidth * 0.04),
//         child: Column(
//           children: [
//             _buildSummaryRow("Subtotal", "₹${_order?.totalAmount ?? '0'}"),
//             _buildSummaryRow("Shipping", "₹${_order?.shipping ?? '0'}"),
//             _buildSummaryRow("Discount", "-₹${_order?.discount ?? '0'}", isDiscount: true),
//             const Divider(thickness: 1),
//             _buildSummaryRow("Total", "₹${_order?.totalAmount ?? '0'}", isTotal: true),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSummaryRow(String label, String value, {bool isDiscount = false, bool isTotal = false}) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.w500, fontSize: screenWidth * 0.035)),
//           Text(
//             value,
//             style: TextStyle(
//               fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
//               color: isDiscount ? Colors.red : (isTotal ? Colors.black : Colors.grey[700]),
//               fontSize: screenWidth * 0.035,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     return Scaffold(
//       key: _scaffoldKey,
//       appBar: AppBar(
//         title: Text("Order Details", style: TextStyle(color: Colors.white,fontSize: screenWidth * 0.045)),
//         backgroundColor:const Color(0xFF1A237E),
//         actions: [
//           Consumer<OrderController>(
//             builder: (context, orderController, child) {
//               final isTimerActive = orderController.isTimerRunning && orderController.getActiveOrderId() == widget.orderId;
//               return Padding(
//                 padding: EdgeInsets.only(right: screenWidth * 0.02),
//                 child: isTimerActive
//                     ? GestureDetector(
//                   onTap: () {
//                     showDialog(
//                       context: context,
//                       builder: (context) => AlertDialog(
//                         title: const Text("Timer Details"),
//                         content: Text(
//                           "Started at: ${orderController.jobStartTime?.toLocal() ?? 'Unknown'}\nElapsed: ${orderController.getFormattedDuration()}",style: TextStyle(fontSize: 18),
//                         ),
//                         actions: [
//                           TextButton(
//                             onPressed: () => Navigator.pop(context),
//                             child: const Text("Close"),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       FadeTransition(
//                         opacity: _blinkAnimation,
//                         child: Icon(Icons.timer, color: Colors.white, size: screenWidth * 0.035),
//                       ),
//                       SizedBox(width: screenWidth * 0.01),
//                       Flexible(
//                         child: Text(
//                           orderController.getFormattedDuration(),
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: screenWidth * 0.04,
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//                     : const SizedBox.shrink(),
//               );
//             },
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _errorMessage != null
//           ? Center(child: Text("Error: $_errorMessage", style: TextStyle(fontSize: screenWidth * 0.04)))
//           : _order == null
//           ? Center(child: Text("No order found", style: TextStyle(fontSize: screenWidth * 0.04)))
//           : LayoutBuilder(
//         builder: (context, constraints) {
//           final isWide = constraints.maxWidth > 800;
//           return SingleChildScrollView(
//             padding: EdgeInsets.all(screenWidth * 0.04),
//             child: Center(
//               child: ConstrainedBox(
//                 constraints: const BoxConstraints(maxWidth: 900),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildSectionTitle("Customer Details"),
//                     Card(
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       margin: EdgeInsets.only(bottom: screenWidth * 0.04),
//                       child: Padding(
//                         padding: EdgeInsets.all(screenWidth * 0.04),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             _buildInfoRow("Full Name", _order?.customerName ?? ""),
//                             _buildInfoRow("Phone", _order?.phone ?? ""),
//                             _buildInfoRow("Email", _order?.email ?? ""),
//                             _buildInfoRow("Address", _order?.address ?? ""),
//                             _buildInfoRow("Pincode", _order?.pincode ?? ""),
//                           ],
//                         ),
//                       ),
//                     ),
//                     _buildSectionTitle("Order Details"),
//                     Card(
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       margin: EdgeInsets.only(bottom: screenWidth * 0.04),
//                       child: Padding(
//                         padding: EdgeInsets.all(screenWidth * 0.04),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             _buildInfoRow("Booking Date", _order?.bookingDate ?? ""),
//                             _buildInfoRow("Booking Time", _order?.bookingTime ?? ""),
//                             _buildInfoRow("Status", _order?.status ?? ""),
//                           ],
//                         ),
//                       ),
//                     ),
//                     _buildSectionTitle("Items"),
//                     ...?_order?.items.map(_buildItemCard).toList(),
//                     _buildSectionTitle("Summary"),
//                     _buildSummaryCard(),
//                     SizedBox(height: screenWidth * 0.05),
//                     Center(
//                       child: Consumer<OrderController>(
//                         builder: (context, controller, child) {
//                           final isJobStarted = controller.isTimerRunning && controller.getActiveOrderId() == widget.orderId;
//                           final hasEnded = _order?.endTime != null && _order!.endTime!.isNotEmpty;
//                           final isButtonDisabled = _order?.status == "Completed" || _order?.status == "Cancelled";
//                           // Hide button if endTime is set; otherwise, show it with appropriate state
//                           if (hasEnded) {
//                             return const SizedBox.shrink(); // Hide button completely
//                           }
//                           return ElevatedButton.icon(
//                             onPressed: isButtonDisabled ? null : (isJobStarted ? _endJob : _startJob),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: isJobStarted ? Colors.red : Colors.green,
//                               padding: EdgeInsets.symmetric(
//                                 horizontal: screenWidth * 0.05,
//                                 vertical: screenWidth * 0.035,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                             icon: Icon(
//                               isJobStarted ? Icons.stop : Icons.play_arrow,
//                               color: Colors.white,
//                               size: screenWidth * 0.035,
//                             ),
//                             label: Text(
//                               isJobStarted ? "End Job" : "Start Job",
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: screenWidth * 0.03,
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }