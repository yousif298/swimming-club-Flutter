class BookingModel {
  final String id;
  final String customerId;
  final String customerName;
  final String laneId;
  final int laneNumber;
  final String slotId;
  final String slotTime;
  final DateTime bookingDate;
  final String bookingType;
  final double price;
  final String paymentStatus;

  BookingModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.laneId,
    required this.laneNumber,
    required this.slotId,
    required this.slotTime,
    required this.bookingDate,
    required this.bookingType,
    required this.price,
    required this.paymentStatus,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: json['id'] as String,
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String? ?? '',
        laneId: json['laneId'] as String,
        laneNumber: json['laneNumber'] as int? ?? 0,
        slotId: json['slotId'] as String,
        slotTime: json['slotTime'] as String? ?? '',
        bookingDate: DateTime.parse(json['bookingDate'] as String),
        bookingType: json['bookingType'] as String,
        price: (json['price'] as num).toDouble(),
        paymentStatus: json['paymentStatus'] as String,
      );
}
