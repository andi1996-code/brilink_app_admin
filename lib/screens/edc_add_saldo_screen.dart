import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/edc_provider.dart';
import '../core/app_navigator.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_alert.dart';
import '../widgets/custom_konfirmasi_dialog.dart';
import '../core/constants/app_color.dart';

class EdcAddSaldoScreen extends StatefulWidget {
  final Map<String, dynamic> machine;

  const EdcAddSaldoScreen({Key? key, required this.machine}) : super(key: key);

  @override
  State<EdcAddSaldoScreen> createState() => _EdcAddSaldoScreenState();
}

class _EdcAddSaldoScreenState extends State<EdcAddSaldoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  bool _isFormatting = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _amountController.addListener(_onAmountChanged);
    _amountController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    if (_isFormatting) return;
    _isFormatting = true;
    final raw = _amountController.text;
    final formatted = _formatRupiah(raw);
    if (formatted != raw) {
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    _isFormatting = false;
  }

  String _formatRupiah(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    final intVal = int.tryParse(digits) ?? 0;
    final s = intVal.toString();
    final chars = s.split('').reversed.toList();
    final grouped = <String>[];
    for (var i = 0; i < chars.length; i += 3) {
      final end = (i + 3 > chars.length) ? chars.length : i + 3;
      grouped.add(chars.sublist(i, end).join());
    }
    return grouped
        .map((g) => g.split('').reversed.join())
        .toList()
        .reversed
        .join('.');
  }

  String _formatCurrencyDisplay(dynamic value) {
    if (value == null) return 'Rp 0';
    try {
      final d = double.tryParse(value.toString());
      if (d != null) {
        final v = d.round();
        final s = v.toString();
        final chars = s.split('').reversed.toList();
        final grouped = <String>[];
        for (var i = 0; i < chars.length; i += 3) {
          final end = (i + 3 > chars.length) ? chars.length : i + 3;
          grouped.add(chars.sublist(i, end).join());
        }
        return 'Rp ${grouped.map((g) => g.split('').reversed.join()).toList().reversed.join('.')}';
      }
    } catch (_) {}
    return 'Rp 0';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amountClean = _amountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final amount = int.tryParse(amountClean) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih besar dari 0')),
      );
      return;
    }

    // Konfirmasi sebelum submit
    final formatted = _formatRupiah(amount.toString());
    final confirm = await showCustomKonfirmasiDialog(
      context,
      title: 'Konfirmasi Tambah Saldo',
      content:
          'Tambahkan saldo sebesar Rp $formatted ke mesin "${widget.machine['name']}"?',
      confirmText: 'Tambah',
      cancelText: 'Batal',
      confirmIsDestructive: false,
      confirmColor: AppColor.primary,
      icon: Icons.account_balance_wallet,
    );
    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    final prov = Provider.of<EdcProvider>(context, listen: false);
    final ok = await prov.addSaldo(
      widget.machine['id'],
      amount,
      showAlert: false,
    );
    setState(() => _isSubmitting = false);

    if (ok) {
      // Go back first, then show global alert on previous screen
      Navigator.of(context).pop(true);
      AppNavigator.showAlert(
        'Saldo berhasil ditambahkan',
        type: AlertType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final machine = widget.machine;
    return Scaffold(
      appBar: const CustomAppBar(title: 'Tambah Saldo Mesin EDC'),
      backgroundColor: theme.colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      machine['name'] ?? '-',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.account_balance, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(machine['bank_name'] ?? '-')),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.confirmation_num, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(machine['account_number'] ?? '-')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Saldo saat ini: ${_formatCurrencyDisplay(machine['saldo'])}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Masukkan nominal', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: false,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'Contoh: 100000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: _amountController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => _amountController.clear()),
                            ),
                    ),
                    validator: (v) {
                      final cleaned =
                          v?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                      if (cleaned.isEmpty) return 'Nominal tidak boleh kosong';
                      final n = int.tryParse(cleaned) ?? 0;
                      if (n <= 0) return 'Nominal harus lebih besar dari 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Tambah Saldo'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
