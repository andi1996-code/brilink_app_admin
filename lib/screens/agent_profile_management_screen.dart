import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/agent_profile_provider.dart';

class AgentProfileManagementScreen extends StatefulWidget {
  const AgentProfileManagementScreen({Key? key}) : super(key: key);

  @override
  State<AgentProfileManagementScreen> createState() =>
      _AgentProfileManagementScreenState();
}

class _AgentProfileManagementScreenState
    extends State<AgentProfileManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerController = TextEditingController();
  final _agentController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _logoUrl;
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AgentProfileProvider>(context, listen: false).fetchProfile();
    });
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _agentController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _changeLogo() async {
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        final _urlCtrl = TextEditingController(text: _logoUrl ?? '');
        return AlertDialog(
          title: const Text('Ganti Logo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL gambar',
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 8),
              const Text(
                'Masukkan URL gambar untuk logo atau kosongkan untuk menggunakan placeholder.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(''),
              child: const Text('Hapus'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(_urlCtrl.text.trim()),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _logoUrl = result.isEmpty ? null : result;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'owner_name': _ownerController.text.trim(),
      'agent_name': _agentController.text.trim(),
      'address': _addressController.text.trim(),
      'phone': _phoneController.text.trim(),
      'logo': _logoUrl ?? '',
    };

    final provider = Provider.of<AgentProfileProvider>(context, listen: false);
    bool ok;
    if (provider.profile != null && provider.profile!['id'] != null) {
      ok = await provider.updateProfile(
        provider.profile!['id'] as int,
        payload,
      );
    } else {
      ok = await provider.createProfile(payload);
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Profil agen tersimpan' : 'Gagal menyimpan profil'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final agentProv = Provider.of<AgentProfileProvider>(context);
    // populate controllers once when profile arrives
    if (!_controllersInitialized && agentProv.profile != null) {
      final p = agentProv.profile!;
      _ownerController.text = p['owner_name'] ?? '';
      _agentController.text = p['agent_name'] ?? '';
      _addressController.text = p['address'] ?? '';
      _phoneController.text = p['phone'] ?? '';
      _logoUrl = p['logo'];
      _controllersInitialized = true;
    }
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Profil Agen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: agentProv.isLoading
            ? Center(
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
              )
            : agentProv.error != null
            ? Center(child: Text('Error: ${agentProv.error}'))
            : Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Card 1: Logo (center), Agent name, Owner name, Buttons (each on own row)
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Row 1: centered avatar
                                Center(
                                  child: CircleAvatar(
                                    radius: 44,
                                    backgroundColor:
                                        theme.colorScheme.surfaceVariant,
                                    backgroundImage:
                                        _logoUrl != null && _logoUrl!.isNotEmpty
                                        ? NetworkImage(_logoUrl!)
                                              as ImageProvider
                                        : null,
                                    child: _logoUrl == null || _logoUrl!.isEmpty
                                        ? Icon(
                                            Icons.storefront,
                                            size: 36,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Row 2: agent name centered
                                Text(
                                  _agentController.text.isNotEmpty
                                      ? _agentController.text
                                      : 'Nama Agen',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                // Row 3: owner name centered
                                Text(
                                  _ownerController.text.isNotEmpty
                                      ? 'Owner: ${_ownerController.text}'
                                      : 'Nama pemilik',
                                  style: theme.textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                // Row 4: action buttons centered
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _changeLogo,
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Ganti Logo'),
                                      style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          setState(() => _logoUrl = null),
                                      icon: const Icon(Icons.delete),
                                      label: const Text('Hapus'),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          width: 1,
                                          color: theme.colorScheme.error,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Card 2: Remaining fields and actions
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _ownerController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nama Pemilik',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Nama pemilik wajib diisi'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _agentController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nama Agen',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Nama agen wajib diisi'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _addressController,
                                  minLines: 2,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'Alamat',
                                    prefixIcon: Icon(
                                      Icons.location_on_outlined,
                                    ),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Alamat wajib diisi'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nomor HP',
                                    prefixIcon: Icon(Icons.phone_outlined),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return 'Nomor HP wajib diisi';
                                    final cleaned = v.trim().replaceAll(
                                      RegExp(r'[^0-9+]'),
                                      '',
                                    );
                                    if (cleaned.length < 7)
                                      return 'Nomor HP terlalu pendek';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          // Reset form
                                          _formKey.currentState?.reset();
                                          setState(() {
                                            _ownerController.clear();
                                            _agentController.clear();
                                            _addressController.clear();
                                            _phoneController.clear();
                                            _logoUrl = null;
                                          });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            width: 1,
                                            color: theme.colorScheme.error,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Berishkan'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _save,
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            width: 1,
                                            color: theme.colorScheme.error,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Simpan'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
