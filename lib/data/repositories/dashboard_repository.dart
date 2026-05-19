import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardRepository {
  final ApiClient _client = ApiClient();

  Future<DashboardModel> getDashboard() async {
    final response = await _client.get(ApiConstants.dashboard);
    return DashboardModel.fromJson(response.data);
  }
}
