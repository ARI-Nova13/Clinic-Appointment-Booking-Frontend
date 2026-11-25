import 'package:dio/dio.dart';
import 'package:medicare_app/core/services/app_client.dart';

class AdminService {
  final Dio _dio = ApiClient.dio;

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _dio.get('/admin/dashboard');
    return _asMap(response.data);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await _dio.get('/admin/users');
    return _asList(response.data, keys: const ['users', 'items', 'data']);
  }

  Future<List<Map<String, dynamic>>> getDoctors() async {
    final response = await _dio.get('/admin/doctors');
    return _asList(response.data, keys: const ['doctors', 'items', 'data']);
  }

  Future<List<Map<String, dynamic>>> getPatients() async {
    final response = await _dio.get('/admin/patients');
    return _asList(response.data, keys: const ['patients', 'items', 'data']);
  }

  Future<List<Map<String, dynamic>>> getAppointments() async {
    final response = await _dio.get('/admin/appointments');
    return _asList(
      response.data,
      keys: const ['appointments', 'items', 'data'],
    );
  }

  Future<Map<String, dynamic>> setUserActive({
    required int userId,
    required bool isActive,
  }) async {
    final response = await _dio.patch(
      '/admin/users/$userId/active',
      data: {'is_active': isActive},
    );
    return _asMap(response.data);
  }

  Future<void> deleteUser(int userId) async {
    await _dio.delete('/admin/users/$userId');
  }

  Future<Map<String, dynamic>> updateAppointment({
    required int appointmentId,
    required String status,
  }) async {
    final response = await _dio.patch(
      '/admin/appointments/$appointmentId',
      data: {'status': status},
    );
    return _asMap(response.data);
  }

  Future<List<Map<String, dynamic>>> getSpecialties() async {
    final response = await _dio.get('/specialties');
    return _asList(response.data, keys: const ['specialties', 'items', 'data']);
  }

  Future<Map<String, dynamic>> createSpecialty(String name) async {
    final response = await _dio.post('/specialties', data: {'name': name});
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> updateSpecialty({
    required int specialtyId,
    required String name,
  }) async {
    final response = await _dio.patch(
      '/specialties/$specialtyId',
      data: {'name': name},
    );
    return _asMap(response.data);
  }

  Future<void> deleteSpecialty(int specialtyId) async {
    await _dio.delete('/specialties/$specialtyId');
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asList(
    dynamic value, {
    List<String> keys = const [],
  }) {
    dynamic list = value;
    if (value is Map) {
      for (final key in keys) {
        if (value[key] is List) {
          list = value[key];
          break;
        }
      }
    }
    if (list is! List) return <Map<String, dynamic>>[];
    return list
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
