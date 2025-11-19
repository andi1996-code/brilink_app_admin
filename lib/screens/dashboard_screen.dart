import 'package:brilink_app_admin/screens/service_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:brilink_app_admin/screens/bank_fee_management_screen.dart';
import 'package:brilink_app_admin/screens/service_fee_management_screen.dart';

import '../../core/constants/app_color.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // load via provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      provider.loadDashboard();
    });
  }

  String _formatCurrency(int value) {
    if (value == 0) return 'Rp 0';
    final s = value.toString();
    final chars = s.split('').reversed.toList();
    final grouped = <String>[];
    for (var i = 0; i < chars.length; i += 3) {
      final end = (i + 3 > chars.length) ? chars.length : i + 3;
      grouped.add(chars.sublist(i, end).join());
    }
    return 'Rp ${grouped.map((g) => g.split('').reversed.join()).toList().reversed.join('.')}';
  }

  int _parseAmount(dynamic v) {
    if (v == null) return 0;
    final s = v.toString().trim().replaceAll(',', '.');
    final cleaned = s.replaceAll(RegExp('[^0-9\.]'), '');
    final d = double.tryParse(cleaned);
    if (d != null) return d.round();
    final digits = s.replaceAll(RegExp('[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Dashboard'),
      body: Consumer<DashboardProvider>(
        builder: (context, dash, _) => RefreshIndicator(
          onRefresh: dash.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                if (dash.isLoading) const LinearProgressIndicator(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang!',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'Kontrol penuh kapanpun dan dimanapun.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CustomCard(
                  title: 'Total Pendapatan Hari Ini',
                  subtitle: _formatCurrency(dash.totalRevenueToday),
                  icon: Icons.attach_money,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Flexible(
                        child: CustomCard(
                          title: 'Saldo Tunai',
                          subtitle: _formatCurrency(dash.saldoTunai),
                          icon: Icons.account_balance_wallet,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: CustomCard(
                          title: 'Saldo EDC',
                          subtitle: _formatCurrency(dash.saldoEdc),
                          icon: Icons.account_balance_wallet,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                CustomCard(
                  title: 'Total Transaksi Hari ini',
                  subtitle: '${dash.totalTransactionsToday} Transaksi',
                  icon: Icons.note_alt,
                ),
                const SizedBox(height: 8),
                CustomCard(
                  title: 'Kasir Aktif',
                  subtitle: '${dash.activeKasir} Kasir',
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),

                // Recent transactions table
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 28,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColor.darkTextSecondary
                            : AppColor.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Transaksi Terbaru',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColor.darkTextPrimary
                              : AppColor.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('No. Trx')),
                      DataColumn(label: Text('Agent')),
                      DataColumn(label: Text('EDC')),
                      DataColumn(label: Text('Layanan')),
                      DataColumn(label: Text('Kasir')),
                      DataColumn(label: Text('Nominal')),
                      DataColumn(label: Text('Waktu')),
                    ],
                    rows: dash.recentTransactions.map((t) {
                      final trx =
                          t['transaction_number'] ??
                          t['transaction_no'] ??
                          t['id']?.toString() ??
                          '-';
                      final agent = t['agent_profile']?['agent_name'] ?? '-';
                      final edc =
                          t['edc_machine']?['name'] ??
                          t['edc_machine_name'] ??
                          '-';
                      final svc = t['service']?['name'] ?? '-';
                      final user = t['user']?['name'] ?? '-';
                      final amount = _formatCurrency(t['amount_int'] ?? 0);
                      final waktu = t['created_at'] ?? t['created_at'] ?? '-';
                      return DataRow(
                        cells: [
                          DataCell(Text(trx)),
                          DataCell(Text(agent)),
                          DataCell(Text(edc)),
                          DataCell(Text(svc)),
                          DataCell(Text(user)),
                          DataCell(Text(amount)),
                          DataCell(Text(waktu)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 28,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColor.darkTextSecondary
                            : AppColor.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Trend Harian (7 Hari Terakhir)',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColor.darkTextPrimary
                              : AppColor.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Tanggal')),
                      DataColumn(label: Text('Jumlah Transaksi')),
                      DataColumn(label: Text('Revenue')),
                    ],
                    rows: dash.dailyTrend.map((trend) {
                      final date = trend['date'] ?? '-';
                      final count = trend['count']?.toString() ?? '0';
                      final revenue = _formatCurrency(
                        _parseAmount(trend['revenue']),
                      );
                      return DataRow(
                        cells: [
                          DataCell(Text(date)),
                          DataCell(Text(count)),
                          DataCell(Text(revenue)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 28,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColor.darkTextSecondary
                            : AppColor.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Top Layanan Berdasarkan Revenue',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColor.darkTextPrimary
                                    : AppColor.primary,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Layanan')),
                      DataColumn(label: Text('Jumlah')),
                      DataColumn(label: Text('Revenue')),
                    ],
                    rows: dash.topServicesByRevenue.map((service) {
                      final name = service['name'] ?? '-';
                      final count = service['count']?.toString() ?? '0';
                      final revenue = _formatCurrency(
                        service['revenue_int'] ?? 0,
                      );
                      return DataRow(
                        cells: [
                          DataCell(Text(name)),
                          DataCell(Text(count)),
                          DataCell(Text(revenue)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 28,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColor.darkTextSecondary
                            : AppColor.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Top Layanan Berdasarkan Volume',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColor.darkTextPrimary
                                    : AppColor.primary,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Layanan')),
                      DataColumn(label: Text('Jumlah')),
                      DataColumn(label: Text('Revenue')),
                    ],
                    rows: dash.topServicesByVolume.map((service) {
                      final name = service['name'] ?? '-';
                      final count = service['count']?.toString() ?? '0';
                      final revenue = _formatCurrency(
                        service['revenue_int'] ?? 0,
                      );
                      return DataRow(
                        cells: [
                          DataCell(Text(name)),
                          DataCell(Text(count)),
                          DataCell(Text(revenue)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 28,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColor.darkTextSecondary
                            : AppColor.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Akses Cepat',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColor.darkTextPrimary
                              : AppColor.primary,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                //akses cepat grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _QuickAccessCard(
                      title: 'Admin Bank',
                      icon: Icons.work,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BankFeeManagementScreen(),
                        ),
                      ),
                    ),
                    _QuickAccessCard(
                      title: 'Biaya Layanan',
                      icon: Icons.report,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ServiceFeeManagementScreen(),
                        ),
                      ),
                    ),
                    _QuickAccessCard(
                      title: 'Manajemen Layanan',
                      icon: Icons.schedule,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ServiceManagementScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                // Add spacing at the bottom to ensure content doesn't overlap with the navigation bar
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _QuickAccessCard({required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: AppColor.primary),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
