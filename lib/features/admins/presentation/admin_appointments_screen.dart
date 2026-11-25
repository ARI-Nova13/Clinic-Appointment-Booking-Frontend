import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:medicare_app/features/admins/data/admin_service.dart';
import 'package:medicare_app/theme/app_theme.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});
  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  final AdminService _service = AdminService();
  List<Map<String, dynamic>> _appointments = [];
  bool _loading = true;
  String? _error;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.getAppointments();
      if (!mounted) return;
      setState(() {
        _appointments = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final message = e is DioException
          ? ((e.response?.data is Map && e.response?.data['detail'] != null)
                ? e.response?.data['detail'].toString()
                : e.message ?? 'Unable to load appointments.')
          : e.toString();
      setState(() {
        _error = message;
        _loading = false;
      });
    }
  }

  Future<void> _changeStatus(
    Map<String, dynamic> appointment,
    String status,
  ) async {
    final id = int.tryParse('${appointment['id']}');
    if (id == null) return;
    try {
      await _service.updateAppointment(appointmentId: id, status: status);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Appointment marked $status.')));
      await refresh();
    } catch (e) {
      if (!mounted) return;
      final message = e is DioException
          ? ((e.response?.data is Map && e.response?.data['detail'] != null)
                ? e.response?.data['detail'].toString()
                : e.message ?? 'Could not update appointment.')
          : e.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message!)));
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 850;
      final items = _filter == 'All'
          ? _appointments
          : _appointments
                .where(
                  (a) =>
                      (a['status'] ?? '').toString().toLowerCase() ==
                      _filter.toLowerCase(),
                )
                .toList();
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: EdgeInsets.all(wide ? 28 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appointments',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Monitor and manage clinic appointments.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 18),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        [
                          'All',
                          'pending',
                          'confirmed',
                          'completed',
                          'cancelled',
                          'rejected',
                        ].map((value) {
                          final selected =
                              _filter == value ||
                              (_filter == 'All' && value == 'All');
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                value == 'All'
                                    ? 'All'
                                    : value[0].toUpperCase() +
                                          value.substring(1),
                              ),
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => _filter = value),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: refresh,
                          child: items.isEmpty
                              ? ListView(
                                  children: const [
                                    SizedBox(height: 100),
                                    Center(
                                      child: Text('No appointments found.'),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final a = items[index];
                                    final status = (a['status'] ?? '')
                                        .toString()
                                        .toLowerCase();
                                    final dateTime =
                                        '${a['date'] ?? ''}  ${a['start_time'] ?? ''}';
                                    return Card(
                                      elevation: 0,
                                      color: AppTheme.surface,
                                      margin: const EdgeInsets.only(bottom: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: const BorderSide(
                                          color: AppTheme.border,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.event_note_rounded,
                                                  color: AppTheme.primary,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    'Appointment #${a['id'] ?? ''}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  status.isEmpty
                                                      ? 'Unknown'
                                                      : status,
                                                  style: const TextStyle(
                                                    color: AppTheme.primary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'Patient: ${a['patient_name'] ?? '—'}',
                                            ),
                                            Text(
                                              'Doctor: ${a['doctor_name'] ?? '—'}',
                                            ),
                                            Text('Date: $dateTime'),
                                            if ((a['reason'] ?? '')
                                                .toString()
                                                .isNotEmpty)
                                              Text('Reason: ${a['reason']}'),
                                            if (status == 'pending' ||
                                                status == 'confirmed') ...[
                                              const Divider(height: 20),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  if (status == 'pending')
                                                    OutlinedButton(
                                                      onPressed: () =>
                                                          _changeStatus(
                                                            a,
                                                            'confirmed',
                                                          ),
                                                      child: const Text(
                                                        'Confirm',
                                                      ),
                                                    ),
                                                  if (status == 'pending' ||
                                                      status == 'confirmed')
                                                    OutlinedButton(
                                                      onPressed: () =>
                                                          _changeStatus(
                                                            a,
                                                            'cancelled',
                                                          ),
                                                      child: const Text(
                                                        'Cancel appointment',
                                                      ),
                                                    ),
                                                  if (status == 'confirmed')
                                                    FilledButton(
                                                      onPressed: () =>
                                                          _changeStatus(
                                                            a,
                                                            'completed',
                                                          ),
                                                      child: const Text(
                                                        'Complete',
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
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
