import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_color.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../layout/main_layout.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 1), () async {
        // Wait for auth provider to load token from storage
        final auth = Provider.of<AuthProvider>(context, listen: false);
        // Poll until initialized (small timeout)
        final end = DateTime.now().add(const Duration(seconds: 3));
        while (!auth.initialized && DateTime.now().isBefore(end)) {
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // If token exists, go to main layout, otherwise login screen
        final startDelay = const Duration(milliseconds: 800);
        await Future.delayed(startDelay);
        if (auth.token != null) {
          // Note: Agent profile will be loaded when needed, not during splash
          // to avoid 404 errors if endpoint doesn't exist
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainLayout(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                final tween = Tween(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeInOut));
                final offsetAnimation = animation.drive(tween);

                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
            ),
          );
          return;
        }

        // otherwise navigate to login
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              final tween = Tween(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeInOut));
              final offsetAnimation = animation.drive(tween);

              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
          ),
        );
      });
    });

    return Scaffold(
      backgroundColor: AppColor.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              'BRILink Admin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
