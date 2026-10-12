class ProductItem {
  const ProductItem({
    required this.id,
    required this.product,
  });

  final String id;
  final Product product;
}

class Product {
  const Product({
    this.name = '',
    this.cost = 0.0,
    this.group = '',
    this.location = '',
    this.company = '',
    this.quantity = 0,
    this.minStock = 10,
    this.unit = 'pcs',
    this.sku = '',
    this.barcode = '',
    this.image = '',
    this.description = '',
  });

  final String name;
  final double cost;
  final String group;
  final String location;
  final String company;
  final int quantity;
  final int minStock;
  final String unit;
  final String sku;
  final String barcode;
  final String image;
  final String description;

  bool get isOutOfStock => quantity <= 0;
  bool get isLowStock => quantity > 0 && quantity <= minStock;
  double get totalValue => cost * quantity;

  Product copyWith({
    String? name,
    double? cost,
    String? group,
    String? location,
    String? company,
    int? quantity,
    int? minStock,
    String? unit,
    String? sku,
    String? barcode,
    String? image,
    String? description,
  }) =>
      Product(
        name: name ?? this.name,
        cost: cost ?? this.cost,
        group: group ?? this.group,
        location: location ?? this.location,
        company: company ?? this.company,
        quantity: quantity ?? this.quantity,
        minStock: minStock ?? this.minStock,
        unit: unit ?? this.unit,
        sku: sku ?? this.sku,
        barcode: barcode ?? this.barcode,
        image: image ?? this.image,
        description: description ?? this.description,
      );

  factory Product.fromMap(Map<String, dynamic> json) => Product(
        name: (json['name'] as String?)?.trim() ?? '',
        cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
        group: (json['group'] as String?)?.trim() ?? '',
        location: (json['location'] as String?)?.trim() ?? '',
        company: (json['company'] as String?)?.trim() ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        minStock: (json['minStock'] as num?)?.toInt() ?? 10,
        unit: (json['unit'] as String?)?.trim() ?? 'pcs',
        sku: (json['sku'] as String?)?.trim() ?? '',
        barcode: (json['barcode'] as String?)?.trim() ?? '',
        image: (json['image'] as String?)?.trim() ?? '',
        description: (json['description'] as String?)?.trim() ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name.trim(),
        'nameLower': name.trim().toLowerCase(),
        'cost': cost,
        'group': group.trim(),
        'location': location.trim(),
        'company': company.trim(),
        'quantity': quantity,
        'minStock': minStock,
        'unit': unit.trim(),
        'sku': sku.trim(),
        'barcode': barcode.trim(),
        'image': image.trim(),
        'description': description.trim(),
      };
}
