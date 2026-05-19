import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/booking_list_model.dart';
import '../models/booking_model.dart';
import '../models/mirror_model.dart';

class BookingRepository {
  final ApiClient _client = ApiClient();

  Future<MirrorViewModel> getMirrorView(String poolId, DateTime date) async {
    final response = await _client.get(
      ApiConstants.mirrorView,
      queryParams: {
        'poolId': poolId,
        'date': date.toIso8601String().split('T').first,
      },
    );
    return MirrorViewModel.fromJson(response.data);
  }

  Future<SlotStatusModel> getSlotStatus(String poolId, String laneId, String slotId, DateTime date) async {
    final response = await _client.get(
      ApiConstants.slotStatus,
      queryParams: {
        'poolId': poolId,
        'laneId': laneId,
        'slotId': slotId,
        'date': date.toIso8601String().split('T').first,
      },
    );
    return SlotStatusModel.fromJson(response.data);
  }

  Future<List<BookingListModel>> getAll({DateTime? date}) async {
    final response = await _client.get(
      ApiConstants.bookings,
      queryParams: date != null ? {'date': date.toIso8601String().split('T').first} : null,
    );
    return (response.data as List).map((e) => BookingListModel.fromJson(e)).toList();
  }

  Future<BookingModel> create({
    required String customerId,
    required String laneId,
    required String slotId,
    required DateTime bookingDate,
    required String bookingType,
    required double price,
    required String paymentStatus,
    int? participantsCount,
  }) async {
    final response = await _client.post(
      ApiConstants.bookings,
      data: {
        'customerId': customerId,
        'laneId': laneId,
        'slotId': slotId,
        'bookingDate': bookingDate.toIso8601String().split('T').first,
        'bookingType': bookingType,
        'price': price,
        'paymentStatus': paymentStatus,
        'participantsCount': participantsCount ?? 1,
      },
    );
    return BookingModel.fromJson(response.data);
  }
}
