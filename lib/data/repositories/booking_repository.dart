import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/booking_list_model.dart';
import '../models/booking_model.dart';
import '../models/booking_type_model.dart';
import '../models/mirror_model.dart';

class BookingRepository {
  final ApiClient _client = ApiClient();

  Future<MirrorViewModel> getMirrorView(String poolId, DateTime date, {String? bookingTypeId}) async {
    final params = <String, dynamic>{
      'poolId': poolId,
      'date': date.toIso8601String().split('T').first,
    };
    if (bookingTypeId != null) params['bookingTypeId'] = bookingTypeId;
    final response = await _client.get(ApiConstants.mirrorView, queryParams: params);
    return MirrorViewModel.fromJson(response.data);
  }

  Future<List<BookingTypeModel>> getBookingTypes() async {
    final response = await _client.get(ApiConstants.bookingTypes);
    return (response.data as List).map((e) => BookingTypeModel.fromJson(e)).toList();
  }

  Future<BookingTypeModel> createBookingType({
    required String name, String? description, required double defaultPrice,
    required bool hasCapacity, int? capacity, required bool hasSchedule,
  }) async {
    final data = <String, dynamic>{
      'name': name, 'defaultPrice': defaultPrice, 'hasCapacity': hasCapacity, 'hasSchedule': hasSchedule,
    };
    if (description != null) data['description'] = description;
    if (capacity != null) data['capacity'] = capacity;
    final response = await _client.post(ApiConstants.bookingTypes, data: data);
    return BookingTypeModel.fromJson(response.data);
  }

  Future<void> updateBookingType(String id, {
    required String name, String? description, required double defaultPrice,
    required bool hasCapacity, int? capacity, required bool hasSchedule, required bool isActive,
  }) async {
    final data = <String, dynamic>{
      'name': name, 'defaultPrice': defaultPrice, 'hasCapacity': hasCapacity,
      'hasSchedule': hasSchedule, 'isActive': isActive,
    };
    if (description != null) data['description'] = description;
    if (capacity != null) data['capacity'] = capacity;
    await _client.put('${ApiConstants.bookingTypes}/$id', data: data);
  }

  Future<void> deleteBookingType(String id) async {
    await _client.delete('${ApiConstants.bookingTypes}/$id');
  }

  Future<List<BookingListModel>> getAll({DateTime? date}) async {
    final response = await _client.get(
      ApiConstants.bookings,
      queryParams: date != null ? {'date': date.toIso8601String().split('T').first} : null,
    );
    return (response.data as List).map((e) => BookingListModel.fromJson(e)).toList();
  }

  Future<BookingModel> create({
    required String customerId, required String laneId, required List<String> slotIds,
    required DateTime bookingDate, required String bookingTypeId, required double price,
    required String paymentStatus, String? title, String? coachName, String? color,
    int? durationMonths, int? daysPerMonth, List<Map<String, dynamic>>? members,
    List<Map<String, dynamic>>? scheduleDays, List<Map<String, dynamic>>? additionalLanes,
  }) async {
    final data = <String, dynamic>{
      'customerId': customerId, 'laneId': laneId, 'slotIds': slotIds,
      'bookingDate': bookingDate.toIso8601String().split('T').first,
      'bookingTypeId': bookingTypeId, 'price': price, 'paymentStatus': paymentStatus,
    };
    if (title != null) data['title'] = title;
    if (coachName != null) data['coachName'] = coachName;
    if (color != null) data['color'] = color;
    if (durationMonths != null) data['durationMonths'] = durationMonths;
    if (daysPerMonth != null) data['daysPerMonth'] = daysPerMonth;
    if (members != null) data['members'] = members;
    if (scheduleDays != null) data['scheduleDays'] = scheduleDays;
    if (additionalLanes != null) data['additionalLanes'] = additionalLanes;
    final response = await _client.post(ApiConstants.bookings, data: data);
    return BookingModel.fromJson(response.data);
  }

  Future<void> addMembers(String bookingId, List<Map<String, dynamic>> members) async {
    await _client.post('${ApiConstants.bookings}/$bookingId/members', data: {'members': members});
  }

  Future<void> cancel(String id) async {
    await _client.delete('${ApiConstants.bookings}/$id');
  }

  Future<void> update(String id, {double? price, String? paymentStatus}) async {
    final data = <String, dynamic>{};
    if (price != null) data['price'] = price;
    if (paymentStatus != null) data['paymentStatus'] = paymentStatus;
    await _client.put('${ApiConstants.bookings}/$id', data: data);
  }

  Future<Map<String, dynamic>> getAvailableSlots(String bookingTypeId, DateTime date, {int? targetDayOfWeek}) async {
    final params = <String, dynamic>{
      'bookingTypeId': bookingTypeId,
      'date': date.toIso8601String().split('T').first,
    };
    if (targetDayOfWeek != null) params['targetDayOfWeek'] = targetDayOfWeek;
    final response = await _client.get(
      ApiConstants.availableSlots,
      queryParams: params,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getCategorySchedules(String bookingTypeId) async {
    final response = await _client.get('${ApiConstants.categorySchedules}/$bookingTypeId');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> updateCategorySchedules(String bookingTypeId, List<Map<String, dynamic>> days) async {
    await _client.put('${ApiConstants.categorySchedules}/$bookingTypeId', data: {'bookingTypeId': bookingTypeId, 'days': days});
  }
}
