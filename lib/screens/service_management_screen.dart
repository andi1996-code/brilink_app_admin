import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:brilink_app_admin/core/constants/app_color.dart';
import '../providers/service_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_konfirmasi_dialog.dart';
import '../widgets/custom_input_dialog.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({Key? key}) : super(key: key);

  @override
  State<ServiceManagementScreen> createState() =>
      _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ServiceProvider>(context, listen: false).fetchServices();
    });
  }

  Future<void> _showForm({Map<String, dynamic>? existing}) async {
    // Use the single-field stylish input dialog sequentially
    final name = await showCustomInputDialog(
      context,
      title: existing == null ? 'Buat Layanan' : 'Edit Layanan',
      hintText: 'Nama layanan',
      inputType: TextInputType.text,
      initialValue: existing?['name'] ?? '',
      okText: 'Lanjut',
      cancelText: 'Batal',
      icon: Icons.room_service, // small contextual icon
      helperText: 'Isi nama layanan',
    );
    if (name == null) return; // cancelled

    final category = await showCustomInputDialog(
      context,
      title: 'Kategori',
      hintText: 'Masukkan kategori',
      inputType: TextInputType.text,
      initialValue: existing?['category'] ?? '',
      okText: 'Lanjut',
      cancelText: 'Batal',
      icon: Icons.category,
      helperText: 'Contoh: Tagihan, Pulsa, Transfer',
    );
    if (category == null) return; // cancelled

    final description = await showCustomInputDialog(
      context,
      title: 'Deskripsi',
      hintText: 'Masukkan deskripsi layanan',
      inputType: TextInputType.multiline,
      initialValue: existing?['description'] ?? '',
      okText: 'Lanjut',
      cancelText: 'Batal',
      icon: Icons.description,
      helperText: 'Deskripsi singkat tentang layanan',
    );
    if (description == null) return; // cancelled

    // For requires_target, we can use a simple yes/no dialog or assume based on category
    // For now, let's add a simple confirmation for requires_target
    bool requiresTarget = existing?['requires_target'] ?? false;
    final targetChoice = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Memerlukan Target?'),
        content: const Text(
          'Apakah layanan ini memerlukan nomor tujuan (seperti nomor telepon)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
    if (targetChoice == null) return; // cancelled
    requiresTarget = targetChoice;

    final payload = {
      'name': name.trim(),
      'category': category.trim(),
      'description': description.trim(),
      'requires_target': requiresTarget,
    };

    // For update, ensure we include existing values if not changed
    if (existing != null) {
      payload.addAll({
        'name': payload['name'] ?? existing['name'],
        'category': payload['category'] ?? existing['category'],
        'description': payload['description'] ?? existing['description'] ?? '',
        'requires_target':
            payload['requires_target'] ?? existing['requires_target'] ?? false,
      });
    }

    final provider = Provider.of<ServiceProvider>(context, listen: false);
    if (existing == null) {
      await provider.createService(payload);
    } else {
      await provider.updateService(existing['id'], payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final listBottomPadding = MediaQuery.of(context).viewPadding.bottom + 96.0;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Manajemen Layanan'),
      backgroundColor: colorScheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Layanan',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        backgroundColor: AppColor.primary,
        elevation: 8,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Consumer<ServiceProvider>(
        builder: (context, svc, _) {
          if (svc.isLoading) {
            return Center(
              child: CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation(colorScheme.primary),
              ),
            );
          }
          if (svc.error != null) {
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
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Error: ${svc.error}'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      onPressed: svc.fetchServices,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (svc.services.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.room_service,
                      size: 80,
                      color: colorScheme.onBackground.withOpacity(0.28),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Belum ada layanan',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tekan tombol "+" untuk menambahkan layanan baru.',
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
              itemCount: svc.services.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final item = svc.services[i];
                return Card(
                  color: colorScheme.surface,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: colorScheme.primary.withOpacity(0.08),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showForm(existing: item),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: colorScheme.primary.withOpacity(
                              0.08,
                            ),
                            child: Icon(
                              Icons.room_service,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] ?? '-',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Kategori: ${item['category'] ?? '-'}',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                ),
                                if (item['description'] != null &&
                                    item['description']
                                        .toString()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Deskripsi: ${item['description']}',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  'Memerlukan Target: ${item['requires_target'] == true ? 'Ya' : 'Tidak'}',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: colorScheme.primary),
                            onPressed: () => _showForm(existing: item),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: colorScheme.error),
                            onPressed: () async {
                              final ok = await showCustomKonfirmasiDialog(
                                context,
                                title: 'Konfirmasi Hapus',
                                content:
                                    'Yakin ingin menghapus layanan "${item['name']}"?',
                                confirmText: 'Hapus',
                                cancelText: 'Batal',
                                confirmIsDestructive: true,
                                icon: Icons.delete_forever,
                              );

                              if (ok == true) {
                                await Provider.of<ServiceProvider>(
                                  context,
                                  listen: false,
                                ).deleteService(item['id']);
                              }
                            },
                            tooltip: 'Hapus',
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
