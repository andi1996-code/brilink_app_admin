import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomInputDialog extends StatefulWidget {
  final String title;
  final String hintText;
  final TextInputType inputType;
  final String? initialValue;
  final String okText;
  final String cancelText;
  final void Function(String)? onSubmitted; // optional callback
  final IconData? icon;
  final String? helperText;
  final int maxLines;
  final bool formatRupiah;
  final bool obscureText;

  const CustomInputDialog({
    super.key,
    required this.title,
    required this.hintText,
    required this.inputType,
    this.initialValue,
    this.okText = 'OK',
    this.cancelText = 'Batal',
    this.onSubmitted,
    this.icon,
    this.helperText,
    this.maxLines = 1,
    this.formatRupiah = false,
    this.obscureText = false,
  });

  @override
  State<CustomInputDialog> createState() => _CustomInputDialogState();
}

class _CustomInputDialogState extends State<CustomInputDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isFormatting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');

    // If formatRupiah is requested and there's an initial value, pre-format it
    if (widget.formatRupiah && (_controller.text).isNotEmpty) {
      final rawInit = _controller.text.trim();
      // Try to parse numeric representations like "100000.00" safely
      final normalized = rawInit.replaceAll(',', '');
      final parsedDouble = double.tryParse(normalized);
      String formatted;
      if (parsedDouble != null) {
        formatted = _formatRupiah(parsedDouble.round().toString());
      } else {
        // fallback: remove non-digits (handles already-formatted strings like "2.000.000")
        final digits = rawInit.replaceAll(RegExp(r'[^0-9]'), '');
        formatted = _formatRupiah(digits);
      }
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    // update UI when text changes so suffixIcon (clear) appears/disappears
    _controller.addListener(() {
      if (widget.formatRupiah && !_isFormatting) {
        _isFormatting = true;
        final raw = _controller.text;
        final formatted = _formatRupiah(raw);
        // Only update if different to avoid cursor jump loops
        if (formatted != raw) {
          _controller.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
        _isFormatting = false;
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final raw = _controller.text.trim();
    final value = widget.formatRupiah
        ? raw.replaceAll(RegExp(r'[^0-9]'), '')
        : raw;
    setState(() => _isSubmitting = true);
    // Call optional callback but still return value to caller via Navigator.pop
    try {
      if (widget.onSubmitted != null) widget.onSubmitted!(value);
      if (mounted) Navigator.of(context).pop(value);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.icon != null)
                Center(
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: theme.colorScheme.primary.withOpacity(
                      0.12,
                    ),
                    child: Icon(widget.icon, color: theme.colorScheme.primary),
                  ),
                ),
              if (widget.icon != null) const SizedBox(height: 12),
              Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _controller,
                autofocus: true,
                obscureText: widget.obscureText,
                keyboardType: widget.formatRupiah
                    ? const TextInputType.numberWithOptions(decimal: false)
                    : widget.inputType,
                inputFormatters: widget.formatRupiah
                    ? <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ]
                    : null,
                textInputAction: TextInputAction.done,
                maxLines: widget.maxLines,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  helperText: widget.helperText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _controller.clear()),
                        ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Tidak boleh kosong'
                    : null,
                onFieldSubmitted: (_) => _handleSubmit(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: Text(widget.cancelText),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(widget.okText),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper that shows [CustomInputDialog] and returns the entered value or null if cancelled.
Future<String?> showCustomInputDialog(
  BuildContext context, {
  required String title,
  required String hintText,
  TextInputType inputType = TextInputType.text,
  String? initialValue,
  String okText = 'OK',
  String cancelText = 'Batal',
  IconData? icon,
  String? helperText,
  int maxLines = 1,
  bool barrierDismissible = false,
  bool formatRupiah = false,
  bool obscureText = false,
}) {
  return showDialog<String?>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => CustomInputDialog(
      title: title,
      hintText: hintText,
      inputType: inputType,
      initialValue: initialValue,
      okText: okText,
      cancelText: cancelText,
      icon: icon,
      helperText: helperText,
      maxLines: maxLines,
      formatRupiah: formatRupiah,
      obscureText: obscureText,
    ),
  );
}
