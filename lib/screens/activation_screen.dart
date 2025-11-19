import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activation_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../core/constants/app_color.dart';
import 'login_screen.dart';
import '../layout/main_layout.dart';
import '../core/device_id.dart';
import 'package:flutter/services.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({Key? key}) : super(key: key);

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _keyController = TextEditingController();
  bool _isSubmitting = false;
  String? _deviceId;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    final id = await DeviceId.getDeviceId();
    setState(() => _deviceId = id);
  }

  Future<void> _activate() async {
    if (!_formKey.currentState!.validate()) return;
    final key = _keyController.text.trim();

    setState(() => _isSubmitting = true);
    final prov = Provider.of<ActivationProvider>(context, listen: false);
    final ok = await prov.activate(key, validateOnServer: false);
    setState(() => _isSubmitting = false);

    if (ok) {
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      if (authProv.token != null) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainLayout(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final tween = Tween(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeInOut));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final tween = Tween(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeInOut));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const CustomAppBar(title: 'Aktivasi Aplikasi'),
      backgroundColor: theme.colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan kode aktivasi untuk mengaktifkan aplikasi ini.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text('Device ID:', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.device_hub, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _deviceId ?? 'Memuat Device ID...',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, color: theme.colorScheme.primary),
                      onPressed: _deviceId == null
                          ? null
                          : () {
                              Clipboard.setData(
                                ClipboardData(text: _deviceId!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Device ID disalin'),
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Langkah 1: Salin Device ID lalu kirimkan ke admin untuk generate kode.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Langkah 2: Masukkan kode aktivasi yang diberikan oleh admin.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _keyController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan kode aktivasi (Base64 atau Hex)',
                      helperText: 'Contoh Hex: 4812841B (8 hex chars)',
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.paste),
                        onPressed: () async {
                          final d = await Clipboard.getData('text/plain');
                          if (d != null && d.text != null) {
                            setState(() => _keyController.text = d.text!);
                          }
                        },
                      ),
                      suffixIcon: _keyController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => _keyController.clear()),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Kode aktivasi tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                      ),
                      onPressed: _isSubmitting ? null : _activate,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Aktivasi'),
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
