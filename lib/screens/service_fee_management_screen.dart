import 'package:brilink_app_admin/core/constants/app_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/service_fee_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_input_dialog.dart';
import '../widgets/custom_konfirmasi_dialog.dart';
import '../providers/service_provider.dart';

class ServiceFeeManagementScreen extends StatefulWidget {
  const ServiceFeeManagementScreen({Key? key}) : super(key: key);

  @override
  State<ServiceFeeManagementScreen> createState() =>
      _ServiceFeeManagementScreenState();
}

class _ServiceFeeManagementScreenState
    extends State<ServiceFeeManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure both fees and services are fetched when this screen opens.
      Provider.of<ServiceFeeProvider>(context, listen: false).fetchFees();
      Provider.of<ServiceProvider>(context, listen: false).fetchServices();
    });
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return 'Rp 0';
    if (value is num) {
      final intVal = value is double ? value.round() : value.toInt();
      final s = intVal.toString();
      final chars = s.split('').reversed.toList();
      final grouped = <String>[];
      for (var i = 0; i < chars.length; i += 3) {
        final end = (i + 3 > chars.length) ? chars.length : i + 3;
        grouped.add(chars.sublist(i, end).join());
      }
      final formatted = grouped
          .map((g) => g.split('').reversed.join())
          .toList()
          .reversed
          .join('.');
      return 'Rp $formatted';
    }

    // Otherwise treat as String: try parsing as decimal first
    final raw = value is String ? value.trim() : value.toString();
    if (raw.isEmpty) return 'Rp 0';

    // try to parse as double (handles '2000000.00')
    final normalized = raw.replaceAll(',', '');
    final maybeDouble = double.tryParse(normalized);
    int intVal;
    if (maybeDouble != null) {
      intVal = maybeDouble.round();
    } else {
      // fallback: remove non-digits
      final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) return 'Rp 0';
      intVal = int.tryParse(digits) ?? 0;
    }

    // Debug log to help identify incorrect magnitudes coming from data
    // ignore: avoid_print
    print('[formatCurrency] input="$value" intVal=$intVal');

    final s = intVal.toString();
    final chars = s.split('').reversed.toList();
    final grouped = <String>[];
    for (var i = 0; i < chars.length; i += 3) {
      final end = (i + 3 > chars.length) ? chars.length : i + 3;
      grouped.add(chars.sublist(i, end).join());
    }
    final formatted = grouped
        .map((g) => g.split('').reversed.join())
        .toList()
        .reversed
        .join('.');
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );
    final feeProvider = Provider.of<ServiceFeeProvider>(context, listen: false);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Manajemen Biaya Layanan'),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showCreateDialog(context, serviceProvider, feeProvider),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Biaya',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        backgroundColor: AppColor.primary,
        elevation: 8,
      ),
      body: Consumer<ServiceFeeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation(colorScheme.primary),
              ),
            );
          }

          if (provider.error != null) {
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
                    const SizedBox(height: 12),
                    Text(
                      'Gagal memuat data',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Error: ${provider.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: provider.fetchFees,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.fees.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 80,
                      color: colorScheme.onBackground.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada konfigurasi biaya layanan',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tambahkan konfigurasi biaya untuk layanan tertentu.',
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: provider.fees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final fee = provider.fees[i];
              return Card(
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Polished layout: leading avatar, title, chips for range & fee, divider and compact actions
                      Consumer<ServiceProvider>(
                        builder: (ctx, svcProv, _) {
                          String name = '-';
                          try {
                            if (fee['service_name'] != null &&
                                fee['service_name']
                                    .toString()
                                    .trim()
                                    .isNotEmpty) {
                              name = fee['service_name'].toString();
                            } else if (fee['service'] is Map &&
                                (fee['service']['name'] ?? '')
                                    .toString()
                                    .trim()
                                    .isNotEmpty) {
                              name = fee['service']['name'].toString();
                            } else if (svcProv.isFetchingId(
                              fee['service_id'],
                            )) {
                              name = 'Memuat...';
                            } else {
                              final found = svcProv.findServiceName(
                                fee['service_id'],
                              );
                              if (found != '-' && found.trim().isNotEmpty) {
                                name = found;
                              } else if (fee['service_id'] != null) {
                                name = 'ID ${fee['service_id']}';
                              }
                            }
                          } catch (_) {}
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surfaceVariant,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            'Range: ${_formatCurrency(fee['min_amount'])} — ${_formatCurrency(fee['max_amount'])}',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            'Fee: ${_formatCurrency(fee['fee'])}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme
                                                      .onPrimaryContainer,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      // Compact action buttons
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () async {
                                // reuse existing edit flow
                                final services = Provider.of<ServiceProvider>(
                                  context,
                                  listen: false,
                                ).services;
                                int? sel = fee['service_id'] as int?;
                                final chosenService = await showDialog<int?>(
                                  context: context,
                                  builder: (ctx) {
                                    int? localSel = sel;
                                    return StatefulBuilder(
                                      builder: (ctx2, setState) {
                                        return AlertDialog(
                                          title: const Text('Pilih Layanan'),
                                          content: SizedBox(
                                            width: double.maxFinite,
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: services.length,
                                              itemBuilder: (c, i) {
                                                final s = services[i];
                                                return RadioListTile<int>(
                                                  value: s['id'] as int,
                                                  groupValue: localSel,
                                                  title: Text(s['name'] ?? '-'),
                                                  subtitle: Text(
                                                    s['category'] ?? '',
                                                  ),
                                                  onChanged: (v) => setState(
                                                    () => localSel = v,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(null),
                                              child: const Text('Batal'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.of(
                                                ctx,
                                              ).pop(localSel),
                                              child: const Text('Lanjut'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                );
                                if (chosenService == null) return;

                                final minInput = await showCustomInputDialog(
                                  context,
                                  title: 'Min Amount',
                                  hintText: 'Masukkan minimum',
                                  inputType: TextInputType.number,
                                  initialValue: fee['min_amount']?.toString(),
                                  okText: 'Lanjut',
                                  cancelText: 'Batal',
                                  formatRupiah: true,
                                );
                                if (minInput == null) return;

                                final maxInput = await showCustomInputDialog(
                                  context,
                                  title: 'Max Amount',
                                  hintText: 'Masukkan maksimum',
                                  inputType: TextInputType.number,
                                  initialValue: fee['max_amount']?.toString(),
                                  okText: 'Lanjut',
                                  cancelText: 'Batal',
                                  formatRupiah: true,
                                );
                                if (maxInput == null) return;

                                final feeInput = await showCustomInputDialog(
                                  context,
                                  title: 'Fee',
                                  hintText: 'Masukkan biaya',
                                  inputType: TextInputType.number,
                                  initialValue: fee['fee']?.toString(),
                                  okText: 'Simpan',
                                  cancelText: 'Batal',
                                );
                                if (feeInput == null) return;

                                final minClean = minInput.replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                );
                                final maxClean = maxInput.replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                );
                                final feeClean = feeInput.replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                );
                                final minVal = int.tryParse(minClean) ?? 0;
                                final maxVal = int.tryParse(maxClean) ?? 0;
                                final feeVal = int.tryParse(feeClean) ?? 0;

                                if (minVal <= 0 ||
                                    maxVal <= 0 ||
                                    feeVal <= 0 ||
                                    minVal > maxVal) {
                                  await showDialog<void>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Input tidak valid'),
                                      content: const Text(
                                        'Periksa nilai min, max, dan fee. Pastikan min <= max dan semua nilai > 0.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }

                                final payload = {
                                  'service_id': chosenService,
                                  'min_amount': minVal,
                                  'max_amount': maxVal,
                                  'fee': feeVal,
                                };
                                await Provider.of<ServiceFeeProvider>(
                                  context,
                                  listen: false,
                                ).updateFee(fee['id'], payload);
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit'),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () async {
                                final ok = await showCustomKonfirmasiDialog(
                                  context,
                                  title: 'Konfirmasi Hapus',
                                  content:
                                      'Yakin ingin menghapus biaya ID ${fee['id']}?',
                                  confirmText: 'Hapus',
                                  cancelText: 'Batal',
                                  confirmIsDestructive: true,
                                );
                                if (ok == true) {
                                  await Provider.of<ServiceFeeProvider>(
                                    context,
                                    listen: false,
                                  ).deleteFee(fee['id']);
                                }
                              },
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Hapus'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateDialog(
    BuildContext context,
    ServiceProvider svcProv,
    ServiceFeeProvider feeProv,
  ) async {
    // If services not yet loaded (e.g., app restarted), try fetching once.
    if (svcProv.services.isEmpty) {
      await svcProv.fetchServices();
    }

    if (svcProv.services.isEmpty) {
      // Inform user to create a service first
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tidak ada layanan'),
          content: const Text(
            'Silakan buat layanan terlebih dahulu sebelum menambahkan biaya.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Choose service_id via dialog
    final services = svcProv.services;
    int? selectedServiceId = services.isNotEmpty
        ? services.first['id'] as int?
        : null;
    final chosen = await showDialog<int?>(
      context: context,
      builder: (ctx) {
        int? sel = selectedServiceId;
        return StatefulBuilder(
          builder: (ctx2, setState) {
            return AlertDialog(
              title: const Text('Pilih Layanan'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: services.length,
                  itemBuilder: (c, i) {
                    final s = services[i];
                    return RadioListTile<int>(
                      value: s['id'] as int,
                      groupValue: sel,
                      title: Text(s['name'] ?? '-'),
                      // subtitle: Text(s['category'] ?? ''),
                      onChanged: (v) => setState(() => sel = v),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(sel),
                  child: const Text('Lanjut'),
                ),
              ],
            );
          },
        );
      },
    );
    if (chosen == null) return;

    final minInput = await showCustomInputDialog(
      context,
      title: 'Min Amount',
      hintText: 'Masukkan minimum (contoh 500001)',
      inputType: TextInputType.number,
      okText: 'Lanjut',
      cancelText: 'Batal',
      formatRupiah: true,
    );
    if (minInput == null) return;

    final maxInput = await showCustomInputDialog(
      context,
      title: 'Max Amount',
      hintText: 'Masukkan maksimum (contoh 1000000)',
      inputType: TextInputType.number,
      okText: 'Lanjut',
      cancelText: 'Batal',
      formatRupiah: true,
    );
    if (maxInput == null) return;

    final feeInput = await showCustomInputDialog(
      context,
      title: 'Fee',
      hintText: 'Masukkan biaya (contoh 1500)',
      inputType: TextInputType.number,
      okText: 'Simpan',
      cancelText: 'Batal',
    );
    if (feeInput == null) return;

    final minClean = minInput.replaceAll(RegExp(r'[^0-9]'), '');
    final maxClean = maxInput.replaceAll(RegExp(r'[^0-9]'), '');
    final feeClean = feeInput.replaceAll(RegExp(r'[^0-9]'), '');
    final minVal = int.tryParse(minClean) ?? 0;
    final maxVal = int.tryParse(maxClean) ?? 0;
    final feeVal = int.tryParse(feeClean) ?? 0;

    if (minVal <= 0 || maxVal <= 0 || feeVal <= 0 || minVal > maxVal) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Input tidak valid'),
          content: const Text(
            'Periksa nilai min, max, dan fee. Pastikan min <= max dan semua nilai > 0.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final payload = {
      'service_id': chosen,
      'min_amount': minVal,
      'max_amount': maxVal,
      'fee': feeVal,
    };

    await feeProv.createFee(payload);
  }
}
