import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:medicare_app/features/doctors/data/doctor_panel_service.dart';
import 'package:medicare_app/theme/app_theme.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  const DoctorAvailabilityScreen({super.key});

  @override
  State<DoctorAvailabilityScreen> createState() =>
      DoctorAvailabilityScreenState();
}

class DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  final DoctorPanelService _service = DoctorPanelService();

  List<Map<String, dynamic>> _slots = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> refresh() => _loadAvailability();

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final slots = await _service.getMyAvailability();

      slots.sort((a, b) {
        final dateA =
            DateTime.tryParse('${a['date']} ${a['start_time']}') ??
            DateTime(2000);
        final dateB =
            DateTime.tryParse('${b['date']} ${b['start_time']}') ??
            DateTime(2000);
        return dateA.compareTo(dateB);
      });

      if (!mounted) return;

      setState(() {
        _slots = slots;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _errorMessage(e);
        _isLoading = false;
      });
    }
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final response = error.response;
      final data = response?.data;

      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }

      if (response != null) {
        return 'Request failed (${response.statusCode}). Please try again.';
      }

      return 'Unable to reach the server. Check your connection.';
    }

    return error.toString();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _displayTime(dynamic value) {
    if (value == null) return '--:--';

    final parts = value.toString().split(':');
    if (parts.length < 2) return value.toString();

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return value.toString();

    final time = TimeOfDay(hour: hour, minute: minute);
    final hourText = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minuteText = minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hourText:$minuteText $period';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(DateTime.now())
          ? DateTime.now()
          : _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null && mounted) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 9, minute: 30),
    );

    if (picked != null && mounted) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _createAvailability() async {
    if (_isSaving) return;

    if (_startTime == null || _endTime == null) {
      _showMessage('Please select both start and end times.');
      return;
    }

    final now = DateTime.now();

    // Normalize the selected date and today's date.
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    final today = DateTime(now.year, now.month, now.day);

    // Reject dates in the past.
    if (selectedDay.isBefore(today)) {
      _showMessage('You cannot create availability for a past date.');
      return;
    }

    // Convert selected times into minutes for comparison.
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;

    if (endMinutes <= startMinutes) {
      _showMessage('End time must be later than start time.');
      return;
    }

    // For today's date, the start time must still be in the future.
    if (selectedDay.isAtSameMomentAs(today)) {
      final selectedStart = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      if (!selectedStart.isAfter(now)) {
        _showMessage(
          'For today, choose a start time later than the current time.',
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      await _service.createAvailability(
        date: _selectedDate,
        startTime: _formatTime(_startTime!),
        endTime: _formatTime(_endTime!),
      );

      if (!mounted) return;

      setState(() {
        _startTime = null;
        _endTime = null;
      });

      _showMessage('Availability slot created successfully.');

      await _loadAvailability();
    } catch (e) {
      if (!mounted) return;

      _showMessage(_errorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteAvailability(int slotId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete availability'),
        content: const Text(
          'Are you sure you want to delete this availability slot?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteAvailability(slotId);

      if (!mounted) return;

      _showMessage('Availability slot deleted.');
      await _loadAvailability();
    } catch (e) {
      if (!mounted) return;
      _showMessage(_errorMessage(e));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isAvailable(Map<String, dynamic> slot) {
    return slot['is_available'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _loadAvailability,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildError()
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isWide ? 28 : 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildCreateCard()),
                        const SizedBox(width: 24),
                        Expanded(child: _buildInformationCard()),
                      ],
                    )
                  else ...[
                    _buildCreateCard(),
                    const SizedBox(height: 16),
                    _buildInformationCard(),
                  ],
                  const SizedBox(height: 30),
                  _buildSlotsHeader(),
                  const SizedBox(height: 14),
                  if (_slots.isEmpty)
                    _buildEmptyState()
                  else
                    ..._slots.map(_buildSlotCard),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Availability',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage your appointment time slots.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create availability',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          _selectionTile(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: _formatDate(_selectedDate),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          _selectionTile(
            icon: Icons.access_time,
            label: 'Start time',
            value: _startTime == null
                ? 'Select start time'
                : _startTime!.format(context),
            onTap: _pickStartTime,
          ),
          const SizedBox(height: 12),
          _selectionTile(
            icon: Icons.access_time_filled,
            label: 'End time',
            value: _endTime == null
                ? 'Select end time'
                : _endTime!.format(context),
            onTap: _pickEndTime,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _createAvailability,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(_isSaving ? 'Creating...' : 'Add availability'),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Availability overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          _infoRow(Icons.event_available, 'Total slots', '${_slots.length}'),
          const Divider(height: 24),
          _infoRow(
            Icons.check_circle_outline,
            'Available slots',
            '${_slots.where(_isAvailable).length}',
          ),
          const Divider(height: 24),
          _infoRow(
            Icons.event_busy,
            'Booked slots',
            '${_slots.where((slot) => !_isAvailable(slot)).length}',
          ),
          const SizedBox(height: 14),
          Text(
            'Patients can book appointments during your available time slots.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Your time slots',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Text(
          '${_slots.length} slots',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSlotCard(Map<String, dynamic> slot) {
    final available = _isAvailable(slot);
    final slotId = int.tryParse(slot['id'].toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatSlotDate(slot['date']),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_displayTime(slot['start_time'])} - '
                  '${_displayTime(slot['end_time'])}',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: available
                  ? AppTheme.success.withValues(alpha: 0.12)
                  : Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              available ? 'Available' : 'Booked',
              style: TextStyle(
                color: available ? AppTheme.success : Colors.orange[800],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (available && slotId != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Delete slot',
              onPressed: () => _deleteAvailability(slotId),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  String _formatSlotDate(dynamic value) {
    final date = DateTime.tryParse(value.toString());
    return date == null ? value.toString() : _formatDate(date);
  }

  Widget _buildEmptyState() {
    return _card(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 48,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 12),
              const Text(
                'No availability slots yet',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create your first slot using the form above.',
                style: TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
            const Icon(Icons.error_outline, size: 44, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _selectionTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: TextStyle(color: AppTheme.textSecondary)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );
  }
}
