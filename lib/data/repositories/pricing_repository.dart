import '../../core/network/api_client.dart';
import '../models/pricing_model.dart';

class PricingRepository {
  final ApiClient _client = ApiClient();

  Future<List<ActivityModel>> getActivities() async {
    final response = await _client.get('/activities');
    return (response.data as List).map((e) => ActivityModel.fromJson(e)).toList();
  }

  Future<List<PricingModel>> getPricing(String activityId) async {
    final response = await _client.get('/pricing/$activityId');
    return (response.data as List).map((e) => PricingModel.fromJson(e)).toList();
  }

  Future<PricingModel> create({
    required String activityId,
    int? minParticipants,
    int? maxParticipants,
    required double price,
    required String pricingType,
    String? duration,
  }) async {
    final data = <String, dynamic>{
      'activityId': activityId,
      'price': price,
      'pricingType': pricingType,
    };
    if (minParticipants != null) data['minParticipants'] = minParticipants;
    if (maxParticipants != null) data['maxParticipants'] = maxParticipants;
    if (duration != null) data['duration'] = duration;
    final response = await _client.post('/pricing', data: data);
    return PricingModel.fromJson(response.data);
  }

  Future<void> update(String id, {double? price, String? pricingType}) async {
    final data = <String, dynamic>{};
    if (price != null) data['price'] = price;
    if (pricingType != null) data['pricingType'] = pricingType;
    await _client.put('/pricing/$id', data: data);
  }

  Future<void> delete(String id) async {
    await _client.delete('/pricing/$id');
  }
}
