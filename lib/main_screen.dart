// main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'controllers/DashboardController.dart';

import 'views/all_job_view.dart';
import 'views/analytics_screen.dart';
import 'views/profile/profile_view.dart';
import 'views/widthrawal_view.dart';
import 'views/wallet_view.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? _userId;
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final controller = Provider.of<DashboardController>(context, listen: false);
    setState(() {
      _userId = prefs.getString('employeeId') ?? '';
      final userData = prefs.getString('userData');
      if (userData != null) {
        final userJson = json.decode(userData);
        _username = userJson['username'] ?? 'User';
      }
      print('MainScreen: Loaded userId: $_userId, username: $_username');
    });
    await controller.refreshWalletBalance();
    final userData = prefs.getString('userData');
    if (userData != null) {
      setState(() {
        final userJson = json.decode(userData);
        _username = userJson['username'] ?? _username;
        print('MainScreen: Updated username from API: $_username');
      });
    }
  }

  Future<bool> _onWillPop() async {
    print('MainScreen: Back button pressed, showing exit confirmation dialog');
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    }

    bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Confirmation'),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () {
              print('MainScreen: User chose "No", staying in app');
              Navigator.pop(context, false);
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              print('MainScreen: User chose "Yes", exiting app');
              Navigator.pop(context, true);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  Future<bool> _confirmLogout() async {
    bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout Confirmation'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              print('MainScreen: User chose "No", staying logged in');
              Navigator.pop(context, false);
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              print('MainScreen: User chose "Yes", proceeding with logout');
              Navigator.pop(context, true);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
      final controller = Provider.of<DashboardController>(context, listen: false);
      await controller.logout(context);
    }
    return shouldLogout ?? false;
  }

  List<Widget> get _screens {
    return [
      AnalyticsDashboard(),
      const AllOrdersScreen(),
      WithdrawalPage(userId: _userId ?? ''),
      const WalletView(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? Colors.tealAccent : Colors.teal;
    final cardColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        if (shouldExit) {
          print('MainScreen: Exiting app');
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [Colors.grey[800]!, Colors.grey[900]!, Colors.black87]
                    : [Colors.teal[300]!, Colors.teal[500]!, Colors.teal[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileViewPage(),
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: screenWidth * 0.06,
                          backgroundColor: primaryColor,
                          child: Text(
                            _username?.isNotEmpty == true
                                ? _username![0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Welcome, ${_username ?? "User"}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Consumer<DashboardController>(
                            builder: (context, controller, child) {
                              final balance = controller.walletBalance;
                              final formatter = NumberFormat.currency(
                                locale: 'en_IN',
                                symbol: '₹',
                                decimalDigits: 2,
                              );
                              return Text(
                                'Balance: ${formatter.format(balance)}',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w400,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await _confirmLogout();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.logout,
                          color: Colors.redAccent,
                          size: screenWidth * 0.06,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: _userId == null && _selectedIndex == 2
            ? Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        )
            : _screens[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.all(_selectedIndex == 0 ? 8 : 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedIndex == 0 ? primaryColor.withOpacity(0.2) : Colors.transparent,
                  ),
                  child: Icon(Icons.home, size: screenWidth * 0.07),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.all(_selectedIndex == 1 ? 8 : 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedIndex == 1 ? primaryColor.withOpacity(0.2) : Colors.transparent,
                  ),
                  child: Icon(Icons.work, size: screenWidth * 0.07),
                ),
                label: 'Jobs',
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.all(_selectedIndex == 2 ? 8 : 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedIndex == 2 ? primaryColor.withOpacity(0.2) : Colors.transparent,
                  ),
                  child: Icon(Icons.account_balance_wallet, size: screenWidth * 0.07),
                ),
                label: 'Withdrawal',
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.all(_selectedIndex == 3 ? 8 : 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedIndex == 3 ? primaryColor.withOpacity(0.2) : Colors.transparent,
                  ),
                  child: Icon(Icons.account_balance, size: screenWidth * 0.07),
                ),
                label: 'Wallet',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: primaryColor,
            unselectedItemColor: isDarkMode ? Colors.white70 : Colors.grey[600],
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: screenWidth * 0.035),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: screenWidth * 0.035),
            elevation: 0,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}