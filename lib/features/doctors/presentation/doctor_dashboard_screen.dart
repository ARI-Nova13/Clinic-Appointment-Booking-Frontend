import 'package:flutter/material.dart';
import 'package:medicare_app/core/constants/api_constants.dart';
import 'package:medicare_app/features/doctors/data/doctor_panel_service.dart';
import 'package:medicare_app/features/doctors/presentation/doctor_appointments_screen.dart';
import 'package:medicare_app/features/doctors/presentation/doctor_availability_screen.dart';
import 'package:medicare_app/features/doctors/presentation/doctor_profile_screen.dart';
import 'package:medicare_app/theme/app_theme.dart';
import 'package:medicare_app/core/services/session_actions.dart';
import 'package:medicare_app/shared/widgets/panel_shell.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final DoctorPanelService _service = DoctorPanelService();
  final GlobalKey<DoctorAppointmentsScreenState> _appointmentsKey =
      GlobalKey<DoctorAppointmentsScreenState>();
  final GlobalKey<DoctorAvailabilityScreenState> _availabilityKey =
      GlobalKey<DoctorAvailabilityScreenState>();
  final GlobalKey<DoctorProfileScreenState> _profileKey =
      GlobalKey<DoctorProfileScreenState>();

  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  Map<String, dynamic> _dashboard = {};
  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>> _upcomingAppointments = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dashboard = await _service.getDashboard();

      Map<String, dynamic> profile = _profile;

      try {
        profile = await _service.getMyProfile();
      } catch (_) {}

      final rawAppointments = dashboard['upcoming_appointments'] as List? ?? [];

      final appointments = rawAppointments
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      if (!mounted) return;

      setState(() {
        _dashboard = dashboard;
        _profile = profile;
        _upcomingAppointments = appointments;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> get _metrics {
    final value = _dashboard['metrics'];
    return value is Map ? Map<String, dynamic>.from(value) : {};
  }

  int _metric(String key) {
    return int.tryParse(_metrics[key]?.toString() ?? '') ?? 0;
  }

  String get _doctorName {
    final first = _profile['first_name']?.toString() ?? '';
    final last = _profile['last_name']?.toString() ?? '';
    final fullName = '$first $last'.trim();

    if (fullName.isNotEmpty) return fullName;

    return _profile['username']?.toString() ?? 'Doctor';
  }

  String get _specialty {
    return _profile['specialty_name']?.toString() ?? 'Healthcare Professional';
  }

  Future<void> _refreshCurrentPage() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      switch (_selectedIndex) {
        case 0:
          await _loadDashboard();
          break;
        case 1:
          await (_appointmentsKey.currentState?.refresh() ?? Future.value());
          break;
        case 2:
          await (_availabilityKey.currentState?.refresh() ?? Future.value());
          break;
        case 3:
          await (_profileKey.currentState?.refresh() ?? Future.value());
          break;
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _selectPage(int index) {
    if (index < 0 || index >= 4 || index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    if (index == 0) _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= AppTheme.desktopBreakpoint;
    final pages = [
      _buildDashboardPage(isDesktop),
      DoctorAppointmentsScreen(
        key: _appointmentsKey,
        onAppointmentsUpdated: _loadDashboard,
      ),
      DoctorAvailabilityScreen(key: _availabilityKey),
      DoctorProfileScreen(key: _profileKey),
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
          label: 'Appointments',
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month_rounded,
        ),
        PanelDestination(
          label: 'Availability',
          icon: Icons.event_available_outlined,
          selectedIcon: Icons.event_available_rounded,
        ),
        PanelDestination(
          label: 'My Profile',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
        ),
      ],
      pages: pages,
      onDestinationSelected: _selectPage,
      onRefresh: _refreshCurrentPage,
      onLogout: () => SessionActions.logout(context),
    );
  }

  // DASHBOARD PAGE

  Widget _buildDashboardPage(bool isDesktop) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isDesktop ? 32 : 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1250),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(isDesktop),
                const SizedBox(height: 28),
                _buildStatistics(),
                const SizedBox(height: 34),
                _buildUpcomingAppointments(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(bool isDesktop) {
    final avatarUrl = ApiConstants.resolveMediaUrl(
      _profile['avatar_url']?.toString(),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 30 : 23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WELCOME BACK',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Dr. $_doctorName',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 29 : 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _specialty,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 17),
                Text(
                  'Here is an overview of your appointments and activity.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          CircleAvatar(
            radius: isDesktop ? 50 : 34,
            backgroundColor: Colors.white.withValues(alpha: 0.16),
            backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl),
            child: avatarUrl == null
                ? Icon(
                    Icons.medical_services_rounded,
                    size: isDesktop ? 48 : 32,
                    color: Colors.white,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  // STATISTICS

  Widget _buildStatistics() {
    final statistics = [
      _StatData(
        title: 'Total Appointments',
        value: _metric('total'),
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF3979C9),
      ),
      _StatData(
        title: "Today's Appointments",
        value: _metric('today'),
        icon: Icons.today_rounded,
        color: const Color(0xFF9B6BD3),
      ),
      _StatData(
        title: 'Pending Requests',
        value: _metric('pending'),
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFFE5A33B),
      ),
      _StatData(
        title: 'Completed',
        value: _metric('completed'),
        icon: Icons.check_circle_outline_rounded,
        color: AppTheme.success,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 17),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 520
                ? 2
                : 1;

            final cardWidth =
                (constraints.maxWidth - (columns - 1) * 15) / columns;

            return Wrap(
              spacing: 15,
              runSpacing: 15,
              children: statistics
                  .map(
                    (stat) =>
                        SizedBox(width: cardWidth, child: _buildStatCard(stat)),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(_StatData stat) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(stat.icon, color: stat.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  stat.value.toString(),
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // UPCOMING APPOINTMENTS

  Widget _buildUpcomingAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Upcoming Appointments',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _selectPage(1),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 17),
        if (_upcomingAppointments.isEmpty)
          _buildEmptyAppointments()
        else
          ..._upcomingAppointments.map(_buildAppointmentCard),
      ],
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final patientName = appointment['patient_name']?.toString() ?? 'Patient';
    final date = _formatDate(appointment['date']);
    final startTime = appointment['start_time']?.toString() ?? '';
    final endTime = appointment['end_time']?.toString() ?? '';
    final status = appointment['status']?.toString() ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppTheme.primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _appointmentDetail(Icons.calendar_today_rounded, date),
                    _appointmentDetail(
                      Icons.access_time_rounded,
                      _formatTime(startTime, endTime),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusBadge(status),
        ],
      ),
    );
  }

  Widget _appointmentDetail(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.textSecondary),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final normalized = status.toLowerCase();

    Color color;

    switch (normalized) {
      case 'confirmed':
        color = AppTheme.success;
        break;
      case 'completed':
        color = const Color(0xFF3979C9);
        break;
      case 'rejected':
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = const Color(0xFFE5A33B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        normalized[0].toUpperCase() + normalized.substring(1),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyAppointments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 42,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 13),
          Text(
            'No upcoming appointments',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Your upcoming patient bookings will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // ERROR STATE

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 55,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 17),
            const Text(
              'Unable to load dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FORMATTING

  String _formatDate(dynamic value) {
    if (value == null) return 'Date unavailable';

    final parsed = DateTime.tryParse(value.toString());

    if (parsed == null) return value.toString();

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');

    return '$day/$month/${parsed.year}';
  }

  String _formatTime(String start, String end) {
    String clean(String value) {
      return value.length >= 5 ? value.substring(0, 5) : value;
    }

    if (start.isEmpty) return 'Time unavailable';
    if (end.isEmpty) return clean(start);

    return '${clean(start)} - ${clean(end)}';
  }
}

class _StatData {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _StatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
