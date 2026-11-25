import 'package:dio/dio.dart';
import 'package:medicare_app/core/services/app_client.dart';

class AuthService {
  final Dio _dio = ApiClient.dio;


  Future<Map<String, dynamic>?> restoreSession() async {
    final token = await ApiClient.storage.read(key: 'access_token');
    if (token == null || token.isEmpty) return null;

    try {
      final response = await _dio.get('/auth/me');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        await logout();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await ApiClient.storage.deleteAll();
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );

    final data = Map<String, dynamic>.from(response.data as Map);

    final token = data['access_token'];

    if (token == null || token.toString().isEmpty) {
      throw Exception('The server did not return an access token.');
    }

    final user = Map<String, dynamic>.from(data['user'] as Map);

    await ApiClient.storage.write(key: 'access_token', value: token.toString());

    await ApiClient.storage.write(key: 'user_id', value: user['id'].toString());

    await ApiClient.storage.write(
      key: 'user_role',
      value: user['role'].toString(),
    );

    await ApiClient.storage.write(
      key: 'username',
      value: user['username'].toString(),
    );

    return user;
  }
}
