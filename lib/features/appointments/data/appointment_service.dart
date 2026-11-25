import 'package:dio/dio.dart';
import 'package:medicare_app/core/services/app_client.dart';
import 'package:medicare_app/features/appointments/data/appointment_model.dart';

class AvailabilityModel {
  final int id;
  final int doctorId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final bool isAvailable;

  const AvailabilityModel({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityModel(
      id: json['id'] as int,
      doctorId: json['doctor_id'] as int,
      date: DateTime.parse(json['date'].toString()),
      startTime: json['start_time'].toString(),
      endTime: json['end_time'].toString(),
      isAvailable: json['is_available'] as bool? ?? false,
    );
  }
}

class AppointmentService {
  final Dio _dio = ApiClient.dio;

  Future<List<AvailabilityModel>> getDoctorAvailability(int doctorId) async {
    final response = await _dio.get('/doctors/$doctorId/availability');

    final data = response.data as List;

    return data.map((item) {
      return AvailabilityModel.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  Future<Map<String, dynamic>> bookAppointment({
    required int availabilityId,
    required String reason,
  }) async {
    final response = await _dio.post(
      '/appointments',
      data: {'availability_id': availabilityId, 'reason': reason},
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<AppointmentModel>> getMyAppointments() async {
    final response = await _dio.get('/appointments/me');

    final data = response.data as List;

    return data.map((item) {
      return AppointmentModel.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  Future<AppointmentModel> rescheduleAppointment({
    required int appointmentId,
    required int availabilityId,
  }) async {
    final response = await _dio.post(
      '/appointments/$appointmentId/reschedule',
      data: {'availability_id': availabilityId},
    );
    return AppointmentModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<AppointmentModel> cancelAppointment({
    required int appointmentId,
    required String reason,
  }) async {
    final response = await _dio.post(
      '/appointments/$appointmentId/cancel',
      data: {'reason': reason},
    );

    return AppointmentModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
