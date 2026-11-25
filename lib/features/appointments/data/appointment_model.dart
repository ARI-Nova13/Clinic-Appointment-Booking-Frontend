import 'package:medicare_app/core/constants/api_constants.dart';

class AppointmentModel {
  final int id;
  final int patientId;
  final int doctorId;
  final int availabilityId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String status;
  final String? reason;
  final String? doctorNotes;
  final String? cancellationReason;
  final String? doctorName;
  final String? doctorAvatarUrl;
  final String? specialtyName;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.availabilityId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.reason,
    this.doctorNotes,
    this.cancellationReason,
    this.doctorName,
    this.doctorAvatarUrl,
    this.specialtyName,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as int,
      patientId: json['patient_id'] as int,
      doctorId: json['doctor_id'] as int,
      availabilityId: json['availability_id'] as int,
      date: DateTime.parse(json['date'].toString()),
      startTime: json['start_time'].toString(),
      endTime: json['end_time'].toString(),
      status: json['status']?.toString() ?? 'pending',
      reason: json['reason']?.toString(),
      doctorNotes: json['doctor_notes']?.toString(),
      cancellationReason: json['cancellation_reason']?.toString(),
      doctorName: json['doctor_name']?.toString(),
      doctorAvatarUrl: ApiConstants.resolveMediaUrl(
        json['doctor_avatar_url']?.toString(),
      ),
      specialtyName: json['specialty_name']?.toString(),
    );
  }

  bool get canCancel =>
      (status == 'pending' || status == 'confirmed') && isUpcoming;

  bool get isUpcoming {
    if (status != 'pending' && status != 'confirmed') return false;
    final parts = startTime.split(':');
    if (parts.length < 2) return false;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return false;
    final startsAt = DateTime(date.year, date.month, date.day, hour, minute);
    return startsAt.isAfter(DateTime.now());
  }
}
