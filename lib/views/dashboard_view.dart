// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import '../controllers/DashboardController.dart';
// import '../controllers/order_controller.dart';
//
// import '../views/widthrawal_view.dart';
// import '../views/wallet_view.dart';
// import '../views/profile/edit_profile_view.dart';
// import 'all_job_view.dart';
//
// import 'menu_view.dart';
//
// class DashboardView extends StatefulWidget {
//   const DashboardView({super.key});
//
//   @override
//   State<DashboardView> createState() => _DashboardViewState();
// }
//
// class _DashboardViewState extends State<DashboardView> {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   int _selectedIndex = 0;
//   String? _userId;
//   String? _username;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _loadUserData();
//   }
//
//   Future<void> _loadUserData() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _userId = prefs.getString('employeeId') ?? '686d10c6452a92d558cb1496';
//       _username = prefs.getString('username') ?? 'User';
//       print('DashboardView: Loaded userId: $_userId, username: $_username');
//     });
//   }
//
//   Future<bool> _onWillPop() async {
//     print('DashboardView: Back button pressed, showing exit confirmation dialog');
//     if (_selectedIndex != 0) {
//       setState(() {
//         _selectedIndex = 0;
//       });
//       return false;
//     }
//
//     bool? shouldExit = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Exit Confirmation'),
//         content: const Text('Are you sure you want to exit the app?'),
//         actions: [
//           TextButton(
//             onPressed: () {
//               print('DashboardView: User chose "No", staying in app');
//               Navigator.pop(context, false);
//             },
//             child: const Text('No'),
//           ),
//           TextButton(
//             onPressed: () {
//               print('DashboardView: User chose "Yes", exiting app');
//               Navigator.pop(context, true);
//             },
//             child: const Text('Yes'),
//           ),
//         ],
//       ),
//     );
//     return shouldExit ?? false;
//   }
//
//   List<Widget> get _screens {
//     return [
//       const DashboardHome(),
//       const AllOrdersScreen(),
//       WithdrawalPage(userId: _userId ?? ''),
//       const WalletView(),
//     ];
//   }
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final dashboardController = Provider.of<DashboardController>(context);
//
//     return PopScope(
//       canPop: false,
//       onPopInvoked: (didPop) async {
//         if (didPop) return;
//         final shouldExit = await _onWillPop();
//         if (shouldExit) {
//           print('DashboardView: Exiting app');
//           SystemNavigator.pop();
//         }
//       },
//       child: Scaffold(
//         key: _scaffoldKey,
//         appBar: PreferredSize(
//           preferredSize: const Size.fromHeight(70),
//           child: Container(
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 colors: [
//                   Color(0xFF0D1B2A),
//                   Color(0xFF1B263B),
//                   Color(0xFF2C3245),
//                 ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: const BorderRadius.vertical(
//                 bottom: Radius.circular(20),
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.3),
//                   blurRadius: 8,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: SafeArea(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     IconButton(
//                       icon: Icon(
//                         Icons.person,
//                         color: Colors.white,
//                         size: screenWidth * 0.07,
//                       ),
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const EditProfilePage(),
//                           ),
//                         );
//                       },
//                     ),
//                     Expanded(
//                       child: Text(
//                         'Welcome, $_username',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: screenWidth * 0.045,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: screenWidth * 0.07), // Balance space for symmetry
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//         body: _userId == null && _selectedIndex == 2
//             ? const Center(child: CircularProgressIndicator())
//             : _screens[_selectedIndex],
//         bottomNavigationBar: BottomNavigationBar(
//           items: const <BottomNavigationBarItem>[
//             BottomNavigationBarItem(
//               icon: Icon(Icons.home),
//               label: 'Home',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.work),
//               label: 'Jobs',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.account_balance_wallet),
//               label: 'Withdrawal',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.account_balance),
//               label: 'Wallet',
//             ),
//           ],
//           currentIndex: _selectedIndex,
//           selectedItemColor: Colors.amber,
//           unselectedItemColor: Colors.white70,
//           backgroundColor: const Color(0xFF1B2333),
//           type: BottomNavigationBarType.fixed,
//           onTap: _onItemTapped,
//         ),
//       ),
//     );
//   }
// }
//
// class DashboardHome extends StatefulWidget {
//   const DashboardHome({super.key});
//
//   @override
//   State<DashboardHome> createState() => _DashboardHomeState();
// }
//
// class _DashboardHomeState extends State<DashboardHome> {
//   bool _isLoading = true;
//   String? _errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchData();
//   }
//
//   Future<void> _fetchData() async {
//     final orderController = Provider.of<OrderController>(context, listen: false);
//     final dashboardController = Provider.of<DashboardController>(context, listen: false);
//
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       await Future.wait([
//         orderController.fetchAllOrders(),
//         dashboardController.refreshWalletBalance(),
//       ]);
//       setState(() {
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = e.toString();
//       });
//       Fluttertoast.showToast(
//         msg: 'Failed to load data: $e',
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//       );
//     }
//   }
//
//   void _onCardTap(int index) {
//     final dashboardViewState = context.findAncestorStateOfType<_DashboardViewState>();
//     dashboardViewState?.setState(() {
//       dashboardViewState._selectedIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final dashboardController = Provider.of<DashboardController>(context);
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     double padding = screenWidth * 0.04;
//     const int crossAxisCount = 2;
//     double aspectRatio = 0.9;
//
//     if (_isLoading) {
//       return Padding(
//         padding: EdgeInsets.all(padding),
//         child: Column(
//           children: [
//             Shimmer.fromColors(
//               baseColor: Colors.grey.shade300,
//               highlightColor: Colors.grey.shade100,
//               child: Container(
//                 height: screenHeight * 0.12,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade300,
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//               ),
//             ),
//             Expanded(
//               child: GridView.count(
//                 crossAxisCount: crossAxisCount,
//                 mainAxisSpacing: padding,
//                 crossAxisSpacing: padding,
//                 childAspectRatio: aspectRatio,
//                 children: List.generate(
//                   4,
//                       (index) => Shimmer.fromColors(
//                     baseColor: Colors.grey.shade300,
//                     highlightColor: Colors.grey.shade100,
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade300,
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     if (_errorMessage != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(_errorMessage!, style: TextStyle(fontSize: screenWidth * 0.04)),
//             SizedBox(height: padding),
//             ElevatedButton(onPressed: _fetchData, child: const Text("Retry")),
//           ],
//         ),
//       );
//     }
//
//     return Column(
//       children: [
//         _buildWalletSection(dashboardController, screenWidth),
//         Expanded(
//           child: Padding(
//             padding: EdgeInsets.all(padding),
//             child: RefreshIndicator(
//               onRefresh: _fetchData,
//               child: GridView.count(
//                 crossAxisCount: crossAxisCount,
//                 mainAxisSpacing: padding,
//                 crossAxisSpacing: padding,
//                 childAspectRatio: aspectRatio,
//                 children: [
//                   _dashboardCard("All Jobs", Icons.list_alt_rounded, [Colors.orange, Colors.deepOrangeAccent], 1),
//                   _dashboardCard("Pending Jobs", Icons.access_time_rounded, [Colors.blue, Colors.indigo], 1),
//                   _dashboardCard("Completed Jobs", Icons.verified_rounded, [Colors.purple, Colors.deepPurpleAccent], 1),
//                   _dashboardCard("Cancelled Jobs", Icons.cancel_rounded, [Colors.redAccent, Colors.deepOrange], 1),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildWalletSection(DashboardController dashboardController, double screenWidth) {
//     final padding = screenWidth * 0.04;
//     final fontSize = screenWidth * 0.05;
//     final iconSize = screenWidth * 0.08;
//
//     return GestureDetector(
//       onTap: () => _onCardTap(3),
//       child: Container(
//         margin: EdgeInsets.all(padding),
//         padding: EdgeInsets.all(padding * 1.2),
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(
//             colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: const [
//             BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4)),
//           ],
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: iconSize),
//                 SizedBox(width: padding),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('My Wallet',
//                         style: TextStyle(
//                             color: Colors.white,
//                             fontSize: fontSize,
//                             fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 6),
//                     Text(
//                       'Balance: ₹${dashboardController.walletBalance}',
//                       style: TextStyle(
//                         color: Colors.white70,
//                         fontSize: fontSize * 0.8,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 20),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _dashboardCard(String title, IconData icon, List<Color> gradient, int index) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final fontSize = screenWidth * 0.04;
//     final iconSize = screenWidth * 0.12;
//
//     return GestureDetector(
//       onTap: () => _onCardTap(index),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         curve: Curves.easeOut,
//         padding: EdgeInsets.symmetric(vertical: screenWidth * 0.05, horizontal: 10),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: gradient,
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: const [
//             BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 3)),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: Colors.white, size: iconSize),
//             const SizedBox(height: 16),
//             Text(title,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                     color: Colors.white,
//                     fontSize: fontSize,
//                     fontWeight: FontWeight.w600)),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text("View Details",
//                     style: TextStyle(
//                         color: Colors.white70, fontSize: fontSize * 0.75)),
//                 const SizedBox(width: 6),
//                 Icon(Icons.arrow_forward_ios_rounded,
//                     color: Colors.white70, size: fontSize * 0.75),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }