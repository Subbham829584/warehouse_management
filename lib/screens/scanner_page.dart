import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/screens/product_details_page.dart';

/// Scan a barcode/QR → jump straight to that product (or type the code).
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  final TextEditingController _manual = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    _manual.dispose();
    super.dispose();
  }

  Future<void> _lookup(String code) async {
    if (_busy || code.trim().isEmpty) return;
    _busy = true;
    final repo = AppScope.of(context).repo;
    try {
      final found = await repo.findByCode(code);
      if (!mounted) return;
      if (found == null) {
        showMessage(context, 'No product with code "$code"', error: true);
      } else {
        await Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => ProductDetailsPage(item: found)));
        return;
      }
    } catch (e) {
      if (mounted) showMessage(context, 'Lookup failed: $e', error: true);
    }
    // Small cool-down so one bad scan doesn't spam the snackbar.
    await Future<void>.delayed(const Duration(seconds: 2));
    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final code = capture.barcodes.firstOrNull?.rawValue;
              if (code != null) _lookup(code);
            },
            errorBuilder: (context, error, child) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                    'Camera unavailable. Type the code below.\n(${error.errorCode.name})',
                    textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _manual,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _lookup,
                  decoration:
                      const InputDecoration(hintText: 'Or type barcode / SKU'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                  onPressed: () => _lookup(_manual.text),
                  child: const Text('Find')),
            ]),
          ),
        ),
      ]),
    );
  }
}
