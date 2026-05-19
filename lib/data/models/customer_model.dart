class CustomerModel {
  final String id;
  final String fullName;
  final String phone;
  final String? address;
  final double currentBalance;
  final DateTime createdAt;

  CustomerModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.address,
    this.currentBalance = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        phone: json['phone'] as String,
        address: json['address'] as String?,
        currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0,
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phone': phone,
        'address': address,
      };
}
