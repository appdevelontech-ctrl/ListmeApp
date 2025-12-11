import 'package:flutter/material.dart';

class CustomMenuDrawer extends StatelessWidget {
  final Function(int) onMenuSelected;
  final int selectedIndex;

  const CustomMenuDrawer({
    super.key,
    required this.onMenuSelected,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Menu items
    final menuItems = [
      {"icon": Icons.dashboard_rounded, "title": "Dashboard"},
      {"icon": Icons.account_balance_wallet_rounded, "title": "Wallet"},
      {"icon": Icons.money_rounded, "title": "Withdrawals"},
      {"icon": Icons.list_alt_rounded, "title": "All Orders"},
      {"icon": Icons.pending_actions_rounded, "title": "Pending Orders"},
      {"icon": Icons.check_circle_rounded, "title": "Completed Orders"},
      {"icon": Icons.cancel_rounded, "title": "Cancelled Orders"},
      {"icon": Icons.manage_accounts_rounded, "title": "Profile Edit"},
      {"icon": Icons.logout_rounded, "title": "Logout"},
    ];

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        width: screenWidth * 0.65,
        margin: EdgeInsets.only(top: screenHeight * 0.05, bottom: screenHeight * 0.05),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(4, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ===== Drawer Header =====
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded, size: 50, color: Colors.deepPurple),
            ),
            const SizedBox(height: 12),
            const Text(
              "Admin Panel",
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 30),

            // ===== Menu Items =====
            Expanded(
              child: ListView.builder(
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  final isSelected = selectedIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                        colors: [Colors.deepPurpleAccent, Colors.purpleAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                      color: isSelected ? null : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: Colors.deepPurpleAccent.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                          : [],
                    ),
                    child: ListTile(
                      leading: Icon(item["icon"] as IconData,
                          color: isSelected ? Colors.white : Colors.white70),
                      title: Text(
                        item["title"] as String,
                        style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 18,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                      ),
                      onTap: () {
                        onMenuSelected(index);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
