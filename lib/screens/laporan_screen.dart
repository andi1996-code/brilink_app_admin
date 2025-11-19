import 'package:brilink_app_admin/core/constants/app_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../../providers/report_provider.dart';
import '../../providers/edc_provider.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  DateTimeRange? _selectedDateRange;
  String _selectedReportType = 'daily';
  int _perPage = 30;

  // simple rupiah formatter: extracts digits, groups thousands with '.' and prefixes 'Rp '
  String _formatRupiah(dynamic v) {
    if (v == null) return 'Rp 0';
    final s = v.toString().trim();

    // Normalize comma decimal separator to dot
    String normalized = s.replaceAll(',', '.');

    // Keep only digits and dots
    String cleaned = normalized.replaceAll(RegExp('[^0-9\.]'), '');

    // If there are multiple dots (e.g. thousand separators), keep the last as decimal separator
    if (cleaned.contains('.')) {
      final lastDot = cleaned.lastIndexOf('.');
      final intPart = cleaned.substring(0, lastDot).replaceAll('.', '');
      final fracPart = cleaned.substring(lastDot + 1);
      cleaned = '$intPart${fracPart.isNotEmpty ? '.$fracPart' : ''}';
    }

    // Try to parse as double (handles values like 100000.00)
    final asDouble = double.tryParse(cleaned);
    int value;
    if (asDouble != null) {
      value = asDouble.round();
    } else {
      // Fallback: extract digits only
      final digitsOnly = s.replaceAll(RegExp('[^0-9]'), '');
      value = int.tryParse(digitsOnly) ?? 0;
    }

    final formatted = value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    );
    return 'Rp $formatted';
  }

  // Parse amount-like values (e.g. "100000.00") into integer rupiah value.
  int _parseAmountToInt(dynamic v) {
    if (v == null) return 0;
    final s = v.toString().trim().replaceAll(',', '.');
    // keep digits and dot
    final cleaned = s.replaceAll(RegExp('[^0-9\.]'), '');
    // try double parse and round
    final d = double.tryParse(cleaned);
    if (d != null) return d.round();
    // fallback to digits only
    final digits = s.replaceAll(RegExp('[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    // No-op here; provider fetching happens when user taps 'Tampilkan Laporan'
  }

  void _selectDateRange(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange:
          _selectedDateRange ?? DateTimeRange(start: now, end: now),
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  final Map<String, String> _reportTypes = {
    'daily': 'Laporan Harian',
    'weekly': 'Laporan Mingguan',
    'monthly': 'Laporan Bulanan',
    'custom': 'Custom Laporan',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Laporan'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih Jenis Laporan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              child: DropdownButton<String>(
                value: _selectedReportType,
                isExpanded: true,
                underline: const SizedBox(),
                style:
                    (Theme.of(context).textTheme.bodyLarge ?? const TextStyle())
                        .copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                items: _reportTypes.entries
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(
                          e.value,
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : null,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedReportType = newValue;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Pilih Rentang Tanggal',
              icon: Icons.date_range,
              onPressed: () => _selectDateRange(context),
              backgroundColor: AppColor.primary,
              textColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Theme.of(context).colorScheme.onPrimary,
              height: 50,
              borderRadius: 8,
            ),
            const SizedBox(height: 16),
            if (_selectedDateRange != null)
              Text(
                'Dari: ${_selectedDateRange!.start.toLocal()}\nKe: ${_selectedDateRange!.end.toLocal()}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            const SizedBox(height: 12),
            Center(
              child: CustomButton(
                text: 'Tampilkan Laporan',
                onPressed: () async {
                  final rp = Provider.of<ReportProvider>(
                    context,
                    listen: false,
                  );
                  await rp.fetchReports(
                    range: _selectedReportType,
                    perPage: _perPage,
                    customRange: _selectedReportType == 'custom'
                        ? _selectedDateRange
                        : null,
                  );

                  // prefetch referenced EDC machines so names are available when the sheet opens
                  try {
                    final edcProv = Provider.of<EdcProvider>(
                      context,
                      listen: false,
                    );
                    final ids = rp.transactions
                        .map(
                          (t) =>
                              t['edc_machine_id'] ??
                              t['machine_id'] ??
                              t['edc_id'],
                        )
                        .where((e) => e != null)
                        .map((e) => int.tryParse(e.toString()))
                        .where((i) => i != null)
                        .map((i) => i!)
                        .toSet();

                    await Future.wait(
                      ids.map((id) async {
                        if (!edcProv.machines.any(
                          (m) => m['id']?.toString() == id.toString(),
                        )) {
                          await edcProv.fetchMachineById(id);
                        }
                      }),
                    );
                  } catch (_) {}
                  if (!mounted) return;
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) => Consumer<ReportProvider>(
                      builder: (c, rp, _) {
                        if (rp.isLoading)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        if (rp.error != null)
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('Gagal: ${rp.error}'),
                          );

                        final s = rp.summary;
                        return SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header with back button
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      icon: const Icon(Icons.close),
                                      tooltip: 'Tutup',
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Hasil Laporan',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Period info
                                if (rp.period.isNotEmpty) ...[
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Periode',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            rp.period['name']?.toString() ??
                                                '-',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          Text(
                                            '${rp.period['start_date']} - ${rp.period['end_date']}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Summary cards
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Total Revenue',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                _formatRupiah(
                                                  s['total_revenue'],
                                                ),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Transaksi',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                s['total_transactions']
                                                        ?.toString() ??
                                                    '0',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Net Profit',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                _formatRupiah(
                                                  s['total_net_profit'],
                                                ),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Avg Transaction',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                _formatRupiah(
                                                  s['avg_transaction_amount'],
                                                ),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Cash flow summary
                                if (s['cash_in'] != null ||
                                    s['cash_out'] != null) ...[
                                  const SizedBox(height: 12),
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Cash Flow',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Cash In',
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodySmall,
                                                  ),
                                                  Text(
                                                    _formatRupiah(s['cash_in']),
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodyMedium,
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Cash Out',
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodySmall,
                                                  ),
                                                  Text(
                                                    _formatRupiah(
                                                      s['cash_out'],
                                                    ),
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodyMedium,
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Net',
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodySmall,
                                                  ),
                                                  Text(
                                                    _formatRupiah(
                                                      s['net_cash_flow'],
                                                    ),
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodyMedium,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],

                                // Agent Performance
                                if (rp.agentPerformance.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'Performa Agen',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  SizedBox(
                                    height: 120,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemBuilder: (c, idx) {
                                        final agent = rp.agentPerformance[idx];
                                        return Card(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  agent['agent_name']
                                                          ?.toString() ??
                                                      '-',
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  _formatRupiah(
                                                    agent['revenue'],
                                                  ),
                                                ),
                                                Text(
                                                  '${agent['transaction_count']} trx',
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 8),
                                      itemCount: rp.agentPerformance.length,
                                    ),
                                  ),
                                ],

                                // EDC Performance
                                if (rp.edcPerformance.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'Performa EDC',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  SizedBox(
                                    height: 120,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemBuilder: (c, idx) {
                                        final edc = rp.edcPerformance[idx];
                                        return Card(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  edc['name']?.toString() ??
                                                      '-',
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  _formatRupiah(edc['revenue']),
                                                ),
                                                Text(
                                                  '${edc['transaction_count']} trx',
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 8),
                                      itemCount: rp.edcPerformance.length,
                                    ),
                                  ),
                                ],

                                // Service Breakdown
                                if (rp.serviceBreakdown.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'Breakdown Layanan',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  SizedBox(
                                    height: 140,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemBuilder: (c, idx) {
                                        final service =
                                            rp.serviceBreakdown[idx];
                                        return Card(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  service['name']?.toString() ??
                                                      '-',
                                                ),
                                                Text(
                                                  service['category']
                                                          ?.toString() ??
                                                      '-',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  _formatRupiah(
                                                    service['revenue'],
                                                  ),
                                                ),
                                                Text(
                                                  '${service['transaction_count']} trx',
                                                ),
                                                Text(
                                                  'Profit: ${_formatRupiah(service['net_profit_total'])}',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 8),
                                      itemCount: rp.serviceBreakdown.length,
                                    ),
                                  ),
                                ],

                                // Daily Breakdown (Series)
                                if (rp.series.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'Breakdown Harian',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  SizedBox(
                                    height: 120,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemBuilder: (c, idx) {
                                        final it = rp.series[idx];
                                        return Card(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  it['date']?.toString() ?? '-',
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  _formatRupiah(it['revenue']),
                                                ),
                                                Text(
                                                  '${it['transaction_count']?.toString() ?? '0'} trx',
                                                ),
                                                Text(
                                                  _formatRupiah(
                                                    it['net_profit'],
                                                  ),
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 8),
                                      itemCount: rp.series.length,
                                    ),
                                  ),
                                ],

                                // Transactions table
                                if (rp.transactions.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'Transaksi',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(label: Text('EDC')),
                                        DataColumn(label: Text('No. Trx')),
                                        DataColumn(label: Text('Kasir')),
                                        DataColumn(label: Text('Layanan')),
                                        DataColumn(label: Text('No Tujuan')),
                                        DataColumn(label: Text('Nominal')),
                                        DataColumn(label: Text('Fee')),
                                        DataColumn(label: Text('Admin')),
                                        DataColumn(label: Text('Tambahan')),
                                        DataColumn(label: Text('Total')),
                                        DataColumn(label: Text('Pelanggan')),
                                        DataColumn(label: Text('Waktu')),
                                      ],
                                      rows: rp.transactions.map((item) {
                                        final edcIdRaw =
                                            item['edc_machine_id'] ??
                                            item['machine_id'] ??
                                            item['edc_id'];
                                        final edcId = edcIdRaw == null
                                            ? null
                                            : int.tryParse(edcIdRaw.toString());
                                        final trxNo =
                                            item['transaction_number'] ??
                                            item['transaction_no'] ??
                                            item['no_trx'] ??
                                            item['trx_no'] ??
                                            item['id']?.toString() ??
                                            '-';
                                        final cashier =
                                            item['user']?['name'] ??
                                            item['kasir']?['name'] ??
                                            item['cashier'] ??
                                            '-';
                                        final layanan =
                                            item['service']?['name'] ??
                                            item['service_name'] ??
                                            item['layanan'] ??
                                            '-';
                                        final tujuan =
                                            item['destination'] ??
                                            item['no_tujuan'] ??
                                            item['target'] ??
                                            item['nomor_tujuan'] ??
                                            '-';
                                        final nominal = _formatRupiah(
                                          item['amount'] ??
                                              item['nominal'] ??
                                              item['price'],
                                        );
                                        final fee = _formatRupiah(
                                          item['service_fee'] ?? item['fee'],
                                        );
                                        final adminFee = _formatRupiah(
                                          item['bank_fee'] ??
                                              item['admin_fee'] ??
                                              item['admin'],
                                        );
                                        final tambahan = _formatRupiah(
                                          item['extra_fee'] ??
                                              item['additional_fee'] ??
                                              item['tambahan'] ??
                                              0,
                                        );
                                        // compute total if provided, otherwise fallback to amount + fees when possible
                                        String totalStr;
                                        if (item['total'] != null) {
                                          totalStr = _formatRupiah(
                                            item['total'],
                                          );
                                        } else {
                                          // parse numeric parts properly (handles decimal strings)
                                          final a = _parseAmountToInt(
                                            item['amount'] ?? '0',
                                          );
                                          final f = _parseAmountToInt(
                                            item['service_fee'] ??
                                                item['fee'] ??
                                                '0',
                                          );
                                          final b = _parseAmountToInt(
                                            item['bank_fee'] ??
                                                item['admin_fee'] ??
                                                '0',
                                          );
                                          final add = _parseAmountToInt(
                                            item['extra_fee'] ??
                                                item['additional_fee'] ??
                                                item['tambahan'] ??
                                                '0',
                                          );
                                          totalStr = _formatRupiah(
                                            a + f + b + add,
                                          );
                                        }
                                        final pelanggan =
                                            item['customer_name'] ??
                                            item['pelanggan'] ??
                                            item['customer'] ??
                                            '-';
                                        final waktu =
                                            item['created_at'] ??
                                            item['waktu'] ??
                                            item['date'] ??
                                            '-';

                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Consumer<EdcProvider>(
                                                builder: (c, edcProv, _) {
                                                  if (edcId == null)
                                                    return const Text('-');
                                                  if (edcProv.isFetchingId(
                                                    edcId,
                                                  ))
                                                    return const Text(
                                                      'Memuat...',
                                                    );
                                                  final name = edcProv
                                                      .findMachineName(edcId);
                                                  if (name == '-' ||
                                                      name.isEmpty)
                                                    return Text('ID $edcId');
                                                  return Text(name);
                                                },
                                              ),
                                            ),
                                            DataCell(Text(trxNo.toString())),
                                            DataCell(Text(cashier)),
                                            DataCell(Text(layanan)),
                                            DataCell(Text(tujuan)),
                                            DataCell(Text(nominal)),
                                            DataCell(Text(fee)),
                                            DataCell(Text(adminFee)),
                                            DataCell(Text(tambahan)),
                                            DataCell(Text(totalStr)),
                                            DataCell(Text(pelanggan)),
                                            DataCell(Text(waktu.toString())),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],

                                // Add bottom padding
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                backgroundColor: AppColor.primary,
                height: 50,
                borderRadius: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
