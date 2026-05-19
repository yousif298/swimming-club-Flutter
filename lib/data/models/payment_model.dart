class PaymentListModel {
  final String id;
  final String customerId;
  final String customerName;
  final double amount;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;

  PaymentListModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory PaymentListModel.fromJson(Map<String, dynamic> json) => PaymentListModel(
        id: json['id'] as String,
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        amount: (json['amount'] as num).toDouble(),
        paymentMethod: json['paymentMethod'] as String,
        paymentStatus: json['paymentStatus'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
