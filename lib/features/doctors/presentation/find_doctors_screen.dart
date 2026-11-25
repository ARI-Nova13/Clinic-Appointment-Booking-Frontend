import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:medicare_app/features/appointments/presentation/appointment_booking_screen.dart';
import 'package:medicare_app/features/authentication/data/doctor_model.dart';
import 'package:medicare_app/theme/app_theme.dart';

import '../data/doctor_service.dart';

class FindDoctorsScreen extends StatefulWidget {
  final VoidCallback? onAppointmentBooked;

  const FindDoctorsScreen({super.key, this.onAppointmentBooked});

  @override
  State<FindDoctorsScreen> createState() => FindDoctorsScreenState();
}

class FindDoctorsScreenState extends State<FindDoctorsScreen> {
  final DoctorService _service = DoctorService();
  final TextEditingController _searchController = TextEditingController();

  List<DoctorModel> _doctors = [];
  List<SpecialtyModel> _specialties = [];

  bool _isLoading = true;
  String? _error;
  int? _selectedSpecialtyId;

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> refresh() => _loadInitialData();

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.getDoctors(),
        _service.getSpecialties(),
      ]);

      if (!mounted) return;

      setState(() {
        _doctors = results[0] as List<DoctorModel>;
        _specialties = results[1] as List<SpecialtyModel>;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _getErrorMessage(e);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong while loading doctors.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final doctors = await _service.getDoctors(
        search: _searchController.text,
        specialtyId: _selectedSpecialtyId,
      );

      if (!mounted) return;

      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _getErrorMessage(e);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load doctors. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 450), _loadDoctors);
  }

  String _getErrorMessage(DioException error) {
    if (error.response?.statusCode == 401) {
      return 'Your session may have expired. Please log in again.';
    }

    if (error.response?.statusCode == 403) {
      return 'You do not have permission to view this information.';
    }

    if (error.response == null) {
      return 'Cannot connect to the server. Check that your backend is running.';
    }

    final data = error.response?.data;

    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }

    return 'Server error (${error.response?.statusCode}). Please try again.';
  }

  void _selectSpecialty(int? id) {
    setState(() {
      _selectedSpecialtyId = id;
    });

    _loadDoctors();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isWide ? 34 : 20,
            25,
            isWide ? 34 : 20,
            35,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find your doctor',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Find the right specialist for your healthcare needs.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 23),

                  _buildSearchField(),

                  const SizedBox(height: 24),

                  const Text(
                    'Specialties',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 13),

                  _buildSpecialtyFilters(),

                  const SizedBox(height: 25),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Available Doctors',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${_doctors.length} found',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 70),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  else if (_error != null)
                    _buildError()
                  else if (_doctors.isEmpty)
                    _buildEmptyState()
                  else
                    _buildDoctorGrid(
                      (constraints.maxWidth - (isWide ? 68 : 40)).clamp(
                        0.0,
                        1200.0,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search doctor or clinic...',
          hintStyle: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _loadDoctors();
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 17),
        ),
      ),
    );
  }

  Widget _buildSpecialtyFilters() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _specialtyChip(label: 'All', id: null),
          ..._specialties.map(
            (specialty) =>
                _specialtyChip(label: specialty.name, id: specialty.id),
          ),
        ],
      ),
    );
  }

  Widget _specialtyChip({required String label, required int? id}) {
    final selected = _selectedSpecialtyId == id;

    return Padding(
      padding: const EdgeInsets.only(right: 9),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => _selectSpecialty(id),
        showCheckmark: false,
        selectedColor: AppTheme.primary,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? AppTheme.primary : AppTheme.border),
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDoctorGrid(double availableWidth) {
    final width = availableWidth >= 1100
        ? 350.0
        : availableWidth >= 700
        ? (availableWidth - 16) / 2
        : availableWidth;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: _doctors.map((doctor) {
        return SizedBox(
          width: width,
          child: _DoctorCard(
            doctor: doctor,
            onTap: () => _showDoctorDetails(doctor),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppTheme.textSecondary,
            size: 40,
          ),
          const SizedBox(height: 13),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_search_rounded,
            size: 45,
            color: AppTheme.primary.withValues(alpha: 0.65),
          ),
          const SizedBox(height: 14),
          const Text(
            'No doctors found',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Try another search or select a different specialty.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 15),
          TextButton(
            onPressed: () {
              _searchController.clear();
              _selectSpecialty(null);
            },
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }

  void _showDoctorDetails(DoctorModel doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _DoctorDetailsSheet(
          doctor: doctor,
          onAppointmentBooked: widget.onAppointmentBooked,
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// DOCTOR CARD
// -----------------------------------------------------------------------------

class _DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onTap;

  const _DoctorCard({required this.doctor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 13,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _DoctorAvatar(doctor: doctor, radius: 29),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        doctor.specialtyName ?? 'General Doctor',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),

            const SizedBox(height: 17),
            const Divider(color: AppTheme.border),
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: Color(0xFFE6A23C),
                ),
                const SizedBox(width: 5),
                Text(
                  doctor.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.work_outline_rounded,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  doctor.experienceYears == null
                      ? 'Experience N/A'
                      : '${doctor.experienceYears} years',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),

            if (doctor.clinicName != null && doctor.clinicName!.isNotEmpty) ...[
              const SizedBox(height: 13),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      doctor.clinicName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 17),

            Row(
              children: [
                Expanded(
                  child: Text(
                    doctor.consultationFee == null
                        ? 'Fee not specified'
                        : 'Fee: ${doctor.consultationFee}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Text(
                  'View details',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// DOCTOR AVATAR
// -----------------------------------------------------------------------------

class _DoctorAvatar extends StatelessWidget {
  final DoctorModel doctor;
  final double radius;

  const _DoctorAvatar({required this.doctor, required this.radius});

  @override
  Widget build(BuildContext context) {
    final hasImage =
        doctor.avatarUrl != null && doctor.avatarUrl!.trim().isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primary.withValues(alpha: 0.10),
      backgroundImage: hasImage ? NetworkImage(doctor.avatarUrl!) : null,
      onBackgroundImageError: hasImage ? (_, _) {} : null,
      child: hasImage
          ? null
          : Text(
              '${doctor.firstName.isNotEmpty ? doctor.firstName[0] : '?'}'
                      '${doctor.lastName.isNotEmpty ? doctor.lastName[0] : ''}'
                  .toUpperCase(),
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.65,
              ),
            ),
    );
  }
}

// -----------------------------------------------------------------------------
// DOCTOR DETAILS
// -----------------------------------------------------------------------------

class _DoctorDetailsSheet extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback? onAppointmentBooked;

  const _DoctorDetailsSheet({required this.doctor, this.onAppointmentBooked});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(24, 15, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Center(
              child: Column(
                children: [
                  _DoctorAvatar(doctor: doctor, radius: 42),
                  const SizedBox(height: 14),
                  Text(
                    doctor.fullName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    doctor.specialtyName ?? 'General Doctor',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'About Doctor',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              doctor.bio?.isNotEmpty == true
                  ? doctor.bio!
                  : 'No biography has been provided yet.',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 22),
            _detailRow(
              Icons.star_rounded,
              'Rating',
              doctor.rating.toStringAsFixed(1),
            ),
            _detailRow(
              Icons.work_outline_rounded,
              'Experience',
              doctor.experienceYears == null
                  ? 'Not specified'
                  : '${doctor.experienceYears} years',
            ),
            _detailRow(
              Icons.payments_outlined,
              'Consultation fee',
              doctor.consultationFee == null
                  ? 'Not specified'
                  : doctor.consultationFee.toString(),
            ),
            _detailRow(
              Icons.local_hospital_outlined,
              'Clinic',
              doctor.clinicName ?? 'Not specified',
            ),
            _detailRow(
              Icons.location_on_outlined,
              'Address',
              doctor.clinicAddress ?? 'Not specified',
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final booked = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => AppointmentBookingScreen(doctor: doctor),
                    ),
                  );

                  if (booked == true) {
                    onAppointmentBooked?.call();

                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 19),
          const SizedBox(width: 12),
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
