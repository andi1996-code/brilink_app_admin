import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:brilink_app_admin/providers/agent_profile_provider.dart';
import 'package:brilink_app_admin/providers/agent_provider.dart';
import 'package:brilink_app_admin/providers/cash_flow_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/menu_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/service_provider.dart';
import 'providers/service_fee_provider.dart';
import 'providers/edc_provider.dart';
import 'providers/activation_provider.dart';
import 'providers/bank_fee_provider.dart';
import 'providers/user_provider.dart';
import 'providers/report_provider.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';
import 'core/app_navigator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load saved API base URL before app starts
  await ApiClient.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use the shared ApiClient singleton so configuration is centralized
    final apiService = ApiClient.instance.apiService;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MenuProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ServiceProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ServiceFeeProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => EdcProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => BankFeeProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => AgentProfileProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => AgentProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => CashFlowProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ActivationProvider(apiService: apiService),
        ),
      ],
      child: AdaptiveTheme(
        light: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        dark: ThemeData.dark().copyWith(useMaterial3: true),
        initial: AdaptiveThemeMode.light,
        builder: (theme, darkTheme) => MaterialApp(
          navigatorKey: AppNavigator.navigatorKey,
          title: 'Aplikasi Saya',
          theme: theme,
          darkTheme: darkTheme,
          debugShowCheckedModeBanner: false, // opsional: hilangkan banner debug
          home: const SplashScreen(), // ← Mulai dari splash
        ),
      ),
    );
  }
}
