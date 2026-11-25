import 'package:medicare_app/core/constants/api_constants.dart';

class DoctorModel {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String? avatarUrl;
  final int? specialtyId;
  final String? specialtyName;
  final String? bio;
  final int? consultationFee;
  final String? clinicName;
  final String? clinicAddress;
  final int? experienceYears;
  final double rating;

  const DoctorModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.avatarUrl,
    this.specialtyId,
    this.specialtyName,
    this.bio,
    this.consultationFee,
    this.clinicName,
    this.clinicAddress,
    this.experienceYears,
    required this.rating,
  });

  String get fullName => '$firstName $lastName';

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] as int,
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      avatarUrl: ApiConstants.resolveMediaUrl(json['avatar_url']?.toString()),
      specialtyId: json['specialty_id'] as int?,
      specialtyName: json['specialty_name']?.toString(),
      bio: json['bio']?.toString(),
      consultationFee: (json['consultation_fee'] as num?)?.toInt(),
      clinicName: json['clinic_name']?.toString(),
      clinicAddress: json['clinic_address']?.toString(),
      experienceYears: (json['experience_years'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SpecialtyModel {
  final int id;
  final String name;
  final String? description;

  const SpecialtyModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory SpecialtyModel.fromJson(Map<String, dynamic> json) {
    return SpecialtyModel(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}
