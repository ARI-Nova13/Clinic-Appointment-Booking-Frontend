import 'package:dio/dio.dart';
import 'package:medicare_app/core/services/app_client.dart';

class PatientService {
  final Dio _dio = ApiClient.dio;

  // Get the logged-in patient's profile.
  Future<Map<String, dynamic>> getMyProfile() async {
    final response = await _dio.get('/patients/me');

    return Map<String, dynamic>.from(response.data as Map);
  }

  // Update the logged-in patient's profile.
  Future<Map<String, dynamic>> updateMyProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    final response = await _dio.patch(
      '/patients/me',
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone.isEmpty ? null : phone,
      },
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  // Get the logged-in patient's dashboard statistics and upcoming appointments.
  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _dio.get('/dashboards/patient');

    return Map<String, dynamic>.from(response.data as Map);
  }
}
