import 'package:flutter/material.dart';
import 'package:warehouse_management/screens/product_form_page.dart';

class NewProductPage extends StatelessWidget {
  final String? group;
  const NewProductPage({super.key, this.group});

  @override
  Widget build(BuildContext context) {
    return ProductFormPage(group: group);
  }
}
