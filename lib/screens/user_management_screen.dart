import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_input_dialog.dart';
import '../widgets/custom_konfirmasi_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
    });
  }

  Future<void> _showCreateDialog(
    BuildContext context,
    UserProvider prov,
  ) async {
    final name = await showCustomInputDialog(
      context,
      title: 'Nama',
      hintText: 'Masukkan nama lengkap',
      okText: 'Lanjut',
      cancelText: 'Batal',
    );
    if (name == null) return;

    final email = await showCustomInputDialog(
      context,
      title: 'Email',
      hintText: 'Masukkan email',
      okText: 'Lanjut',
      cancelText: 'Batal',
      inputType: TextInputType.emailAddress,
    );
    if (email == null) return;

    final password = await showCustomInputDialog(
      context,
      title: 'Password',
      hintText: 'Masukkan password',
      okText: 'Simpan',
      cancelText: 'Batal',
      obscureText: true,
    );
    if (password == null) return;

    // Role selection: only 'owner' and 'kasir'
    final role = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        String sel = 'kasir'; // Default to kasir instead of owner
        return StatefulBuilder(
          builder: (c, setState) {
            return AlertDialog(
              title: const Text('Pilih Role'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    value: 'owner',
                    groupValue: sel,
                    title: const Text('Owner'),
                    onChanged: (v) => setState(() => sel = v ?? 'owner'),
                  ),
                  RadioListTile<String>(
                    value: 'kasir',
                    groupValue: sel,
                    title: const Text('Kasir'),
                    onChanged: (v) => setState(() => sel = v ?? 'kasir'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(sel),
                  child: const Text('Pilih'),
                ),
              ],
            );
          },
        );
      },
    );
    if (role == null) return;

    // Status selection: active / inactive (default active)
    final status = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        String sel = 'active';
        return StatefulBuilder(
          builder: (c, setState) {
            return AlertDialog(
              title: const Text('Pilih Status'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    value: 'active',
                    groupValue: sel,
                    title: const Text('Active'),
                    onChanged: (v) => setState(() => sel = v ?? 'active'),
                  ),
                  RadioListTile<String>(
                    value: 'inactive',
                    groupValue: sel,
                    title: const Text('Inactive'),
                    onChanged: (v) => setState(() => sel = v ?? 'inactive'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(sel),
                  child: const Text('Pilih'),
                ),
              ],
            );
          },
        );
      },
    );
    if (status == null) return;

    final payload = {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'status': status,
    };

    await prov.createUser(payload);
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Manajemen Pengguna'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, prov),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Pengguna'),
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : prov.error != null
              ? Center(child: Text('Error: ${prov.error}'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: prov.users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final u = prov.users[i];
                          return Card(
                            child: ListTile(
                              title: Text(u['name'] ?? '-'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u['email'] ?? '-'),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (u['role'] == 'owner')
                                              ? Colors.blue.withOpacity(0.1)
                                              : Colors.green.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          (u['role'] == 'owner')
                                              ? 'Owner'
                                              : 'Kasir',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: (u['role'] == 'owner')
                                                ? Colors.blue
                                                : Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (u['status'] == 'active')
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          (u['status'] == 'active')
                                              ? 'Active'
                                              : 'Inactive',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: (u['status'] == 'active')
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () async {
                                      final name = await showCustomInputDialog(
                                        context,
                                        title: 'Nama',
                                        initialValue: u['name']?.toString(),
                                        okText: 'Simpan',
                                        cancelText: 'Batal',
                                        hintText: '',
                                      );
                                      if (name == null) return;

                                      final email = await showCustomInputDialog(
                                        context,
                                        title: 'Email',
                                        initialValue: u['email']?.toString(),
                                        okText: 'Simpan',
                                        cancelText: 'Batal',
                                        inputType: TextInputType.emailAddress,
                                        hintText: '',
                                      );
                                      if (email == null) return;

                                      // Role selection when editing (owner / kasir)
                                      final editRole =
                                          await showDialog<String?>(
                                        context: context,
                                        builder: (ctx) {
                                          String sel =
                                              u['role']?.toString() ?? 'kasir';
                                          return StatefulBuilder(
                                            builder: (c, setState) {
                                              return AlertDialog(
                                                title: const Text('Pilih Role'),
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    RadioListTile<String>(
                                                      value: 'owner',
                                                      groupValue: sel,
                                                      title:
                                                          const Text('Owner'),
                                                      onChanged: (v) =>
                                                          setState(
                                                        () =>
                                                            sel = v ?? 'owner',
                                                      ),
                                                    ),
                                                    RadioListTile<String>(
                                                      value: 'kasir',
                                                      groupValue: sel,
                                                      title:
                                                          const Text('Kasir'),
                                                      onChanged: (v) =>
                                                          setState(
                                                        () =>
                                                            sel = v ?? 'kasir',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(null),
                                                    child: const Text('Batal'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(sel),
                                                    child: const Text('Pilih'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                      if (editRole == null) return;

                                      // Status selection when editing (active / inactive)
                                      final editStatus =
                                          await showDialog<String?>(
                                        context: context,
                                        builder: (ctx) {
                                          String sel =
                                              u['status']?.toString() ??
                                                  'active';
                                          return StatefulBuilder(
                                            builder: (c, setState) {
                                              return AlertDialog(
                                                title:
                                                    const Text('Pilih Status'),
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    RadioListTile<String>(
                                                      value: 'active',
                                                      groupValue: sel,
                                                      title:
                                                          const Text('Active'),
                                                      onChanged: (v) =>
                                                          setState(
                                                        () =>
                                                            sel = v ?? 'active',
                                                      ),
                                                    ),
                                                    RadioListTile<String>(
                                                      value: 'inactive',
                                                      groupValue: sel,
                                                      title: const Text(
                                                          'Inactive'),
                                                      onChanged: (v) =>
                                                          setState(
                                                        () => sel =
                                                            v ?? 'inactive',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(null),
                                                    child: const Text('Batal'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(sel),
                                                    child: const Text('Pilih'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                      if (editStatus == null) return;

                                      final payload = {
                                        'name': name,
                                        'email': email,
                                        'role': editRole,
                                        'status': editStatus,
                                      };

                                      await prov.updateUser(u['id'], payload);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      final ok =
                                          await showCustomKonfirmasiDialog(
                                        context,
                                        title: 'Konfirmasi Hapus',
                                        content:
                                            'Yakin ingin menghapus pengguna ${u['name']}?',
                                        confirmText: 'Hapus',
                                        cancelText: 'Batal',
                                        confirmIsDestructive: true,
                                      );
                                      if (ok == true)
                                        await prov.deleteUser(u['id']);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Pagination controls
                    if (prov.totalPages > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Halaman ${prov.currentPage} dari ${prov.totalPages} (${prov.totalUsers} pengguna)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: prov.currentPage > 1
                                      ? () => prov.previousPage()
                                      : null,
                                ),
                                SizedBox(
                                  width: 60,
                                  child: TextField(
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                      border: OutlineInputBorder(),
                                    ),
                                    controller: TextEditingController(
                                      text: prov.currentPage.toString(),
                                    ),
                                    onSubmitted: (value) {
                                      final page = int.tryParse(value);
                                      if (page != null) {
                                        prov.goToPage(page);
                                      }
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: prov.currentPage < prov.totalPages
                                      ? () => prov.nextPage()
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}
