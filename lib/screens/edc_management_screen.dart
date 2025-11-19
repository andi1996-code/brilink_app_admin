import 'package:brilink_app_admin/core/constants/app_color.dart';
import 'package:brilink_app_admin/screens/edc_add_saldo_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/edc_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_konfirmasi_dialog.dart';
import '../widgets/custom_input_dialog.dart';

class EdcManagementScreen extends StatefulWidget {
  const EdcManagementScreen({Key? key}) : super(key: key);

  @override
  State<EdcManagementScreen> createState() => _EdcManagementScreenState();
}

class _EdcManagementScreenState extends State<EdcManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EdcProvider>(context, listen: false).fetchMachines();
    });
  }

  String _formatCurrencyString(String? value) {
    if (value == null || value.isEmpty) return 'Rp 0';
    final raw = value.toString().trim();

    // Try to parse as a decimal number first (handles '2000000.00')
    final normalized = raw.replaceAll(',', ''); // remove commas if any
    final doubleVal = double.tryParse(normalized);
    int intVal;
    if (doubleVal != null) {
      // value already in units with possible fractional part -> round
      intVal = doubleVal.round();
    } else {
      // fallback: remove any non-digit characters (for preformatted strings)
      final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) return 'Rp 0';
      intVal = int.tryParse(digits) ?? 0;
    }

    final s = intVal.toString();
    final chars = s.split('').reversed.toList();
    final grouped = <String>[];
    for (var i = 0; i < chars.length; i += 3) {
      final end = (i + 3 > chars.length) ? chars.length : i + 3;
      grouped.add(chars.sublist(i, end).join());
    }
    return 'Rp ${grouped.map((g) => g.split('').reversed.join()).toList().reversed.join('.')}';
  }

  Future<void> _showForm({Map<String, dynamic>? existing}) async {
    final name = await showCustomInputDialog(
      context,
      title: existing == null ? 'Buat Mesin EDC' : 'Edit Mesin EDC',
      hintText: 'Nama mesin',
      inputType: TextInputType.text,
      initialValue: existing?['name'] ?? '',
      okText: 'Lanjut',
      cancelText: 'Batal',
      icon: Icons.point_of_sale,
    );
    if (name == null) return;

    final bank = await showCustomInputDialog(
      context,
      title: 'Bank',
      hintText: 'Nama bank',
      inputType: TextInputType.text,
      initialValue: existing?['bank_name'] ?? '',
      okText: 'Lanjut',
      cancelText: 'Batal',
      icon: Icons.account_balance,
    );
    if (bank == null) return;

    final acc = await showCustomInputDialog(
      context,
      title: 'Nomor Rekening',
      hintText: 'Contoh: 1234567890',
      inputType: TextInputType.number,
      initialValue: existing?['account_number'] ?? '',
      okText: 'Lanjut',
      cancelText: 'Batal',
      icon: Icons.confirmation_num,
    );
    if (acc == null) return;

    final saldoInput = await showCustomInputDialog(
      context,
      title: 'Saldo Awal',
      hintText: 'Masukkan saldo (angka tanpa pemisah)',
      inputType: TextInputType.numberWithOptions(decimal: true),
      initialValue: existing?['saldo']?.toString() ?? '0.00',
      okText: 'Simpan',
      cancelText: 'Batal',
      icon: Icons.account_balance_wallet,
      helperText: 'Contoh: 1000000.00 untuk satu juta',
      formatRupiah: true,
    );
    if (saldoInput == null) return;

    final saldoClean = saldoInput.replaceAll(RegExp(r'[^0-9.]'), '');
    final saldo = double.tryParse(saldoClean) ?? 0.0;

    final payload = <String, dynamic>{
      'name': name.trim(),
      'bank_name': bank.trim(),
      'account_number': acc.trim(),
      'saldo': saldo,
    };

    // Jika sedang mengedit, pertahankan agent_profile_id lama jika ada
    if (existing != null && existing['agent_profile_id'] != null) {
      payload['agent_profile_id'] = existing['agent_profile_id'];
    }

    final provider = Provider.of<EdcProvider>(context, listen: false);
    if (existing == null) {
      await provider.createMachine(payload);
    } else {
      await provider.updateMachine(existing['id'], payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final listBottomPadding = MediaQuery.of(context).viewPadding.bottom + 96.0;
    return Scaffold(
      appBar: const CustomAppBar(title: 'Manajemen Mesin EDC'),
      backgroundColor: colorScheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah EDC',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        backgroundColor: AppColor.primary,
        elevation: 8,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Consumer<EdcProvider>(
        builder: (context, edc, _) {
          if (edc.isLoading) {
            return Center(
              child: CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation(colorScheme.primary),
              ),
            );
          }
          if (edc.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat data',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Error: ${edc.error}'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        edc.fetchMachines();
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (edc.machines.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.point_of_sale,
                      size: 80,
                      color: colorScheme.onBackground.withOpacity(0.28),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Belum ada mesin EDC',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tekan tombol "+" untuk menambahkan mesin baru.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: ListView.separated(
              padding: EdgeInsets.only(bottom: listBottomPadding),
              itemCount: edc.machines.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final item = edc.machines[i];

                return Card(
                  color: colorScheme.surface,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: colorScheme.primary.withOpacity(0.12),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showForm(existing: item),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  item['name'] ?? '-',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Icon(
                                Icons.confirmation_num,
                                size: 16,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item['account_number'] ?? '-',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatCurrencyString(
                                  item['saldo']?.toString(),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: colorScheme.primary,
                                ),
                                onPressed: () async {
                                  final ok = await Navigator.of(context)
                                      .push<bool?>(
                                        MaterialPageRoute(
                                          builder: (ctx) =>
                                              EdcAddSaldoScreen(machine: item),
                                        ),
                                      );
                                  if (ok == true) {
                                    // Refresh list after successful top-up
                                    Provider.of<EdcProvider>(
                                      context,
                                      listen: false,
                                    ).fetchMachines();
                                  }
                                },
                                tooltip: 'Tambah Saldo',
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: colorScheme.primary,
                                ),
                                onPressed: () => _showForm(existing: item),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: colorScheme.error,
                                ),
                                onPressed: () async {
                                  final ok = await showCustomKonfirmasiDialog(
                                    context,
                                    title: 'Konfirmasi Hapus',
                                    content:
                                        'Yakin ingin menghapus mesin "${item['name']}"?',
                                    confirmText: 'Hapus',
                                    cancelText: 'Batal',
                                    confirmIsDestructive: true,
                                    icon: Icons.delete_forever,
                                  );

                                  if (ok == true) {
                                    await Provider.of<EdcProvider>(
                                      context,
                                      listen: false,
                                    ).deleteMachine(item['id']);
                                  }
                                },
                                tooltip: 'Hapus',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
