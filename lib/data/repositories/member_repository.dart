import '../../core/network/api_client.dart';
import '../models/member_model.dart';

class MemberRepository {
  final ApiClient _client = ApiClient();

  Future<List<MemberModel>> getAll({String? search}) async {
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final response = await _client.get('/members', queryParams: params.isNotEmpty ? params : null);
    return (response.data as List).map((e) => MemberModel.fromJson(e)).toList();
  }

  Future<MemberModel> create({
    required String fullName,
    int? age,
    String? phone,
    String? customerId,
  }) async {
    final data = <String, dynamic>{
      'fullName': fullName,
    };
    if (age != null) data['age'] = age;
    if (phone != null) data['phone'] = phone;
    if (customerId != null) data['customerId'] = customerId;
    final response = await _client.post('/members', data: data);
    return MemberModel.fromJson(response.data);
  }

  Future<void> update(String id, {String? fullName, int? age, String? phone}) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['fullName'] = fullName;
    if (age != null) data['age'] = age;
    if (phone != null) data['phone'] = phone;
    await _client.put('/members/$id', data: data);
  }

  Future<void> delete(String id) async {
    await _client.delete('/members/$id');
  }
}
