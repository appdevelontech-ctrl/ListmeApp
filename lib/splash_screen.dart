// views/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:listme_app/views/auth/login_page.dart';
import '../controllers/auth/login_controller.dart';
import '../main_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool useDelay;

  const SplashScreen({super.key, this.useDelay = true});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    print('SplashScreen: Initializing splash screen');
  }

  Future<bool> _checkSessionWithDelay() async {
    print('SplashScreen: Checking session...');
    if (widget.useDelay) {
      await Future.delayed(const Duration(seconds: 2));
    }
    final isLoggedIn = await LoginController.isLoggedIn();
    print('SplashScreen: Session check complete, isLoggedIn: $isLoggedIn');
    return isLoggedIn;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // plain background
      body: FutureBuilder<bool>(
        future: _checkSessionWithDelay(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (snapshot.hasData && snapshot.data == true) {
                print('SplashScreen: User logged in, navigating to MainScreen');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              } else {
                print('SplashScreen: User not logged in, navigating to LoginPage');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            });
          }

          // Minimal splash design
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.shopping_bag, size: 80, color: Color(0xFF1B2333)),
                SizedBox(height: 20),
                Text(
                  "ListMe App",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2333),
                  ),
                ),
                SizedBox(height: 40),
                CircularProgressIndicator(color: Color(0xFF1B2333)),
              ],
            ),
          );
        },
      ),
    );
  }
}
