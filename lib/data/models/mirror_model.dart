class MirrorViewModel {
  final String poolId;
  final String poolName;
  final List<LaneMirror> lanes;
  final List<TimeSlotMirror> timeSlots;
  final List<MirrorSlotModel> slots;

  MirrorViewModel({
    required this.poolId,
    required this.poolName,
    required this.lanes,
    required this.timeSlots,
    required this.slots,
  });

  Map<String, MirrorSlotModel> get slotMap => {
        for (final s in slots) '${s.laneId}-${s.slotId}': s,
      };

  factory MirrorViewModel.fromJson(Map<String, dynamic> json) => MirrorViewModel(
        poolId: json['poolId'] as String,
        poolName: json['poolName'] as String,
        lanes: (json['lanes'] as List).map((e) => LaneMirror.fromJson(e)).toList(),
        timeSlots: (json['timeSlots'] as List).map((e) => TimeSlotMirror.fromJson(e)).toList(),
        slots: (json['slots'] as List).map((e) => MirrorSlotModel.fromJson(e)).toList(),
      );
}

class MirrorSlotModel {
  final String laneId;
  final String slotId;
  final String? bookingId;
  final String? customerId;
  final String? customerName;
  final String? bookingType;
  final String? color;
  final String status;

  MirrorSlotModel({
    required this.laneId,
    required this.slotId,
    this.bookingId,
    this.customerId,
    this.customerName,
    this.bookingType,
    this.color,
    required this.status,
  });

  bool get isBooked => status == 'booked' || status == 'pending';
  bool get isAvailable => status == 'available';

  factory MirrorSlotModel.fromJson(Map<String, dynamic> json) => MirrorSlotModel(
        laneId: json['laneId'] as String,
        slotId: json['slotId'] as String,
        bookingId: json['bookingId'] as String?,
        customerId: json['customerId'] as String?,
        customerName: json['customerName'] as String?,
        bookingType: json['bookingType'] as String?,
        color: json['color'] as String?,
        status: json['status'] as String,
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
  final int? dayOfWeek;

  TimeSlotMirror({required this.id, required this.display, required this.orderIndex, this.dayOfWeek});

  factory TimeSlotMirror.fromJson(Map<String, dynamic> json) => TimeSlotMirror(
        id: json['id'] as String,
        display: json['display'] as String,
        orderIndex: json['orderIndex'] as int,
        dayOfWeek: json['dayOfWeek'] as int?,
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
