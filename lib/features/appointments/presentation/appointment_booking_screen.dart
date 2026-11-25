import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:medicare_app/features/appointments/data/appointment_service.dart';
import 'package:medicare_app/features/authentication/data/doctor_model.dart';
import 'package:medicare_app/theme/app_theme.dart';

class AppointmentBookingScreen extends StatefulWidget {
  final DoctorModel doctor;

  const AppointmentBookingScreen({super.key, required this.doctor});

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final AppointmentService _service = AppointmentService();
  final TextEditingController _reasonController = TextEditingController();

  List<AvailabilityModel> _slots = [];
  DateTime? _selectedDate;
  int? _selectedSlotId;

  bool _isLoading = true;
  bool _isBooking = false;
  String? _error;

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final slots = await _service.getDoctorAvailability(widget.doctor.id);

      slots.sort((a, b) {
        final dateComparison = a.date.compareTo(b.date);
        if (dateComparison != 0) return dateComparison;
        return a.startTime.compareTo(b.startTime);
      });

      final availableSlots = slots.where((slot) => slot.isAvailable).toList();

      if (!mounted) return;

      setState(() {
        _slots = availableSlots;

        if (_slots.isNotEmpty) {
          _selectedDate = DateUtils.dateOnly(_slots.first.date);
        }

        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.response?.data is Map
            ? (e.response?.data['detail']?.toString() ??
                  'Could not load available appointments.')
            : 'Could not connect to the server.';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Something went wrong while loading availability.';
        _isLoading = false;
      });
    }
  }

  List<DateTime> get _availableDates {
    final dates = <DateTime>{};

    for (final slot in _slots) {
      dates.add(DateUtils.dateOnly(slot.date));
    }

    return dates.toList()..sort();
  }

  List<AvailabilityModel> get _selectedDateSlots {
    if (_selectedDate == null) return [];

    return _slots.where((slot) {
      return DateUtils.isSameDay(slot.date, _selectedDate);
    }).toList();
  }

  String _formatTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return value;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return value;

    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDate(DateTime date) {
    return '${_weekdays[date.weekday - 1]}, '
        '${date.day}/${date.month}/${date.year}';
  }

  String _formatShortDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  Future<void> _bookAppointment() async {
    if (_selectedSlotId == null) {
      _showMessage('Please select an appointment time.');
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      _showMessage('Please enter the reason for your appointment.');
      return;
    }

    setState(() => _isBooking = true);

    try {
      await _service.bookAppointment(
        availabilityId: _selectedSlotId!,
        reason: _reasonController.text.trim(),
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.success,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Booking Submitted!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your appointment request has been submitted. '
                  'You can follow its status in My Appointments.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(context, true);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['detail']?.toString() ??
                'Could not book this appointment.')
          : 'Could not connect to the server.';

      if (mounted) _showMessage(message);
    } catch (_) {
      if (mounted) {
        _showMessage('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Book Appointment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildError()
            : _slots.isEmpty
            ? _buildEmpty()
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 850;

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1150),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isDesktop ? 28 : 18),
                        child: isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 4, child: _buildDoctorCard()),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 6, child: _buildBookingForm()),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildDoctorCard(),
                                  const SizedBox(height: 20),
                                  _buildBookingForm(),
                                ],
                              ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDoctorCard() {
    final doctor = widget.doctor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR DOCTOR',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                backgroundImage:
                    doctor.avatarUrl != null && doctor.avatarUrl!.isNotEmpty
                    ? NetworkImage(doctor.avatarUrl!)
                    : null,
                child: doctor.avatarUrl == null || doctor.avatarUrl!.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: AppTheme.primary,
                        size: 32,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.fullName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      doctor.specialtyName ?? 'General Practitioner',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 14),
          _doctorInfo(
            Icons.location_on_outlined,
            doctor.clinicName ?? 'Clinic information unavailable',
          ),
          if (doctor.experienceYears != null) ...[
            const SizedBox(height: 12),
            _doctorInfo(
              Icons.work_outline,
              '${doctor.experienceYears} years of experience',
            ),
          ],
          if (doctor.consultationFee != null) ...[
            const SizedBox(height: 12),
            _doctorInfo(
              Icons.payments_outlined,
              'Consultation fee: ${doctor.consultationFee}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _doctorInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppTheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose a date',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select one of the available dates below.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: _availableDates.map((date) {
              final selected =
                  _selectedDate != null &&
                  DateUtils.isSameDay(date, _selectedDate);

              return ChoiceChip(
                label: Text(_formatShortDate(date)),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _selectedDate = date;
                    _selectedSlotId = null;
                  });
                },
                selectedColor: AppTheme.primary,
                backgroundColor: AppTheme.background,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                  color: selected ? AppTheme.primary : AppTheme.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 25),
          const Text(
            'Available time slots',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedDate == null
                ? 'Choose a date first.'
                : _formatDate(_selectedDate!),
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          if (_selectedDateSlots.isEmpty)
            const Text(
              'No available times for this date.',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _selectedDateSlots.map((slot) {
                final selected = _selectedSlotId == slot.id;

                return ChoiceChip(
                  label: Text(
                    '${_formatTime(slot.startTime)} - '
                    '${_formatTime(slot.endTime)}',
                  ),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedSlotId = slot.id);
                  },
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.background,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: selected ? AppTheme.primary : AppTheme.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 28),
          const Text(
            'Reason for appointment',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Briefly describe why you need this appointment...',
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppTheme.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _isBooking ? null : _bookAppointment,
              icon: _isBooking
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.calendar_month_rounded),
              label: Text(
                _isBooking ? 'Submitting...' : 'Confirm Appointment',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 14),
            Text(
              _error ?? 'Unable to load availability.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _loadAvailability,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 54,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Available Appointments',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This doctor currently has no available time slots. '
              'Please check again later.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: _loadAvailability,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
