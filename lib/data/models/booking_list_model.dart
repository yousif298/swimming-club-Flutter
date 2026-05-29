class BookingListModel {
  final String id;
  final String customerName;
  final int laneNumber;
  final String slotTime;
  final DateTime bookingDate;
  final String bookingType;
  final double price;
  final String paymentStatus;
  final String? color;

  BookingListModel({
    required this.id,
    required this.customerName,
    required this.laneNumber,
    required this.slotTime,
    required this.bookingDate,
    required this.bookingType,
    required this.price,
    required this.paymentStatus,
    this.color,
  });

  factory BookingListModel.fromJson(Map<String, dynamic> json) => BookingListModel(
        id: json['id'] as String,
        customerName: json['customerName'] as String,
        laneNumber: json['laneNumber'] as int,
        slotTime: json['slotTime'] as String,
        bookingDate: DateTime.parse(json['bookingDate'] as String),
        bookingType: json['bookingType'] as String,
        price: (json['price'] as num).toDouble(),
        paymentStatus: json['paymentStatus'] as String,
        color: json['color'] as String?,
      );
}
