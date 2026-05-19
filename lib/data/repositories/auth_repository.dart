import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

class AuthRepository {
  final ApiClient _client = ApiClient();

  Future<String?> login(String username, String password) async {
    try {
      final response = await _client.post(
        ApiConstants.login,
        data: {'username': username, 'password': password},
      );
      final token = response.data['token'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('user', response.data['fullName'] as String);
      return token;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Login failed');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }
}
