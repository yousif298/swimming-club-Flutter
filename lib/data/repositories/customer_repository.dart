import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final ApiClient _client = ApiClient();

  Future<List<CustomerModel>> getAll({String? search, int page = 1, int pageSize = 20}) async {
    final response = await _client.get(
      ApiConstants.customers,
      queryParams: {'search': search, 'page': page, 'pageSize': pageSize},
    );
    final data = response.data;
    return (data['items'] as List).map((e) => CustomerModel.fromJson(e)).toList();
  }

  Future<CustomerModel> create(String fullName, String phone, String? address) async {
    final response = await _client.post(
      ApiConstants.customers,
      data: {'fullName': fullName, 'phone': phone, 'address': address},
    );
    return CustomerModel.fromJson(response.data);
  }
}
