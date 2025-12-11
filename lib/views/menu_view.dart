import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/DashboardController.dart';

class MenuView extends StatelessWidget {
  final Function(int) onMenuSelected;
  final int selectedIndex;

  const MenuView({
    super.key,
    required this.onMenuSelected,
    required this.selectedIndex,
  });

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B2333),
          title: const Text('Confirm Logout', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to log out?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.amber)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Provider.of<DashboardController>(context, listen: false).logout(context);
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget logoutButton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth * 0.035;
    final iconSize = screenWidth * 0.04;
    final horizontalPadding = screenWidth * 0.03;
    final verticalPadding = screenWidth * 0.015;
    final iconPadding = screenWidth * 0.005;

    return ElevatedButton.icon(
      onPressed: () => _showLogoutConfirmationDialog(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        elevation: 0,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Container(
        padding: EdgeInsets.all(iconPadding),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Icon(Icons.logout, color: Colors.white, size: iconSize),
      ),
      label: Text(
        'Logout',
        style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardController = Provider.of<DashboardController>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    double drawerWidth = screenWidth < 600 ? screenWidth * 0.7 : 280;

    return Drawer(
      width: drawerWidth,
      backgroundColor: const Color(0xFF1B2333),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Helpy Admin",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 20),
                buildMenuTile(
                  index: 0,
                  icon: Icons.home,
                  title: "Dashboard",
                  color: Colors.amber,
                ),
                buildMenuTile(
                  index: 3,
                  icon: Icons.account_balance,
                  title: "Wallet (${dashboardController.walletBalance})",
                  color: Colors.green,
                ),
                buildMenuTile(
                  index: 2,
                  icon: Icons.account_balance_wallet,
                  title: "All Withdrawal",
                  color: Colors.white,
                ),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: const Icon(Icons.work, color: Colors.white),
                    title: const Text("Jobs",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white70,
                    children: [
                      subMenuItem("All Jobs", 1),
                    ],
                  ),
                ),
                buildMenuTile(
                  index: 7,
                  icon: Icons.person,
                  title: "Edit Profile",
                  color: Colors.blue,
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: logoutButton(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMenuTile({
    required int index,
    required IconData icon,
    required String title,
    required Color color,
  }) {
    final bool isSelected = selectedIndex == index;

    return ListTile(
      tileColor: isSelected ? Colors.white12 : Colors.transparent,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.amber : Colors.white,
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () => onMenuSelected(index),
    );
  }

  Widget subMenuItem(String text, int index) {
    final bool isSelected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        tileColor: isSelected ? Colors.white12 : Colors.transparent,
        title: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.amber : Colors.white70,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () => onMenuSelected(index),
      ),
    );
  }
}