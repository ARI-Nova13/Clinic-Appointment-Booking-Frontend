import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:medicare_app/features/admins/data/admin_service.dart';
import 'package:medicare_app/features/admins/presentation/admin_appointments_screen.dart';
import 'package:medicare_app/features/admins/presentation/admin_doctors_screen.dart';
import 'package:medicare_app/features/admins/presentation/admin_patients_screen.dart';
import 'package:medicare_app/features/admins/presentation/admin_specialties_screen.dart';
import 'package:medicare_app/features/admins/presentation/admin_users_screen.dart';
import 'package:medicare_app/theme/app_theme.dart';
import 'package:medicare_app/core/services/session_actions.dart';
import 'package:medicare_app/shared/widgets/panel_shell.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _service = AdminService();
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _dashboard = {};

  final List<GlobalKey> _pageKeys = List.generate(6, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _service.getDashboard();
      if (!mounted) return;
      setState(() {
        _dashboard = result;
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

  Future<void> _refreshCurrentPage() async {
    if (_selectedIndex == 0) {
      await _loadDashboard();
      return;
    }
    switch (_selectedIndex) {
      case 1:
        await (_pageKeys[1].currentState as dynamic)?.refresh();
        break;
      case 2:
        await (_pageKeys[2].currentState as dynamic)?.refresh();
        break;
      case 3:
        await (_pageKeys[3].currentState as dynamic)?.refresh();
        break;
      case 4:
        await (_pageKeys[4].currentState as dynamic)?.refresh();
        break;
      case 5:
        await (_pageKeys[5].currentState as dynamic)?.refresh();
        break;
    }
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
      return error.message ?? 'Unable to load dashboard.';
    }
    return error.toString();
  }

  void _selectPage(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    if (index == 0) _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildOverview(),
      AdminUsersScreen(key: _pageKeys[1]),
      AdminDoctorsScreen(key: _pageKeys[2]),
      AdminPatientsScreen(key: _pageKeys[3]),
      AdminAppointmentsScreen(key: _pageKeys[4]),
      AdminSpecialtiesScreen(key: _pageKeys[5]),
    ];

    const destinations = [
      PanelDestination(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
      ),
      PanelDestination(
        label: 'Users',
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
      ),
      PanelDestination(
        label: 'Doctors',
        icon: Icons.medical_services_outlined,
        selectedIcon: Icons.medical_services,
      ),
      PanelDestination(
        label: 'Patients',
        icon: Icons.personal_injury_outlined,
        selectedIcon: Icons.personal_injury,
      ),
      PanelDestination(
        label: 'Appointments',
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
      ),
      PanelDestination(
        label: 'Specialties',
        icon: Icons.category_outlined,
        selectedIcon: Icons.category,
      ),
    ];

    return PanelShell(
      currentIndex: _selectedIndex,
      destinations: destinations,
      pages: pages,
      onDestinationSelected: _selectPage,
      onRefresh: _refreshCurrentPage,
      onLogout: () => SessionActions.logout(context),
    );
  }

  Widget _buildOverview() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _CenteredContent(
        child: _ErrorPanel(message: _error!),
      );
    }

    final metrics = _dashboard['metrics'] is Map
        ? Map<String, dynamic>.from(_dashboard['metrics'])
        : _dashboard;
    final upcoming = _dashboard['upcoming_appointments'] is List
        ? List<Map<String, dynamic>>.from(
            (_dashboard['upcoming_appointments'] as List).whereType<Map>().map(
              (e) => Map<String, dynamic>.from(e),
            ),
          )
        : <Map<String, dynamic>>[];

    return _CenteredContent(
      child: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const _PageHeading(
              title: 'Dashboard Overview',
              subtitle: 'Monitor your clinic activity and operations.',
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 3
                    : constraints.maxWidth >= 520
                    ? 2
                    : 1;
                final cards = [
                  _MetricData(
                    'Patients',
                    _metric(metrics, 'patients'),
                    Icons.people_alt_outlined,
                  ),
                  _MetricData(
                    'Doctors',
                    _metric(metrics, 'doctors'),
                    Icons.medical_services_outlined,
                  ),
                  _MetricData(
                    'Appointments',
                    _metric(metrics, 'appointments'),
                    Icons.calendar_month_outlined,
                  ),
                  _MetricData(
                    'Pending',
                    _metric(metrics, 'pending'),
                    Icons.hourglass_top_rounded,
                  ),
                  _MetricData(
                    'Confirmed',
                    _metric(metrics, 'confirmed'),
                    Icons.event_available_rounded,
                  ),
                  _MetricData(
                    'Completed',
                    _metric(metrics, 'completed'),
                    Icons.task_alt_rounded,
                  ),
                  _MetricData(
                    'Specialties',
                    _metric(metrics, 'specialties'),
                    Icons.category_outlined,
                  ),
                ];
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: columns == 1 ? 4.2 : 2.2,
                  children: cards
                      .map((item) => _MetricCard(data: item))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 28),
            const Text(
              'Upcoming appointments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (upcoming.isEmpty)
              const _EmptyPanel(message: 'No upcoming appointments.')
            else
              ...upcoming
                  .take(6)
                  .map((item) => _AppointmentSummary(item: item)),
          ],
        ),
      ),
    );
  }

  String _metric(Map<String, dynamic> data, String key) =>
      (data[key] ?? 0).toString();
}

class _CenteredContent extends StatelessWidget {
  const _CenteredContent({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: EdgeInsets.all(constraints.maxWidth >= 900 ? 28 : 18),
          child: child,
        ),
      ),
    ),
  );
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      const SizedBox(height: 5),
      Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary)),
    ],
  );
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});
  final _MetricData data;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: AppTheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppTheme.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primary.withValues(alpha: .10),
            child: Icon(data.icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.label,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 5),
                Text(
                  data.value,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _AppointmentSummary extends StatelessWidget {
  const _AppointmentSummary({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final patient = item['patient_name'] ?? 'Patient';
    final doctor = item['doctor_name'] ?? 'Doctor';
    final date = item['date'] ?? '';
    final time = item['start_time'] ?? '';
    final status = item['status'] ?? '';
    return Card(
      elevation: 0,
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.event_note_rounded)),
        title: Text(
          '$patient • $doctor',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('$date  $time'),
        trailing: Text(
          status.toString(),
          style: const TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border),
    ),
    child: Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 36),
      const SizedBox(height: 10),
      Text(message, textAlign: TextAlign.center),
    ],
  );
}
