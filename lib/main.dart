import 'package:flutter/material.dart';
import 'package:medicare_app/features/admins/presentation/admin_dashboard_screen.dart';
import 'package:medicare_app/features/authentication/data/auth_service.dart';
import 'package:medicare_app/features/authentication/presentation/login_screen.dart';
import 'package:medicare_app/features/doctors/presentation/doctor_dashboard_screen.dart';
import 'package:medicare_app/features/patients/presentation/patient_dashboard_screen.dart';
import 'package:medicare_app/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MediCareApp());
}

class MediCareApp extends StatelessWidget {
  const MediCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _SessionGate(),
    );
  }
}

class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  final AuthService _authService = AuthService();
  late Future<Map<String, dynamic>?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _authService.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        switch (user?['role']?.toString().toLowerCase()) {
          case 'patient':
            return const PatientDashboardScreen();
          case 'doctor':
            return const DoctorDashboardScreen();
          case 'admin':
            return const AdminDashboardScreen();
          default:
            return const LoginScreen();
        }
      },
    );
  }
}
