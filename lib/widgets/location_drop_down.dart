import 'package:flutter/material.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class LocationDD extends StatefulWidget {
  final Product? product;
  final String? initialLocation;
  final ValueChanged<String>? onChanged;

  const LocationDD({super.key, this.product, this.initialLocation, this.onChanged});
  @override
  State<LocationDD> createState() => _LocationDDState();
}

class _LocationDDState extends State<LocationDD> {
  static const List<String> locations = [
    "Godown 1, 1st Floor",
    "Godown 1, 2nd Floor",
    "Godown 2, 1st Floor",
    "Godown 2, 2nd Floor",
  ];
  late String _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialLocation ?? widget.product?.location ?? locations[0];
    if (!locations.contains(_current)) {
      _current = locations[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 3),
            blurRadius: 6,
            color: ColorPalette.nileBlue.withValues(alpha: 0.1),
          ),
        ],
      ),
      height: 50,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: _current,
            onChanged: (String? value) {
              if (value != null) {
                setState(() => _current = value);
                widget.onChanged?.call(value);
              }
            },
            items: locations.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontFamily: "Nunito",
                    fontSize: 14,
                    color: ColorPalette.nileBlue,
                  ),
                ),
              );
            }).toList(),
            icon: Icon(
              Icons.arrow_drop_down,
              color: ColorPalette.nileBlue.withValues(alpha: 0.58),
            ),
          ),
        ),
      ),
    );
  }
}
