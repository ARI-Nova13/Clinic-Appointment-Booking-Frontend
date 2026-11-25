import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:medicare_app/features/admins/presentation/admin_dashboard_screen.dart';
import 'package:medicare_app/features/authentication/data/auth_service.dart';
import 'package:medicare_app/features/doctors/presentation/doctor_dashboard_screen.dart';
import 'package:medicare_app/features/patients/presentation/patient_dashboard_screen.dart';
import 'package:medicare_app/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      final role = user['role'].toString().toLowerCase();

      if (role == 'patient') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PatientDashboardScreen()),
        );
      } else if (role == 'doctor') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DoctorDashboardScreen()),
        );
      } else if (role == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unknown account role: $role')));
      }

      // We'll add role-based dashboard navigation next.
    } on DioException catch (error) {
      if (!mounted) return;

      final responseData = error.response?.data;
      String message = 'Unable to connect to the server.';

      if (responseData is Map && responseData['detail'] != null) {
        message = responseData['detail'].toString();
      } else if (error.response?.statusCode == 401) {
        message = 'Incorrect username or password.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 850;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1150),
                  child: isDesktop
                      ? _buildDesktopLayout(constraints.maxHeight)
                      : _buildMobileLayout(constraints.maxHeight),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // MOBILE LAYOUT
  Widget _buildMobileLayout(double availableHeight) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: availableHeight - 48),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.textPrimary.withValues(alpha: 0.06),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.health_and_safety_rounded,
                          color: AppTheme.primary,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'MediCare',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your health, our priority.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 42),

                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Sign in to continue to your healthcare account.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 30),

                _buildUsernameField(),

                const SizedBox(height: 22),

                _buildPasswordField(),

                const SizedBox(height: 30),

                _buildLoginButton(),

                const SizedBox(height: 28),

                _buildSecurityLabel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // DESKTOP LAYOUT
  Widget _buildDesktopLayout(double availableHeight) {
    final desktopHeight = availableHeight > 700 ? availableHeight - 48 : 650.0;

    return SizedBox(
      height: desktopHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.07),
              blurRadius: 35,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Expanded(child: _buildBrandPanel()),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 55,
                  vertical: 35,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back!',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'Sign in to continue to your healthcare workspace.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: AppTheme.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 38),

                          _buildUsernameField(),

                          const SizedBox(height: 24),

                          _buildPasswordField(),

                          const SizedBox(height: 32),

                          _buildLoginButton(),

                          const SizedBox(height: 25),

                          _buildSecurityLabel(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // BRANDING PANEL
  Widget _buildBrandPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -50, right: -50, child: _circle(200)),
          Positioned(bottom: -70, left: -60, child: _circle(240)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'MediCare',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                'Your health,\nour priority.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'A smarter way to connect patients, doctors, '
                'and healthcare professionals.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 15,
                  height: 1.7,
                ),
              ),

              const SizedBox(height: 45),

              _feature(
                Icons.calendar_month_rounded,
                'Easy appointment booking',
              ),

              const SizedBox(height: 18),

              _feature(
                Icons.medical_services_rounded,
                'Professional healthcare',
              ),

              const SizedBox(height: 18),

              _feature(
                Icons.verified_user_rounded,
                'Secure patient experience',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
      ),
    );
  }

  Widget _feature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 21),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }

  // SHARED FORM FIELDS
  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Username or email',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _usernameController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Enter your username or email',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your username or email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: _isLoading ? null : _login,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Sign In',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildSecurityLabel() {
    return const Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 15,
            color: AppTheme.textSecondary,
          ),
          SizedBox(width: 7),
          Flexible(
            child: Text(
              'Secure healthcare access',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
