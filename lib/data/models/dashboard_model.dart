class DashboardModel {
  final int todayBookings;
  final int activeCustomers;
  final double todayRevenue;
  final int occupiedLanes;
  final double totalCredits;
  final List<RecentBooking> recentBookings;

  DashboardModel({
    this.todayBookings = 0,
    this.activeCustomers = 0,
    this.todayRevenue = 0,
    this.occupiedLanes = 0,
    this.totalCredits = 0,
    this.recentBookings = const [],
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) => DashboardModel(
        todayBookings: json['todayBookings'] as int? ?? 0,
        activeCustomers: json['activeCustomers'] as int? ?? 0,
        todayRevenue: (json['todayRevenue'] as num?)?.toDouble() ?? 0,
        occupiedLanes: json['occupiedLanes'] as int? ?? 0,
        totalCredits: (json['totalCredits'] as num?)?.toDouble() ?? 0,
        recentBookings: (json['recentBookings'] as List? ?? [])
            .map((e) => RecentBooking.fromJson(e))
            .toList(),
      );
}

class RecentBooking {
  final String id;
  final String customerName;
  final int laneNumber;
  final String slotTime;
  final double price;
  final String status;

  RecentBooking({
    required this.id,
    required this.customerName,
    required this.laneNumber,
    required this.slotTime,
    required this.price,
    required this.status,
  });

  factory RecentBooking.fromJson(Map<String, dynamic> json) => RecentBooking(
        id: json['id'] as String,
        customerName: json['customerName'] as String,
        laneNumber: json['laneNumber'] as int,
        slotTime: json['slotTime'] as String,
        price: (json['price'] as num).toDouble(),
        status: json['status'] as String,
      );
}
