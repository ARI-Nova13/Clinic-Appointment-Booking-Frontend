import 'package:flutter/material.dart';
import 'package:medicare_app/features/doctors/data/doctor_panel_service.dart';
import 'package:medicare_app/theme/app_theme.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  final VoidCallback? onAppointmentsUpdated;

  const DoctorAppointmentsScreen({super.key, this.onAppointmentsUpdated});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      DoctorAppointmentsScreenState();
}

class DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  final DoctorPanelService _service = DoctorPanelService();
  final TextEditingController _notesController = TextEditingController();

  List<Map<String, dynamic>> _appointments = [];
  String _selectedStatus = '';
  bool _isLoading = true;
  String? _error;

  final List<String> _filters = [
    'All',
    'Pending',
    'Confirmed',
    'Completed',
    'Rejected',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> refresh() => _loadAppointments();

  Future<void> _loadAppointments() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.getAppointments(
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
      );

      if (!mounted) return;

      setState(() {
        _appointments = result;
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
    final message = error.toString();

    if (message.contains('401')) {
      return 'Your session has expired. Please log in again.';
    }

    if (message.contains('403')) {
      return 'You do not have permission to view these appointments.';
    }

    return 'Could not load appointments. Please try again.';
  }

  Future<void> _updateAppointment(
    Map<String, dynamic> appointment,
    String status,
  ) async {
    final id = appointment['id'];

    if (id is! int) {
      _showMessage('Invalid appointment ID.');
      return;
    }

    try {
      await _service.updateAppointment(
        appointmentId: id,
        status: status,
        doctorNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;

      _notesController.clear();
      widget.onAppointmentsUpdated?.call();
      _showMessage('Appointment updated successfully.');
      await _loadAppointments();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not update appointment. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showDecisionDialog(Map<String, dynamic> appointment, String status) {
    final action = status == 'confirmed'
        ? 'Confirm'
        : status == 'rejected'
        ? 'Reject'
        : 'Complete';

    _notesController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('$action Appointment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Patient: ${appointment['patient_name'] ?? 'Patient'}'),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Doctor notes (optional)',
                  hintText: 'Add notes for this appointment...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _updateAppointment(appointment, status);
              },
              child: Text(action),
            ),
          ],
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppTheme.success;
      case 'completed':
        return Colors.blue;
      case 'rejected':
      case 'cancelled':
        return Colors.redAccent;
      case 'pending':
        return Colors.orange;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Date unavailable';

    try {
      final date = DateTime.parse(value.toString());
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final status = (appointment['status'] ?? 'unknown')
        .toString()
        .toLowerCase();

    final patientName =
        appointment['patient_name']?.toString() ?? 'Unknown patient';

    final date = _formatDate(appointment['date']);
    final startTime = appointment['start_time']?.toString() ?? '--:--';
    final endTime = appointment['end_time']?.toString() ?? '--:--';

    final canDecide = status == 'pending';
    final canComplete = status == 'confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.person_outline,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Appointment #${appointment['id'] ?? '-'}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(date, style: const TextStyle(color: AppTheme.textPrimary)),
              const SizedBox(width: 18),
              const Icon(
                Icons.access_time,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$startTime - $endTime',
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
          if (appointment['reason'] != null &&
              appointment['reason'].toString().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Reason',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              appointment['reason'].toString(),
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ],
          if (appointment['doctor_notes'] != null &&
              appointment['doctor_notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Doctor notes',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              appointment['doctor_notes'].toString(),
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ],
          if (canDecide || canComplete) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (canDecide)
                  FilledButton.icon(
                    onPressed: () =>
                        _showDecisionDialog(appointment, 'confirmed'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Confirm'),
                  ),
                if (canDecide)
                  OutlinedButton.icon(
                    onPressed: () =>
                        _showDecisionDialog(appointment, 'rejected'),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                  ),
                if (canComplete)
                  FilledButton.icon(
                    onPressed: () =>
                        _showDecisionDialog(appointment, 'completed'),
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('Complete'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointments',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Review and manage your patient appointments.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 850;
            final pagePadding = isWide ? 28.0 : 18.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        pagePadding,
                        isWide ? 28 : 24,
                        pagePadding,
                        0,
                      ),
                      child: _buildPageHeader(),
                    ),
                    SizedBox(
                      height: 66,
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: pagePadding,
                          vertical: 12,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final filter = _filters[index];
                          final value = filter == 'All'
                              ? ''
                              : filter.toLowerCase();
                          final selected = _selectedStatus == value;

                          return ChoiceChip(
                            label: Text(filter),
                            selected: selected,
                            onSelected: (_) {
                              setState(() => _selectedStatus = value);
                              _loadAppointments();
                            },
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.redAccent,
                                      size: 42,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(_error!, textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            )
                          : _appointments.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.all(pagePadding),
                              children: const [
                                SizedBox(height: 90),
                                Icon(
                                  Icons.event_busy_outlined,
                                  size: 52,
                                  color: AppTheme.textSecondary,
                                ),
                                SizedBox(height: 12),
                                Center(
                                  child: Text(
                                    'No appointments found',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : RefreshIndicator(
                              onRefresh: _loadAppointments,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.all(pagePadding),
                                itemCount: _appointments.length,
                                itemBuilder: (context, index) =>
                                    _buildAppointmentCard(_appointments[index]),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
