import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medicare_app/core/services/app_client.dart';

class DoctorPanelService {
  final Dio _dio = ApiClient.dio;

  // ─────────────────────────────────────────────
  // DASHBOARD
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _dio.get('/dashboards/doctor');

    return Map<String, dynamic>.from(response.data as Map);
  }

  // ─────────────────────────────────────────────
  // APPOINTMENTS
  // ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAppointments({
    DateTime? dateFilter,
    String? status,
  }) async {
    final response = await _dio.get(
      '/doctor/appointments',
      queryParameters: {
        if (dateFilter != null) 'date_filter': _formatDate(dateFilter),
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );

    final data = response.data as List;

    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> updateAppointment({
    required int appointmentId,
    required String status,
    String? doctorNotes,
  }) async {
    final response = await _dio.patch(
      '/doctor/appointments/$appointmentId',
      data: {'status': status, 'doctor_notes': doctorNotes},
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  // ─────────────────────────────────────────────
  // AVAILABILITY
  // ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMyAvailability({
    DateTime? dateFrom,
  }) async {
    final response = await _dio.get(
      '/availability/me',
      queryParameters: {
        if (dateFrom != null) 'date_from': _formatDate(dateFrom),
      },
    );

    final data = response.data as List;

    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> createAvailability({
    required DateTime date,
    required String startTime,
    required String endTime,
  }) async {
    final response = await _dio.post(
      '/availability',
      data: {
        'date': _formatDate(date),
        'start_time': startTime,
        'end_time': endTime,
      },
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> deleteAvailability(int slotId) async {
    final response = await _dio.delete('/availability/$slotId');

    if (response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }

    return {'message': 'Availability deleted'};
  }

  // ─────────────────────────────────────────────
  // SPECIALTIES
  // ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSpecialties() async {
    final response = await _dio.get('/specialties');

    final data = response.data as List;

    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  // ─────────────────────────────────────────────
  // DOCTOR PROFILE
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getMyProfile() async {
    final response = await _dio.get('/doctors/me');

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateMyProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    int? specialtyId,
    String? bio,
    int? consultationFee,
    String? clinicName,
    String? clinicAddress,
    int? experienceYears,
  }) async {
    final data = <String, dynamic>{};

    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (specialtyId != null) data['specialty_id'] = specialtyId;
    if (bio != null) data['bio'] = bio;
    if (consultationFee != null) {
      data['consultation_fee'] = consultationFee;
    }
    if (clinicName != null) data['clinic_name'] = clinicName;
    if (clinicAddress != null) {
      data['clinic_address'] = clinicAddress;
    }
    if (experienceYears != null) {
      data['experience_years'] = experienceYears;
    }

    final response = await _dio.patch('/doctors/me', data: data);

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> uploadMyAvatar(XFile image) async {
    final bytes = await image.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('The selected image is empty.');
    }
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: image.name),
    });
    final response = await _dio.post(
      '/doctors/me/avatar',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
