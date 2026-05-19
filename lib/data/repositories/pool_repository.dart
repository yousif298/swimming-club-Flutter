import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/pool_model.dart';

class PoolRepository {
  final ApiClient _client = ApiClient();

  Future<List<PoolModel>> getAll() async {
    final response = await _client.get(ApiConstants.pools);
    return (response.data as List).map((e) => PoolModel.fromJson(e)).toList();
  }

  Future<List<LaneModel>> getLanes(String poolId) async {
    final path = ApiConstants.lanes.replaceAll('{poolId}', poolId);
    final response = await _client.get(path);
    return (response.data as List).map((e) => LaneModel.fromJson(e)).toList();
  }

  Future<PoolModel> create(String name, int totalLanes) async {
    final response = await _client.post(
      ApiConstants.pools,
      data: {'name': name, 'totalLanes': totalLanes},
    );
    return PoolModel.fromJson(response.data);
  }
}
