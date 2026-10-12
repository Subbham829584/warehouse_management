class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.category,
    required this.leadTimeDays,
    this.rating = 4.5,
    this.address = '',
  });

  final String id;
  final String name;
  final String contactPerson;
  final String email;
  final String phone;
  final String category;
  final int leadTimeDays;
  final double rating;
  final String address;

  Supplier copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? email,
    String? phone,
    String? category,
    int? leadTimeDays,
    double? rating,
    String? address,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      category: category ?? this.category,
      leadTimeDays: leadTimeDays ?? this.leadTimeDays,
      rating: rating ?? this.rating,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contactPerson': contactPerson,
      'email': email,
      'phone': phone,
      'category': category,
      'leadTimeDays': leadTimeDays,
      'rating': rating,
      'address': address,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map, {String? id}) {
    return Supplier(
      id: id ?? (map['id'] as String? ?? ''),
      name: map['name'] as String? ?? '',
      contactPerson: map['contactPerson'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      leadTimeDays: (map['leadTimeDays'] as num?)?.toInt() ?? 5,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      address: map['address'] as String? ?? '',
    );
  }
}
