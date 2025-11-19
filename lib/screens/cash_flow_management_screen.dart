import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cash_flow_provider.dart';
import '../widgets/custom_input_dialog.dart';

class CashFlowManagementScreen extends StatefulWidget {
  const CashFlowManagementScreen({Key? key}) : super(key: key);

  @override
  State<CashFlowManagementScreen> createState() =>
      _CashFlowManagementScreenState();
}

class _CashFlowManagementScreenState extends State<CashFlowManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CashFlowProvider>(context, listen: false).fetchCashFlows();
    });
  }

  // Helper to safely convert dynamic id values to int?
  int? _toIntNullable(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<CashFlowProvider>(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Alur Kas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // collect type
          final type = await showModalBottomSheet<String>(
            context: context,
            builder: (ctx) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Cash In'),
                  onTap: () => Navigator.pop(ctx, 'cash_in'),
                ),
                ListTile(
                  title: const Text('Cash Out'),
                  onTap: () => Navigator.pop(ctx, 'cash_out'),
                ),
              ],
            ),
          );
          if (type == null) return;

          // Get agent profile ID - use default value 1 as shown in the curl example
          // This appears to be a fixed agent profile ID for the system
          int agentProfileId = 1;

          final source = await showCustomInputDialog(
            context,
            title: 'Sumber',
            hintText: 'Sumber (contoh: Setoran dari Pemilik)',
            inputType: TextInputType.text,
            formatRupiah: false,
            barrierDismissible: true,
          );
          if (source == null) return;

          final amountStr = await showCustomInputDialog(
            context,
            title: 'Jumlah',
            hintText: 'Masukkan nominal (tanpa titik)',
            inputType: TextInputType.number,
            formatRupiah: true,
            barrierDismissible: true,
          );
          if (amountStr == null) return;

          final description = await showCustomInputDialog(
            context,
            title: 'Deskripsi',
            hintText: 'Deskripsi (contoh: Setoran modal awal)',
            inputType: TextInputType.text,
            formatRupiah: false,
            barrierDismissible: true,
          );
          if (description == null) return;

          // Clean formatted amount (remove dots/commas) then parse to int
          final amountClean = amountStr.replaceAll(RegExp(r'[^0-9]'), '');
          final amount = int.tryParse(amountClean) ?? 0;
          final payload = {
            'type': type,
            'source': source,
            'amount': amount,
            'description': description,
          };
          final ok = await Provider.of<CashFlowProvider>(
            context,
            listen: false,
          ).createCashFlow(payload);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ok ? 'Berhasil menambah alur kas' : 'Gagal menambah',
              ),
            ),
          );
        },
        label: const Text('Tambah'),
        icon: const Icon(Icons.add),
      ),
      body: prov.isLoading && prov.items.isEmpty
          ? Center(
              child: CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            )
          : prov.error != null
          ? Center(child: Text('Error: ${prov.error}'))
          : prov.items.isEmpty
          ? Center(child: Text('Belum ada data alur kas'))
          : RefreshIndicator(
              onRefresh: () => Provider.of<CashFlowProvider>(
                context,
                listen: false,
              ).refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: prov.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final item = prov.items[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            item['type'] == 'cash_in'
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: item['type'] == 'cash_in'
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['source'] ?? '-',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['description'] ?? '',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                FutureBuilder<String>(
                                  future:
                                      Provider.of<CashFlowProvider>(
                                        context,
                                        listen: false,
                                      ).getAgentProfileName(
                                        _toIntNullable(
                                          item['agent_profile_id'],
                                        ),
                                      ),
                                  builder: (ctx, snap) {
                                    // If no agent_profile_id provided, don't render anything
                                    if (item['agent_profile_id'] == null)
                                      return const SizedBox.shrink();

                                    if (snap.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Text('Memuat...');
                                    }

                                    // On error or null data, hide the agent profile text
                                    if (snap.hasError || (snap.data == null)) {
                                      return const SizedBox.shrink();
                                    }

                                    // Otherwise show the resolved name
                                    return Text(snap.data!);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            Provider.of<CashFlowProvider>(
                              context,
                              listen: false,
                            ).formatAmount(item['amount']),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
