import 'package:dio/dio.dart';
import 'package:medicare_app/core/services/app_client.dart';
import 'package:medicare_app/features/authentication/data/doctor_model.dart';

class DoctorService {
  final Dio _dio = ApiClient.dio;

  Future<List<DoctorModel>> getDoctors({
    String? search,
    int? specialtyId,
  }) async {
    final response = await _dio.get(
      '/doctors',
      queryParameters: {
        if (search case final value?)
          if (value.trim().isNotEmpty) 'q': value.trim(),
        'specialty_id': ?specialtyId,
      },
    );

    final data = response.data as List;

    return data
        .map(
          (item) =>
              DoctorModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<SpecialtyModel>> getSpecialties() async {
    final response = await _dio.get('/specialties');

    final data = response.data as List;

    return data
        .map(
          (item) =>
              SpecialtyModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }
}
