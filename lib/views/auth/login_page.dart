  // views/auth/login_page.dart
  import 'package:flutter/material.dart';
  import 'package:flutter_easyloading/flutter_easyloading.dart';
  import 'package:provider/provider.dart';
  import '../../controllers/auth/login_controller.dart';
  import '../../main_screen.dart';

  class LoginPage extends StatefulWidget {
    const LoginPage({super.key});

    @override
    State<LoginPage> createState() => _LoginPageState();
  }

  class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    late AnimationController _animationController;
    late Animation<double> _fadeAnimation;

    @override
    void initState() {
      super.initState();
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      _fadeAnimation = CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      );
      _animationController.forward();
    }

    @override
    void dispose() {
      emailController.dispose();
      passwordController.dispose();
      _animationController.dispose();
      super.dispose();
    }

    Future<void> handleLogin() async {
      final loginController = Provider.of<LoginController>(context, listen: false);

      loginController.setEmail(emailController.text);
      loginController.setPassword(passwordController.text);

      await EasyLoading.show(
        status: 'Signing In...',
        maskType: EasyLoadingMaskType.black,
      );

      try {
        final success = await loginController.login(context);
        if (success) {
          await EasyLoading.showSuccess(
            'Login successful!',
            duration: const Duration(seconds: 2),
          );
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
                  (Route<dynamic> route) => false, // पुरानी स्क्रीन हटाने के लिए false
            );

          }
        } else {
          if (context.mounted) {
            await EasyLoading.showError(
              loginController.errorMessage ?? 'Invalid email or password',
              duration: const Duration(seconds: 3),
            );
          }
        }
      } catch (e) {
        print('Login Error: $e');
        if (context.mounted) {
          await EasyLoading.showError(
            'An error occurred: ${e.toString()}',
            duration: const Duration(seconds: 3),
          );
        }
      } finally {
        if (context.mounted) {
          await EasyLoading.dismiss();
        }
      }
    }

    @override
    Widget build(BuildContext context) {
      const Color backgroundColor = Color(0xFF1B2333);
      final theme = Theme.of(context);

      return Scaffold(
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: backgroundColor,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_open, size: 80, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome Back!',
                      style: theme.textTheme.headlineSmall!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue',
                      style: theme.textTheme.titleMedium!.copyWith(color: Colors.white70),
                    ),
                    Consumer<LoginController>(
                      builder: (context, controller, child) {
                        return controller.errorMessage != null
                            ? Column(
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              controller.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        )
                            : const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 32),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 10,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.email),
                                labelText: 'Email Address',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock),
                                labelText: 'Password',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // TODO: Implement forgot password flow
                                },
                                child: const Text('Forgot password?'),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: Consumer<LoginController>(
                                builder: (context, controller, child) {
                                  return ElevatedButton(
                                    onPressed: controller.isLoading ? null : handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1B2333),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: controller.isLoading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : const Text('Sign In', style: TextStyle(fontSize: 18, color: Colors.white)),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "ListMe © 2025",
                      style: theme.textTheme.bodySmall!.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }