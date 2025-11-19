import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bank_fee_provider.dart';
import '../providers/service_provider.dart';
import '../providers/edc_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_input_dialog.dart';
import '../widgets/custom_konfirmasi_dialog.dart';

class BankFeeManagementScreen extends StatefulWidget {
  const BankFeeManagementScreen({super.key});

  @override
  State<BankFeeManagementScreen> createState() =>
      _BankFeeManagementScreenState();
}

class _BankFeeManagementScreenState extends State<BankFeeManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BankFeeProvider>(context, listen: false).fetchFees();
    });
  }

  // Return raw digits string for initialValue (e.g. "2500" for "2500.00")
  String _initialFeeValue(dynamic fee) {
    if (fee == null) return '';
    if (fee is num) {
      return fee is double ? fee.round().toString() : fee.toString();
    }
    final s = fee.toString();
    // Try parse as double first (handles '2500.00')
    final d = double.tryParse(s.replaceAll(',', ''));
    if (d != null) return d.round().toString();
    // Fallback: extract digits
    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    return digits;
  }

  String _formatCurrency(dynamic v) {
    if (v == null) return 'Rp 0';
    // Accept numeric or string like '2500.00'
    if (v is num) {
      final intVal = v is double ? v.round() : v.toInt();
      return _formatInt(intVal);
    }
    final raw = v is String ? v : v.toString();
    final normalized = raw.replaceAll(',', '');
    final maybeDouble = double.tryParse(normalized);
    if (maybeDouble != null) return _formatInt(maybeDouble.round());
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'Rp 0';
    return _formatInt(int.tryParse(digits) ?? 0);
  }

  String _formatInt(int val) {
    final s = val.toString();
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
    final provider = Provider.of<BankFeeProvider>(context);
    final svcProv = Provider.of<ServiceProvider>(context, listen: false);
    final edcProv = Provider.of<EdcProvider>(context, listen: false);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Manajemen Biaya Bank'),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreate(context, svcProv, edcProv, provider),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
          ? Center(child: Text('Error: ${provider.error}'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.fees.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final f = provider.fees[i];
                return Card(
                  child: ListTile(
                    // Show EDC / Service names instead of exposing raw IDs and
                    // allow UI to update when providers fetch data.
                    title: Consumer<EdcProvider>(
                      builder: (ctx, edcProvider, _) {
                        String edcName = '-';
                        try {
                          if (f['edc_name'] != null &&
                              f['edc_name'].toString().trim().isNotEmpty) {
                            edcName = f['edc_name'].toString();
                          } else if (f['edc_machine'] is Map &&
                              (f['edc_machine']['name'] ?? '')
                                  .toString()
                                  .trim()
                                  .isNotEmpty) {
                            edcName = f['edc_machine']['name'].toString();
                          } else if (edcProvider.isFetchingId(
                            f['edc_machine_id'],
                          )) {
                            edcName = 'Memuat...';
                          } else {
                            final found = edcProvider.findMachineName(
                              f['edc_machine_id'],
                            );
                            if (found != '-' && found.trim().isNotEmpty) {
                              edcName = found;
                            } else if (f['edc_machine_id'] != null) {
                              edcName = 'ID ${f['edc_machine_id']}';
                            }
                          }
                        } catch (_) {}
                        return Text(edcName);
                      },
                    ),
                    subtitle: Consumer<ServiceProvider>(
                      builder: (ctx, svcProvider, _) {
                        String svcName = '-';
                        try {
                          if (f['service_name'] != null &&
                              f['service_name'].toString().trim().isNotEmpty) {
                            svcName = f['service_name'].toString();
                          } else if (f['service'] is Map &&
                              (f['service']['name'] ?? '')
                                  .toString()
                                  .trim()
                                  .isNotEmpty) {
                            svcName = f['service']['name'].toString();
                          } else {
                            final found = svcProvider.findServiceName(
                              f['service_id'],
                            );
                            if (found != '-' && found.trim().isNotEmpty) {
                              svcName = found;
                            } else if (f['service_id'] != null) {
                              svcName = 'ID ${f['service_id']}';
                            }
                          }
                        } catch (_) {}
                        return Text('Layanan: $svcName');
                      },
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_formatCurrency(f['fee'])),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            // pick edc
                            final edcChosen = await showDialog<int?>(
                              context: context,
                              builder: (ctx) {
                                int? sel = f['edc_machine_id'] as int?;
                                final list = edcProv.machines;
                                return StatefulBuilder(
                                  builder: (c, setState) {
                                    return AlertDialog(
                                      title: const Text('Pilih EDC'),
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: list.length,
                                          itemBuilder: (c, idx) {
                                            final e = list[idx];
                                            return RadioListTile<int>(
                                              value: e['id'] as int,
                                              groupValue: sel,
                                              title: Text(e['name'] ?? '-'),
                                              onChanged: (v) =>
                                                  setState(() => sel = v),
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
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(sel),
                                          child: const Text('Lanjut'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                            if (edcChosen == null) return;

                            // pick service
                            final svcChosen = await showDialog<int?>(
                              context: context,
                              builder: (ctx) {
                                int? sel = f['service_id'] as int?;
                                final list = svcProv.services;
                                return StatefulBuilder(
                                  builder: (c, setState) {
                                    return AlertDialog(
                                      title: const Text('Pilih Layanan'),
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: list.length,
                                          itemBuilder: (c, idx) {
                                            final s = list[idx];
                                            return RadioListTile<int>(
                                              value: s['id'] as int,
                                              groupValue: sel,
                                              title: Text(s['name'] ?? '-'),
                                              onChanged: (v) =>
                                                  setState(() => sel = v),
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
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(sel),
                                          child: const Text('Lanjut'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                            if (svcChosen == null) return;

                            final feeInput = await showCustomInputDialog(
                              context,
                              title: 'Fee',
                              hintText: 'Masukkan biaya (contoh 2500)',
                              inputType: TextInputType.number,
                              initialValue: _initialFeeValue(f['fee']),
                              okText: 'Simpan',
                              cancelText: 'Batal',
                              formatRupiah: true,
                            );
                            if (feeInput == null) return;

                            final feeClean = feeInput.replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            );
                            final feeVal = int.tryParse(feeClean) ?? 0;
                            if (feeVal <= 0) return;

                            final payload = {
                              'edc_machine_id': edcChosen,
                              'service_id': svcChosen,
                              'fee': feeVal,
                            };

                            await Provider.of<BankFeeProvider>(
                              context,
                              listen: false,
                            ).updateFee(f['id'], payload);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            final ok = await showCustomKonfirmasiDialog(
                              context,
                              title: 'Konfirmasi Hapus',
                              content:
                                  'Yakin ingin menghapus biaya ID ${f['id']}?',
                              confirmText: 'Hapus',
                              cancelText: 'Batal',
                              confirmIsDestructive: true,
                            );
                            if (ok == true) {
                              await Provider.of<BankFeeProvider>(
                                context,
                                listen: false,
                              ).deleteFee(f['id']);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showCreate(
    BuildContext context,
    ServiceProvider svcProv,
    EdcProvider edcProv,
    BankFeeProvider prov,
  ) async {
    // Try to lazy-load missing reference data before blocking the user
    if (svcProv.services.isEmpty) {
      try {
        await svcProv.fetchServices();
      } catch (_) {}
    }
    if (edcProv.machines.isEmpty) {
      try {
        await edcProv.fetchMachines();
      } catch (_) {}
    }

    if (svcProv.services.isEmpty || edcProv.machines.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Data tidak lengkap'),
          content: const Text(
            'Pastikan EDC dan Layanan tersedia terlebih dahulu.',
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

    final edcChosen = await showDialog<int?>(
      context: context,
      builder: (ctx) {
        int? sel = edcProv.machines.isNotEmpty
            ? edcProv.machines.first['id'] as int?
            : null;
        final list = edcProv.machines;
        return StatefulBuilder(
          builder: (c, setState) {
            return AlertDialog(
              title: const Text('Pilih EDC'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (c, idx) {
                    final e = list[idx];
                    return RadioListTile<int>(
                      value: e['id'] as int,
                      groupValue: sel,
                      title: Text(e['name'] ?? '-'),
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
    if (edcChosen == null) return;

    final svcChosen = await showDialog<int?>(
      context: context,
      builder: (ctx) {
        int? sel = svcProv.services.isNotEmpty
            ? svcProv.services.first['id'] as int?
            : null;
        final list = svcProv.services;
        return StatefulBuilder(
          builder: (c, setState) {
            return AlertDialog(
              title: const Text('Pilih Layanan'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (c, idx) {
                    final s = list[idx];
                    return RadioListTile<int>(
                      value: s['id'] as int,
                      groupValue: sel,
                      title: Text(s['name'] ?? '-'),
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
    if (svcChosen == null) return;

    final feeInput = await showCustomInputDialog(
      context,
      title: 'Fee',
      hintText: 'Masukkan biaya (contoh 2500)',
      inputType: TextInputType.number,
      okText: 'Simpan',
      cancelText: 'Batal',
      formatRupiah: true,
    );
    if (feeInput == null) return;

    final feeClean = feeInput.replaceAll(RegExp(r'[^0-9]'), '');
    final feeVal = int.tryParse(feeClean) ?? 0;
    if (feeVal <= 0) return;

    final payload = {
      'edc_machine_id': edcChosen,
      'service_id': svcChosen,
      'fee': feeVal,
    };

    await Provider.of<BankFeeProvider>(
      context,
      listen: false,
    ).createFee(payload);
  }
}
