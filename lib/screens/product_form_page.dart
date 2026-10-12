import 'package:flutter/material.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/core/constants.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/core/validators.dart';
import 'package:warehouse_management/models/product.dart';

/// Create (item == null) or edit (item != null) a product with real
/// form validation. Quantity is editable only when creating; afterwards
/// it changes via Stock In / Out so every change is audited.
class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.group, this.item});
  final String? group;
  final ProductItem? item;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  late String _location;
  late String _unit;
  bool _saving = false;

  bool get _editing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final p = widget.item?.product ?? const Product();
    _c = {
      'name': TextEditingController(text: p.name),
      'company': TextEditingController(text: p.company),
      'sku': TextEditingController(text: p.sku),
      'barcode': TextEditingController(text: p.barcode),
      'cost': TextEditingController(text: _editing ? '${p.cost}' : ''),
      'quantity': TextEditingController(text: _editing ? '${p.quantity}' : '0'),
      'minStock': TextEditingController(text: '${p.minStock}'),
      'image': TextEditingController(text: p.image),
      'description': TextEditingController(text: p.description),
    };
    _location = AppConstants.locations.contains(p.location)
        ? p.location
        : AppConstants.locations.first;
    _unit =
        AppConstants.units.contains(p.unit) ? p.unit : AppConstants.units.first;
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Product _build() {
    final old = widget.item?.product;
    return Product(
      name: _c['name']!.text.trim(),
      company: _c['company']!.text.trim(),
      sku: _c['sku']!.text.trim(),
      barcode: _c['barcode']!.text.trim(),
      cost: double.parse(_c['cost']!.text.trim()),
      quantity:
          _editing ? old!.quantity : int.parse(_c['quantity']!.text.trim()),
      minStock: int.parse(_c['minStock']!.text.trim()),
      image: _c['image']!.text.trim(),
      description: _c['description']!.text.trim(),
      group: widget.item?.product.group ?? widget.group ?? '',
      location: _location,
      unit: _unit,
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final scope = AppScope.of(context);
    setState(() => _saving = true);
    try {
      final p = _build();
      // Block duplicate barcodes/SKUs so scanning is unambiguous.
      for (final code in [p.barcode, p.sku].where((s) => s.isNotEmpty)) {
        final dup = await scope.repo.findByCode(code);
        if (dup != null && dup.id != widget.item?.id) {
          throw StateError('"$code" is already used by ${dup.product.name}.');
        }
      }
      if (_editing) {
        await scope.repo.updateProduct(widget.item!.id, p);
      } else {
        await scope.repo.addProduct(p, userEmail: scope.userEmail);
      }
      if (!mounted) return;
      showMessage(context, _editing ? 'Product updated' : 'Product added');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted)
        showMessage(context, '$e'.replaceFirst('Bad state: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String key, String label,
      {String? Function(String?)? validator,
      TextInputType? type,
      int lines = 1,
      bool enabled = true,
      Widget? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _c[key],
        validator: validator,
        keyboardType: type,
        maxLines: lines,
        enabled: enabled,
        decoration: InputDecoration(labelText: label, suffixIcon: suffix),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit product' : 'New product')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field('name', 'Product name *',
                validator: (v) => Validators.required(v, 'Name')),
            _field('company', 'Manufacturer / company'),
            Row(children: [
              Expanded(child: _field('sku', 'SKU')),
              const SizedBox(width: 12),
              Expanded(child: _field('barcode', 'Barcode')),
            ]),
            Row(children: [
              Expanded(
                child: _field('cost', 'Unit cost (₹) *',
                    type: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => Validators.nonNegativeNumber(v, 'Cost')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                    'quantity',
                    _editing
                        ? 'Quantity (use Stock In/Out)'
                        : 'Opening quantity *',
                    type: TextInputType.number,
                    enabled: !_editing,
                    validator: (v) => Validators.nonNegativeInt(v, 'Quantity')),
              ),
            ]),
            Row(children: [
              Expanded(
                child: _field('minStock', 'Low-stock alert at *',
                    type: TextInputType.number,
                    validator: (v) =>
                        Validators.nonNegativeInt(v, 'Min stock')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: [
                      for (final u in AppConstants.units)
                        DropdownMenuItem(value: u, child: Text(u))
                    ],
                    onChanged: (v) => setState(() => _unit = v ?? _unit),
                  ),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DropdownButtonFormField<String>(
                initialValue: _location,
                decoration: const InputDecoration(labelText: 'Location'),
                items: [
                  for (final l in AppConstants.locations)
                    DropdownMenuItem(value: l, child: Text(l))
                ],
                onChanged: (v) => setState(() => _location = v ?? _location),
              ),
            ),
            _field('image', 'Image URL (optional)', type: TextInputType.url,
                validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final u = Uri.tryParse(v.trim());
              return (u != null && u.hasScheme && u.host.isNotEmpty)
                  ? null
                  : 'Enter a valid URL';
            }),
            _field('description', 'Description', lines: 3),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: Text(_editing ? 'Save changes' : 'Add product'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
