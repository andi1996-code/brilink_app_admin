import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agent_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../core/constants/app_color.dart';

class AgentManagementScreen extends StatefulWidget {
  const AgentManagementScreen({Key? key}) : super(key: key);

  @override
  State<AgentManagementScreen> createState() => _AgentManagementScreenState();
}

class _AgentManagementScreenState extends State<AgentManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AgentProvider>(context, listen: false).fetchAgents();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _populateForm(Map<String, dynamic> agent) {
    _nameController.text = agent['agent_name']?.toString() ?? '';
    _addressController.text = agent['address']?.toString() ?? '';
    _phoneController.text = agent['phone']?.toString() ?? '';
  }

  Future<void> _saveAgent(AgentProvider prov) async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'agent_name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'phone': _phoneController.text.trim(),
    };

    // Assuming single agent, get the first one
    if (prov.agents.isNotEmpty) {
      final agentId = prov.agents[0]['id'];
      await prov.updateAgent(agentId, payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AgentProvider>(context);

    // Populate form when data is loaded
    if (prov.agents.isNotEmpty && _nameController.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _populateForm(prov.agents[0]);
      });
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Manajemen Agen'),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : prov.error != null
              ? Center(child: Text('Error: ${prov.error}'))
              : prov.agents.isEmpty
                  ? const Center(child: Text('Tidak ada data agen'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informasi Agen',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColor.darkTextPrimary
                                        : AppColor.primary,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nama Agen',
                                hintText: 'Masukkan nama agen',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.business),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nama agen tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Nomor Telepon',
                                hintText: 'Masukkan nomor telepon',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nomor telepon tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Alamat',
                                hintText: 'Masukkan alamat lengkap',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Alamat tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            CustomButton(
                              text: 'Simpan Perubahan',
                              icon: Icons.save,
                              onPressed: prov.isLoading
                                  ? null
                                  : () => _saveAgent(prov),
                              height: 50,
                              borderRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}
