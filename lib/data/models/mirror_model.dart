class MirrorViewModel {
  final String poolId;
  final String poolName;
  final List<LaneMirror> lanes;
  final List<TimeSlotMirror> timeSlots;

  MirrorViewModel({
    required this.poolId,
    required this.poolName,
    required this.lanes,
    required this.timeSlots,
  });

  factory MirrorViewModel.fromJson(Map<String, dynamic> json) => MirrorViewModel(
        poolId: json['poolId'] as String,
        poolName: json['poolName'] as String,
        lanes: (json['lanes'] as List).map((e) => LaneMirror.fromJson(e)).toList(),
        timeSlots: (json['timeSlots'] as List).map((e) => TimeSlotMirror.fromJson(e)).toList(),
      );
}

class LaneMirror {
  final String id;
  final int number;

  LaneMirror({required this.id, required this.number});

  factory LaneMirror.fromJson(Map<String, dynamic> json) => LaneMirror(
        id: json['id'] as String,
        number: json['number'] as int,
      );
}

class TimeSlotMirror {
  final String id;
  final String display;
  final int orderIndex;

  TimeSlotMirror({required this.id, required this.display, required this.orderIndex});

  factory TimeSlotMirror.fromJson(Map<String, dynamic> json) => TimeSlotMirror(
        id: json['id'] as String,
        display: json['display'] as String,
        orderIndex: json['orderIndex'] as int,
      );
}

class SlotStatusModel {
  final bool isBooked;
  final BookingDetail? booking;

  SlotStatusModel({required this.isBooked, this.booking});

  factory SlotStatusModel.fromJson(Map<String, dynamic> json) => SlotStatusModel(
        isBooked: json['isBooked'] as bool,
        booking: json['booking'] != null ? BookingDetail.fromJson(json['booking']) : null,
      );
}

class BookingDetail {
  final String bookingId;
  final String customerId;
  final String customerName;
  final String bookingType;
  final double price;
  final String paymentStatus;

  BookingDetail({
    required this.bookingId,
    required this.customerId,
    required this.customerName,
    required this.bookingType,
    required this.price,
    required this.paymentStatus,
  });

  factory BookingDetail.fromJson(Map<String, dynamic> json) => BookingDetail(
        bookingId: json['bookingId'] as String,
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        bookingType: json['bookingType'] as String,
        price: (json['price'] as num).toDouble(),
        paymentStatus: json['paymentStatus'] as String,
      );
}
