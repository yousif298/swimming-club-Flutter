import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/booking_list_model.dart';
import '../models/payment_model.dart';

class ReportRepository {
  final ApiClient _client = ApiClient();

  Future<List<BookingListModel>> getCustomerBookings(String customerId) async {
    final response = await _client.get('${ApiConstants.customers}/$customerId/bookings');
    return (response.data as List).map((e) => BookingListModel.fromJson(e)).toList();
  }

  Future<List<PaymentListModel>> getCustomerPayments(String customerId) async {
    final response = await _client.get('${ApiConstants.customers}/$customerId/payments');
    return (response.data as List).map((e) => PaymentListModel.fromJson(e)).toList();
  }

  Future<PoolReportModel> getPoolReport(String poolId, {DateTime? from, DateTime? to}) async {
    final params = <String, dynamic>{};
    if (from != null) params['from'] = from.toIso8601String().split('T').first;
    if (to != null) params['to'] = to.toIso8601String().split('T').first;
    final response = await _client.get('${ApiConstants.pools}/$poolId/report', queryParams: params.isNotEmpty ? params : null);
    return PoolReportModel.fromJson(response.data);
  }
}

class PoolReportModel {
  final String poolId;
  final String poolName;
  final int totalLanes;
  final int totalBookings;
  final double totalRevenue;
  final double totalCredits;
  final List<PoolReportBooking>? bookings;

  PoolReportModel({
    required this.poolId,
    required this.poolName,
    required this.totalLanes,
    required this.totalBookings,
    required this.totalRevenue,
    required this.totalCredits,
    this.bookings,
  });

  factory PoolReportModel.fromJson(Map<String, dynamic> json) => PoolReportModel(
        poolId: json['poolId'] as String,
        poolName: json['poolName'] as String,
        totalLanes: json['totalLanes'] as int,
        totalBookings: json['totalBookings'] as int,
        totalRevenue: (json['totalRevenue'] as num).toDouble(),
        totalCredits: (json['totalCredits'] as num).toDouble(),
        bookings: (json['bookings'] as List?)?.map((e) => PoolReportBooking.fromJson(e)).toList(),
      );
}

class PoolReportBooking {
  final String date;
  final String customerName;
  final int laneNumber;
  final String slotTime;
  final String bookingType;
  final double price;
  final String paymentStatus;

  PoolReportBooking({
    required this.date,
    required this.customerName,
    required this.laneNumber,
    required this.slotTime,
    required this.bookingType,
    required this.price,
    required this.paymentStatus,
  });

  factory PoolReportBooking.fromJson(Map<String, dynamic> json) => PoolReportBooking(
        date: json['date'] as String,
        customerName: json['customerName'] as String,
        laneNumber: json['laneNumber'] as int,
        slotTime: json['slotTime'] as String,
        bookingType: json['bookingType'] as String,
        price: (json['price'] as num).toDouble(),
        paymentStatus: json['paymentStatus'] as String,
      );
}
