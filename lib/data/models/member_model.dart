class MemberModel {
  final String id;
  final String fullName;
  final int? age;
  final String? phone;
  final String? customerId;
  final String? customerName;

  MemberModel({
    required this.id,
    required this.fullName,
    this.age,
    this.phone,
    this.customerId,
    this.customerName,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) => MemberModel(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        age: json['age'] as int?,
        phone: json['phone'] as String?,
        customerId: json['customerId'] as String?,
        customerName: json['customerName'] as String?,
      );
}
