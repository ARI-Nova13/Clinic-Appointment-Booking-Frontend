import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:medicare_app/theme/app_theme.dart';
import 'package:medicare_app/features/appointments/data/appointment_model.dart';
import 'package:medicare_app/features/appointments/data/appointment_service.dart';

class MyAppointmentsScreen extends StatefulWidget {
  final VoidCallback? onAppointmentsChanged;

  const MyAppointmentsScreen({super.key, this.onAppointmentsChanged});

  @override
  State<MyAppointmentsScreen> createState() => MyAppointmentsScreenState();
}

class MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final AppointmentService _service = AppointmentService();

  List<AppointmentModel> _appointments = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All';
  bool _isRescheduling = false;

  final List<String> _filters = ['All', 'Upcoming', 'Completed', 'Cancelled', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> refresh() => _loadAppointments();

  Future<void> _loadAppointments() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final appointments = await _service.getMyAppointments();

      if (!mounted) return;

      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.response?.data is Map
            ? e.response?.data['detail']?.toString()
            : e.message ?? 'Unable to load appointments.';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Something went wrong while loading appointments.';
        _isLoading = false;
      });
    }
  }

  List<AppointmentModel> get _filteredAppointments {
    switch (_selectedFilter) {
      case 'Upcoming':
        return _appointments.where((appointment) => appointment.isUpcoming).toList();

      case 'Completed':
        return _appointments.where((a) => a.status == 'completed').toList();

      case 'Cancelled':
        return _appointments.where((a) => a.status == 'cancelled').toList();

      case 'Rejected':
        return _appointments.where((a) => a.status == 'rejected').toList();

      default:
        return _appointments;
    }
  }

  Future<void> _cancelAppointment(AppointmentModel appointment) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _CancellationReasonDialog(),
    );

    if (reason == null || !mounted) return;

    try {
      await _service.cancelAppointment(
        appointmentId: appointment.id,
        reason: reason,
      );

      if (!mounted) return;
      widget.onAppointmentsChanged?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment cancelled successfully.'),
          backgroundColor: AppTheme.success,
        ),
      );

      await _loadAppointments();
    } on DioException catch (e) {
      if (!mounted) return;

      final message = e.response?.data is Map
          ? e.response?.data['detail']?.toString()
          : null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? 'Could not cancel appointment.'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }
  }

  DateTime? _slotStart(AvailabilityModel slot) {
    final parts = slot.startTime.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(slot.date.year, slot.date.month, slot.date.day, hour, minute);
  }

  Future<void> _rescheduleAppointment(AppointmentModel appointment) async {
    if (_isRescheduling) return;
    setState(() => _isRescheduling = true);

    try {
      final availableSlots = await _service.getDoctorAvailability(
        appointment.doctorId,
      );
      final now = DateTime.now();
      final futureSlots = availableSlots
          .where((slot) {
            final startsAt = _slotStart(slot);
            return slot.isAvailable && startsAt != null && startsAt.isAfter(now);
          })
          .toList();

      if (!mounted) return;
      if (futureSlots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('There are no available future slots for this doctor.')),
        );
        return;
      }

      final selectedSlot = await showDialog<AvailabilityModel>(
        context: context,
        builder: (_) => _RescheduleSlotDialog(slots: futureSlots),
      );
      if (!mounted || selectedSlot == null) return;

      await _service.rescheduleAppointment(
        appointmentId: appointment.id,
        availabilityId: selectedSlot.id,
      );

      if (!mounted) return;
      widget.onAppointmentsChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment rescheduled. It is now awaiting doctor confirmation.'),
          backgroundColor: AppTheme.success,
        ),
      );
      await _loadAppointments();
    } on DioException catch (error) {
      if (!mounted) return;
      final data = error.response?.data;
      final message = data is Map && data['detail'] != null
          ? data['detail'].toString()
          : 'Could not reschedule appointment. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong while rescheduling.')),
      );
    } finally {
      if (mounted) setState(() => _isRescheduling = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF16865C);
      case 'pending':
        return const Color(0xFFD58B20);
      case 'completed':
        return const Color(0xFF3978C5);
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFD65353);
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.schedule;
      case 'completed':
        return Icons.task_alt;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return time;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];

    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour:$minute $period';
  }

  Widget _buildHeader(bool isWide) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Appointments',
                style: TextStyle(
                  fontSize: isWide ? 28 : 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage your visits and keep track of your healthcare.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final selected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 9),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) {
                setState(() => _selectedFilter = filter);
              },
              selectedColor: AppTheme.primary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: selected ? AppTheme.primary : AppTheme.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    final statusColor = _statusColor(appointment.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.09),
                backgroundImage: appointment.doctorAvatarUrl == null ||
                        appointment.doctorAvatarUrl!.isEmpty
                    ? null
                    : NetworkImage(appointment.doctorAvatarUrl!),
                child: appointment.doctorAvatarUrl == null ||
                        appointment.doctorAvatarUrl!.isEmpty
                    ? const Icon(
                        Icons.medical_services_outlined,
                        color: AppTheme.primary,
                        size: 24,
                      )
                    : null,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName?.trim().isNotEmpty == true
                          ? appointment.doctorName!
                          : 'Doctor #${appointment.doctorId}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.specialtyName ?? 'Medical specialist',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _statusIcon(appointment.status),
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      appointment.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _infoItem(
                  Icons.calendar_today_outlined,
                  'DATE',
                  _formatDate(appointment.date),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoItem(
                  Icons.access_time,
                  'TIME',
                  '${_formatTime(appointment.startTime)} - '
                      '${_formatTime(appointment.endTime)}',
                ),
              ),
            ],
          ),
          if (appointment.reason?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _infoItem(
              Icons.notes_outlined,
              'REASON FOR VISIT',
              appointment.reason!,
            ),
          ],
          if (appointment.cancellationReason?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _infoItem(
              Icons.info_outline,
              'CANCELLATION REASON',
              appointment.cancellationReason!,
            ),
          ],
          if (appointment.canCancel) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isRescheduling
                        ? null
                        : () => _rescheduleAppointment(appointment),
                    icon: const Icon(Icons.event_repeat_rounded, size: 17),
                    label: const Text('Reschedule'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isRescheduling
                        ? null
                        : () => _cancelAppointment(appointment),
                    icon: const Icon(Icons.close, size: 17),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 55),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: AppTheme.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No appointments found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All'
                ? 'Your appointments will appear here once you book a visit.'
                : 'There are no ${_selectedFilter.toLowerCase()} appointments.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isWide) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    final appointments = _filteredAppointments;

    if (appointments.isEmpty) {
      return _buildEmptyState();
    }

    if (isWide) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: appointments.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 540,
          mainAxisExtent: 290,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
        ),
        itemBuilder: (context, index) {
          return _buildAppointmentCard(appointments[index]);
        },
      );
    }

    return Column(
      children: appointments.map((appointment) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: _buildAppointmentCard(appointment),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;

        return Container(
          color: AppTheme.background,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 20,
              vertical: 28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isWide),
                    const SizedBox(height: 28),
                    _buildFilters(),
                    const SizedBox(height: 24),
                    _buildContent(isWide),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


class _CancellationReasonDialog extends StatefulWidget {
  const _CancellationReasonDialog();

  @override
  State<_CancellationReasonDialog> createState() =>
      _CancellationReasonDialogState();
}

class _CancellationReasonDialogState extends State<_CancellationReasonDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a cancellation reason.')),
      );
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel appointment?'),
      content: TextField(
        controller: _reasonController,
        maxLines: 3,
        maxLength: 500,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: 'Enter cancellation reason...',
          labelText: 'Reason',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep appointment'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Cancel appointment'),
        ),
      ],
    );
  }
}


class _RescheduleSlotDialog extends StatelessWidget {
  const _RescheduleSlotDialog({required this.slots});

  final List<AvailabilityModel> slots;

  String _formatTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return value;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return value;
    final time = TimeOfDay(hour: hour, minute: minute);
    final hourText = (time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod).toString();
    return '$hourText:${minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return AlertDialog(
      title: const Text('Choose a new appointment time'),
      content: SizedBox(
        width: 420,
        height: height < 650 ? height * 0.45 : 360,
        child: ListView.separated(
          itemCount: slots.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final slot = slots[index];
            return ListTile(
              leading: const Icon(Icons.event_available_rounded, color: AppTheme.primary),
              title: Text(_formatDate(slot.date)),
              subtitle: Text('${_formatTime(slot.startTime)} – ${_formatTime(slot.endTime)}'),
              onTap: () => Navigator.of(context).pop(slot),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
