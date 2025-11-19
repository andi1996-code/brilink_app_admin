import 'package:brilink_app_admin/layout/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_color.dart';
import '../../core/constants/app_style.dart';
import '../providers/auth_provider.dart';
import '../core/app_navigator.dart';
import '../widgets/custom_alert.dart';
import '../services/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController serverUrlController = TextEditingController();
  bool isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Prefill with current base URL
    serverUrlController.text = ApiClient.instance.baseUrl;
  }

  @override
  void dispose() {
    serverUrlController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void handleLogin(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = usernameController.text.trim();
    final password = passwordController.text.trim();
    final baseUrl = serverUrlController.text.trim();

    if (baseUrl.isEmpty) {
      AppNavigator.showAlert('URL server harus diisi', type: AlertType.error);
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      AppNavigator.showAlert(
        'Email dan password harus diisi',
        type: AlertType.error,
      );
      return;
    }

    // Apply and persist the server URL before login
    await ApiClient.instance.setBaseUrl(baseUrl);

    final ok = await auth.login(email, password);
    if (ok) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainLayout(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(position: offsetAnimation, child: child);
          },
        ),
      );
    } else {
      // show floating error alert
      AppNavigator.showAlert(
        auth.errorMessage ?? 'Login gagal',
        type: AlertType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adaptiveTheme = AdaptiveTheme.of(context);
    final isDarkMode = adaptiveTheme.mode == AdaptiveThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColor.darkBackground
          : AppColor.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              right: 16,
              child: Row(
                children: [
                  Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      if (value) {
                        adaptiveTheme.setDark();
                      } else {
                        adaptiveTheme.setLight();
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 64,
                    color: isDarkMode
                        ? AppColor.darkTextPrimary
                        : AppColor.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'BRILink Admin',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? AppColor.darkTextPrimary
                          : AppColor.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? AppColor.darkSurface
                          : AppColor.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Server URL field
                        TextField(
                          controller: serverUrlController,
                          decoration: AppStyle.inputDecoration(
                            label: 'URL Server',
                            icon: Icons.link,
                          ).copyWith(helperText: 'Contoh: https://example.com'),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: usernameController,
                          decoration: AppStyle.inputDecoration(
                            label: 'Username atau Email',
                            icon: Icons.person,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,
                          decoration:
                              AppStyle.inputDecoration(
                                label: 'Password',
                                icon: Icons.lock,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: isDarkMode
                                        ? AppColor.darkTextPrimary
                                        : AppColor.textPrimary,
                                  ),
                                  onPressed: () => setState(
                                    () =>
                                        isPasswordVisible = !isPasswordVisible,
                                  ),
                                ),
                              ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: Consumer<AuthProvider>(
                            builder: (context, auth, _) => ElevatedButton.icon(
                              onPressed: auth.isLoading
                                  ? null
                                  : () => handleLogin(context),
                              icon: auth.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      Icons.login,
                                      color: isDarkMode
                                          ? AppColor.darkTextPrimary
                                          : Colors.white,
                                    ),
                              label: Text(
                                auth.isLoading ? 'Memproses...' : 'Masuk',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? AppColor.darkTextPrimary
                                      : Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '© 2025 BRILink Admin Panel',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? AppColor.darkTextSecondary
                          : AppColor.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
