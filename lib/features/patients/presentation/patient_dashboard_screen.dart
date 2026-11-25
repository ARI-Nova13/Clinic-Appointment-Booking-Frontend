import 'package:flutter/material.dart';
import 'package:medicare_app/features/patients/data/patient_service.dart';
import 'package:medicare_app/features/patients/presentation/patient_profile_screen.dart';
import 'package:medicare_app/theme/app_theme.dart';
import 'package:medicare_app/core/services/session_actions.dart';
import 'package:medicare_app/shared/widgets/panel_shell.dart';
import 'package:medicare_app/features/doctors/presentation/find_doctors_screen.dart';
import 'package:medicare_app/features/appointments/presentation/my_appointments_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final PatientService _patientService = PatientService();
  final GlobalKey<FindDoctorsScreenState> _doctorsKey = GlobalKey<FindDoctorsScreenState>();
  final GlobalKey<MyAppointmentsScreenState> _appointmentsKey = GlobalKey<MyAppointmentsScreenState>();
  final GlobalKey<PatientProfileScreenState> _profileKey = GlobalKey<PatientProfileScreenState>();

  int _selectedIndex = 0;
  String _patientName = 'Patient';

  Map<String, dynamic> _metrics = {
    'total': 0,
    'upcoming': 0,
    'completed': 0,
    'cancelled': 0,
  };

  List<Map<String, dynamic>> _upcomingAppointments = [];

  bool _isDashboardLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    if (_isDashboardLoading) return;

    setState(() => _isDashboardLoading = true);

    try {
      final results = await Future.wait([
        _patientService.getMyProfile(),
        _patientService.getDashboard(),
      ]);

      if (!mounted) return;

      final profile = results[0];
      final dashboard = results[1];

      final firstName = profile['first_name']?.toString() ?? '';
      final lastName = profile['last_name']?.toString() ?? '';
      final fullName = '$firstName $lastName'.trim();

      final metrics = Map<String, dynamic>.from(dashboard['metrics'] as Map);

      final appointments = (dashboard['upcoming_appointments'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      setState(() {
        _patientName = fullName.isEmpty ? 'Patient' : fullName;
        _metrics = metrics;
        _upcomingAppointments = appointments;
      });
    } catch (e) {
      debugPrint('Patient dashboard error: $e');
    } finally {
      if (mounted) {
        setState(() => _isDashboardLoading = false);
      }
    }
  }

  Future<void> _refreshCurrentPage() async {
    switch (_selectedIndex) {
      case 0:
        await _loadDashboardData();
        break;
      case 1:
        await (_doctorsKey.currentState?.refresh() ?? Future.value());
        break;
      case 2:
        await (_appointmentsKey.currentState?.refresh() ?? Future.value());
        break;
      case 3:
        await (_profileKey.currentState?.refresh() ?? Future.value());
        break;
    }
  }

  void _changeTab(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    if (index == 0) _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _PatientHomeTab(
        username: _patientName,
        metrics: _metrics,
        upcomingAppointments: _upcomingAppointments,
        isLoading: _isDashboardLoading,
        onFindDoctors: () => _changeTab(1),
        onRefresh: _loadDashboardData,
      ),
      FindDoctorsScreen(
        key: _doctorsKey,
        onAppointmentBooked: _loadDashboardData,
      ),
      MyAppointmentsScreen(
        key: _appointmentsKey,
        onAppointmentsChanged: _loadDashboardData,
      ),
      PatientProfileScreen(
        key: _profileKey,
        onProfileUpdated: _loadDashboardData,
      ),
    ];

    return PanelShell(
      currentIndex: _selectedIndex,
      destinations: const [
        PanelDestination(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
        ),
        PanelDestination(
          label: 'Find Doctors',
          icon: Icons.search_rounded,
        ),
        PanelDestination(
          label: 'My Appointments',
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month_rounded,
        ),
        PanelDestination(
          label: 'My Profile',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
        ),
      ],
      pages: pages,
      onDestinationSelected: _changeTab,
      onRefresh: _refreshCurrentPage,
      onLogout: () => SessionActions.logout(context),
    );
  }

}

class _PatientHomeTab extends StatelessWidget {
  final String username;
  final Map<String, dynamic> metrics;
  final List<Map<String, dynamic>> upcomingAppointments;
  final bool isLoading;
  final VoidCallback onFindDoctors;
  final VoidCallback onRefresh;

  const _PatientHomeTab({
    required this.username,
    required this.metrics,
    required this.upcomingAppointments,
    required this.isLoading,
    required this.onFindDoctors,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isWide ? 30 : 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _welcomeBanner(isWide, onFindDoctors),
                    const SizedBox(height: 30),

                    _sectionTitle('Overview'),
                    const SizedBox(height: 16),

                    if (isLoading && metrics['total'] == 0)
                      const LinearProgressIndicator()
                    else
                      _buildStatistics(isWide),

                    const SizedBox(height: 30),

                    _sectionTitle('Quick Actions'),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _ActionCard(
                          icon: Icons.search_rounded,
                          title: 'Find a Doctor',
                          subtitle: 'Browse available specialists',
                          onTap: onFindDoctors,
                        ),
                        _ActionCard(
                          icon: Icons.calendar_month_rounded,
                          title: 'Book Appointment',
                          subtitle: 'Schedule your next visit',
                          onTap: onFindDoctors,
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionTitle('Upcoming Appointments'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildUpcomingAppointments(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _welcomeBanner(bool isWide, VoidCallback onFindDoctors) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 30 : 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(child: _welcomeText(onFindDoctors)),
                const SizedBox(width: 20),
                const Icon(
                  Icons.health_and_safety_rounded,
                  color: Colors.white24,
                  size: 110,
                ),
              ],
            )
          : _welcomeText(onFindDoctors),
    );
  }

  Widget _welcomeText(VoidCallback onFindDoctors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PATIENT DASHBOARD',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Hello, $username 👋',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Take control of your health. Find doctors and manage your appointments easily.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onFindDoctors,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Find a Doctor'),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 19,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatistics(bool isWide) {
    final cards = [
      _StatCard(
        title: 'Total Appointments',
        value: '${metrics['total'] ?? 0}',
        icon: Icons.calendar_month_rounded,
        color: AppTheme.primary,
      ),
      _StatCard(
        title: 'Upcoming',
        value: '${metrics['upcoming'] ?? 0}',
        icon: Icons.event_available_rounded,
        color: Colors.orange,
      ),
      _StatCard(
        title: 'Completed',
        value: '${metrics['completed'] ?? 0}',
        icon: Icons.check_circle_outline_rounded,
        color: AppTheme.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = isWide
            ? (constraints.maxWidth - 32) / 3
            : (constraints.maxWidth - 14) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards
              .map((card) => SizedBox(width: cardWidth, child: card))
              .toList(),
        );
      },
    );
  }

  Widget _buildUpcomingAppointments() {
    if (upcomingAppointments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 40,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'No upcoming appointments',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your scheduled appointments will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: upcomingAppointments.map((appointment) {
        final doctorName = appointment['doctor_name']?.toString() ?? 'Doctor';

        final specialty =
            appointment['specialty_name']?.toString() ?? 'Specialist';

        final dateString = appointment['date']?.toString() ?? '';
        final startTime = appointment['start_time']?.toString() ?? '';
        final endTime = appointment['end_time']?.toString() ?? '';
        final status = appointment['status']?.toString() ?? 'pending';

        String formattedDate = dateString;

        try {
          final date = DateTime.parse(dateString);
          formattedDate =
              '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/'
              '${date.year}';
        } catch (_) {
          // Keep the original date if parsing fails.
        }

        final isConfirmed = status.toLowerCase() == 'confirmed';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.medical_services_rounded,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialty,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '$formattedDate  •  $startTime - $endTime',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isConfirmed
                      ? AppTheme.success.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: isConfirmed
                        ? AppTheme.success
                        : Colors.orange.shade800,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
