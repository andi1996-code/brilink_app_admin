import 'package:brilink_app_admin/core/app_navigator.dart';
import 'package:brilink_app_admin/screens/login_screen.dart';
import 'package:brilink_app_admin/widgets/custom_alert.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_app_bar.dart';
import 'package:brilink_app_admin/screens/service_management_screen.dart';
import 'package:brilink_app_admin/screens/edc_management_screen.dart';
import 'package:brilink_app_admin/screens/service_fee_management_screen.dart';
import 'package:brilink_app_admin/screens/bank_fee_management_screen.dart';
import 'package:brilink_app_admin/screens/cash_flow_management_screen.dart';
import 'package:brilink_app_admin/screens/user_management_screen.dart';
import 'package:brilink_app_admin/screens/agent_management_screen.dart';
import '../widgets/custom_button.dart';
import 'package:brilink_app_admin/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _isResetLoading = false;

  Future<void> _resetAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Reset Saldo'),
        content: const Text(
          'Apakah Anda yakin ingin mereset semua data? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isResetLoading = true);

    try {
      final apiService = ApiClient.instance.apiService;
      await apiService.post('/api/edc-machines/reset-all');

      if (mounted) {
        AppNavigator.showAlert(
          'Data berhasil direset',
          type: AlertType.success,
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        AppNavigator.showAlert(
          e.response?.data?['message'] ?? e.message ?? 'Gagal melakukan reset',
          type: AlertType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        AppNavigator.showAlert(
          'Gagal melakukan reset: $e',
          type: AlertType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResetLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Pengaturan'),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _menuItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                return _buildMenuItem(context, item, colorScheme);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CustomButton(
                  text: 'Reset Saldo',
                  icon: Icons.restart_alt,
                  onPressed: _isResetLoading ? null : _resetAll,
                  isLoading: _isResetLoading,
                  backgroundColor: Colors.orange.shade600,
                  textColor: Colors.white,
                  height: 50,
                  borderRadius: 12,
                ),
                const SizedBox(height: 12),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) => CustomButton(
                    text: 'Logout',
                    icon: Icons.logout,
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Konfirmasi Logout'),
                                content: const Text(
                                  'Apakah Anda yakin ingin logout?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Logout'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed != true) return;

                            final ok = await auth.logoutFromServer();
                            if (ok) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            } else {
                              AppNavigator.showAlert(
                                auth.errorMessage ?? 'Logout gagal',
                                type: AlertType.error,
                              );
                            }
                          },
                    backgroundColor: colorScheme.error,
                    textColor: colorScheme.onError,
                    height: 50,
                    borderRadius: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    _MenuItem item,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: colorScheme.surface,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => item.screen),
            );
          },
          splashColor: colorScheme.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Widget screen;

  const _MenuItem({
    required this.title,
    required this.icon,
    required this.screen,
  });
}

final List<_MenuItem> _menuItems = [
  _MenuItem(
    title: 'Manajemen Layanan',
    icon: Icons.settings,
    screen: const ServiceManagementScreen(),
  ),
  _MenuItem(
    title: 'Manajemen Mesin EDC',
    icon: Icons.devices,
    screen: const EdcManagementScreen(),
  ),
  _MenuItem(
    title: 'Manajemen Biaya Layanan',
    icon: Icons.money,
    screen: const ServiceFeeManagementScreen(),
  ),
  _MenuItem(
    title: 'Manajemen Admin Bank',
    icon: Icons.admin_panel_settings,
    screen: const BankFeeManagementScreen(),
  ),
  _MenuItem(
    title: 'Manajemen Agen',
    icon: Icons.business,
    screen: const AgentManagementScreen(),
  ),
  _MenuItem(
    title: 'Manajemen Alur Kas',
    icon: Icons.account_balance,
    screen: const CashFlowManagementScreen(),
  ),
  _MenuItem(
    title: 'Manajemen Pengguna',
    icon: Icons.people,
    screen: const UserManagementScreen(),
  ),
];
