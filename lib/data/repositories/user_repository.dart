import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class UserRepository {
  final ApiClient _client = ApiClient();

  Future<List<UserModel>> getAll() async {
    final response = await _client.get('/users');
    return (response.data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<UserModel> create({
    required String username,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final data = {
      'username': username,
      'password': password,
      'fullName': fullName,
      'role': role,
    };
    final response = await _client.post('/users', data: data);
    return UserModel.fromJson(response.data);
  }

  Future<void> update(String id, {String? fullName, String? password, String? role, bool? isActive}) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['fullName'] = fullName;
    if (password != null) data['password'] = password;
    if (role != null) data['role'] = role;
    if (isActive != null) data['isActive'] = isActive;
    await _client.put('/users/$id', data: data);
  }

  Future<void> delete(String id) async {
    await _client.delete('/users/$id');
  }
}
