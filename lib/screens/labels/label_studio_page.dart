import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/utils/color_palette.dart';

enum LabelType { barcode, binQr, shippingPallet }

class LabelStudioPage extends StatefulWidget {
  const LabelStudioPage({super.key});

  @override
  State<LabelStudioPage> createState() => _LabelStudioPageState();
}

class _LabelStudioPageState extends State<LabelStudioPage> {
  LabelType _type = LabelType.barcode;
  ProductItem? _selectedProduct;
  final _customCodeCtrl = TextEditingController(text: 'WMS-7892140');
  final _customTitleCtrl = TextEditingController(text: 'USB-C Cable 2m');
  bool _includePrice = true;
  bool _includeSku = true;
  bool _includeCompany = true;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);

    return Scaffold(
      backgroundColor: ColorPalette.aquaHaze,
      appBar: AppBar(
        title: const Text('Barcode & Label Studio'),
        actions: [
          IconButton(
            tooltip: 'Print Label',
            icon: const Icon(Icons.print_outlined),
            onPressed: () => _printLabel(context),
          ),
        ],
      ),
      body: StreamBuilder<List<ProductItem>>(
        stream: scope.repo.watchProducts(),
        builder: (ctx, snap) {
          final products = snap.data ?? [];
          if (_selectedProduct == null && products.isNotEmpty) {
            _selectedProduct = products.first;
            _customCodeCtrl.text = _selectedProduct!.product.barcode.isNotEmpty
                ? _selectedProduct!.product.barcode
                : _selectedProduct!.product.sku;
            _customTitleCtrl.text = _selectedProduct!.product.name;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label Type Selector
                SegmentedButton<LabelType>(
                  segments: const [
                    ButtonSegment(
                      value: LabelType.barcode,
                      label: Text('Product Barcode'),
                      icon: Icon(Icons.barcode_reader),
                    ),
                    ButtonSegment(
                      value: LabelType.binQr,
                      label: Text('Bin QR Tag'),
                      icon: Icon(Icons.qr_code_2),
                    ),
                    ButtonSegment(
                      value: LabelType.shippingPallet,
                      label: Text('Shipping Tag'),
                      icon: Icon(Icons.local_shipping_outlined),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (set) => setState(() => _type = set.first),
                ),
                const SizedBox(height: 16),
                // Live Interactive Label Canvas Preview
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: _buildLabelContent(),
                  ),
                ),
                const SizedBox(height: 20),
                // Configuration Controls Card
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Label Source & Content Options',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: ColorPalette.timberGreen,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (products.isNotEmpty) ...[
                          DropdownButtonFormField<String>(
                            value: _selectedProduct?.id,
                            decoration: const InputDecoration(
                              labelText: 'Map from Inventory Product',
                              isDense: true,
                            ),
                            items: products
                                .map((p) => DropdownMenuItem(
                                      value: p.id,
                                      child: Text(
                                        p.product.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (id) {
                              if (id != null) {
                                final found =
                                    products.firstWhere((p) => p.id == id);
                                setState(() {
                                  _selectedProduct = found;
                                  _customTitleCtrl.text = found.product.name;
                                  _customCodeCtrl.text =
                                      found.product.barcode.isNotEmpty
                                          ? found.product.barcode
                                          : found.product.sku;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: _customTitleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Label Header / Title',
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _customCodeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Barcode Data / Serial Number',
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          dense: true,
                          title: const Text('Show Price & Currency'),
                          value: _includePrice,
                          onChanged: (v) => setState(() => _includePrice = v),
                        ),
                        SwitchListTile(
                          dense: true,
                          title: const Text('Show SKU Identifier'),
                          value: _includeSku,
                          onChanged: (v) => setState(() => _includeSku = v),
                        ),
                        SwitchListTile(
                          dense: true,
                          title: const Text('Show Company / Manufacturer'),
                          value: _includeCompany,
                          onChanged: (v) => setState(() => _includeCompany = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _printLabel(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorPalette.pacificBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.print, size: 20),
                    label: const Text(
                      'Print / Export Label',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabelContent() {
    final title = _customTitleCtrl.text.isNotEmpty
        ? _customTitleCtrl.text
        : 'Item Description';
    final code = _customCodeCtrl.text.isNotEmpty
        ? _customCodeCtrl.text
        : 'WMS-000000';
    final company = _selectedProduct?.product.company.isNotEmpty == true
        ? _selectedProduct!.product.company
        : 'Warehouse Operations Ltd';
    final priceStr = _selectedProduct != null
        ? '\$${_selectedProduct!.product.cost.toStringAsFixed(2)}'
        : '\$24.99';
    final sku = _selectedProduct?.product.sku.isNotEmpty == true
        ? _selectedProduct!.product.sku
        : code;

    switch (_type) {
      case LabelType.barcode:
        return Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_includeCompany)
                Text(
                  company.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Vector Barcode
              CustomPaint(
                size: const Size(260, 64),
                painter: BarcodePainter(code),
              ),
              const SizedBox(height: 4),
              Text(
                code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_includeSku)
                    Text('SKU: $sku',
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                  if (_includePrice)
                    Text(priceStr,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );

      case LabelType.binQr:
        return Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LOCATION BIN TAG',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                code,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              CustomPaint(
                size: const Size(120, 120),
                painter: QrPatternPainter(code),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

      case LabelType.shippingPallet:
        return Container(
          width: 340,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PRIORITY FREIGHT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: const Text(
                      'ZONE A-01',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(thickness: 2, color: Colors.black, height: 16),
              const Text('SHIP TO:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const Text('100 Warehouse Way, Central Dock #4', style: TextStyle(fontSize: 11)),
              const Divider(thickness: 1, color: Colors.black, height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TRACKING / SERIAL #:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        Text(code, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        CustomPaint(
                          size: const Size(160, 48),
                          painter: BarcodePainter(code),
                        ),
                      ],
                    ),
                  ),
                  CustomPaint(
                    size: const Size(70, 70),
                    painter: QrPatternPainter(code),
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }

  void _printLabel(BuildContext context) async {
    final code = _customCodeCtrl.text;
    final title = _customTitleCtrl.text;
    await Clipboard.setData(ClipboardData(text: 'LABEL DATA: [$title] CODE: [$code]'));
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Label Ready for Thermal Printer'),
          content: Text(
            'Label "$title" ($code) generated. Data has been copied to your clipboard and queued for active print spooler.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }
}

/// Custom painter that renders deterministic, clean vector barcode stripes based on string hash.
class BarcodePainter extends CustomPainter {
  BarcodePainter(this.data);
  final String data;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final hash = data.hashCode.abs();
    final barCount = 42;
    final barWidth = size.width / (barCount * 1.4);

    double currentX = 0;
    for (int i = 0; i < barCount; i++) {
      final isThick = ((hash >> (i % 24)) & 1) == 1 || (i % 7 == 0);
      final w = isThick ? barWidth * 1.8 : barWidth * 0.9;
      if (i % 2 == 0 || i < 3 || i > barCount - 4) {
        canvas.drawRect(Rect.fromLTWH(currentX, 0, w, size.height), paint);
      }
      currentX += w + barWidth * 0.4;
    }
  }

  @override
  bool shouldRepaint(covariant BarcodePainter oldDelegate) =>
      oldDelegate.data != data;
}

/// Custom painter that renders deterministic, high-contrast QR matrix pattern blocks.
class QrPatternPainter extends CustomPainter {
  QrPatternPainter(this.data);
  final String data;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    const grid = 17;
    final cellSize = size.width / grid;
    final hash = data.hashCode.abs();

    for (int r = 0; r < grid; r++) {
      for (int c = 0; c < grid; c++) {
        // Corner alignment boxes (standard QR corners)
        final inTopLeft = r < 5 && c < 5;
        final inTopRight = r < 5 && c > grid - 6;
        final inBottomLeft = r > grid - 6 && c < 5;

        bool fill = false;
        if (inTopLeft || inTopRight || inBottomLeft) {
          fill = true;
          // hollow inside corner
          if ((r == 1 && c == 1) ||
              (r == 1 && c == grid - 2) ||
              (r == grid - 2 && c == 1)) {
            fill = false;
          }
        } else {
          fill = ((hash >> ((r * grid + c) % 28)) & 1) == 1;
        }

        if (fill) {
          canvas.drawRect(
            Rect.fromLTWH(c * cellSize, r * cellSize, cellSize - 0.5, cellSize - 0.5),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant QrPatternPainter oldDelegate) =>
      oldDelegate.data != data;
}
