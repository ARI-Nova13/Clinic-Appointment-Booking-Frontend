import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medicare_app/core/constants/api_constants.dart';
import 'package:medicare_app/features/doctors/data/doctor_panel_service.dart';
import 'package:medicare_app/theme/app_theme.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => DoctorProfileScreenState();
}

class DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final DoctorPanelService _service = DoctorPanelService();
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _feeController = TextEditingController();
  final _experienceController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;
  final ImagePicker _imagePicker = ImagePicker();
  String? _error;
  int? _specialtyId;
  List<Map<String, dynamic>> _specialties = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _feeController.dispose();
    _experienceController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    super.dispose();
  }

  // Called by the refresh button in the main Doctor Panel AppBar.
  Future<void> refresh() => _loadProfile();

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _service.getMyProfile(),
        _service.getSpecialties(),
      ]);

      final profile = results[0] as Map<String, dynamic>;
      final specialties = (results[1] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (!mounted) return;

      _avatarUrl = profile['avatar_url']?.toString();
      _firstNameController.text = profile['first_name']?.toString() ?? '';
      _lastNameController.text = profile['last_name']?.toString() ?? '';
      _emailController.text = profile['email']?.toString() ?? '';
      _phoneController.text = profile['phone']?.toString() ?? '';
      _bioController.text = profile['bio']?.toString() ?? '';
      _feeController.text = profile['consultation_fee']?.toString() ?? '';
      _experienceController.text =
          profile['experience_years']?.toString() ?? '';
      _clinicNameController.text = profile['clinic_name']?.toString() ?? '';
      _clinicAddressController.text =
          profile['clinic_address']?.toString() ?? '';

      final specialty = profile['specialty_id'];
      final specialtyId = specialty is int
          ? specialty
          : int.tryParse(specialty?.toString() ?? '');

      setState(() {
        _specialties = specialties;
        _specialtyId = specialtyId;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your profile. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _changeAvatar() async {
    if (_isUploadingAvatar) return;
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (image == null || !mounted) return;

      setState(() => _isUploadingAvatar = true);
      final updated = await _service.uploadMyAvatar(image);
      if (!mounted) return;
      setState(() => _avatarUrl = updated['avatar_url']?.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not upload profile photo: $error')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  String? get _resolvedAvatarUrl => ApiConstants.resolveMediaUrl(_avatarUrl);

  Widget _buildAvatarCard() {
    final imageUrl = _resolvedAvatarUrl;
    return Card(
      color: AppTheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.10),
              backgroundImage: imageUrl == null ? null : NetworkImage(imageUrl),
              onBackgroundImageError: imageUrl == null ? null : (_, _) {},
              child: imageUrl == null
                  ? const Icon(Icons.person_rounded, size: 42, color: AppTheme.primary)
                  : null,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile photo',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'JPEG, PNG or WebP • up to 5 MB',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _isUploadingAvatar ? null : _changeAvatar,
                    icon: _isUploadingAvatar
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.photo_camera_outlined),
                    label: Text(_isUploadingAvatar ? 'Uploading...' : 'Change photo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _service.updateMyProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        specialtyId: _specialtyId,
        bio: _bioController.text.trim(),
        consultationFee: int.tryParse(_feeController.text.trim()),
        clinicName: _clinicNameController.text.trim(),
        clinicAddress: _clinicAddressController.text.trim(),
        experienceYears: int.tryParse(_experienceController.text.trim()),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: AppTheme.success,
        ),
      );
      await _loadProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Profile',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage your personal and professional information.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 24),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: AppTheme.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Personal Information', Icons.person_outline),
          _field(
            label: 'First name',
            controller: _firstNameController,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'First name is required'
                : null,
          ),
          _field(
            label: 'Last name',
            controller: _lastNameController,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Last name is required'
                : null,
          ),
          _field(
            label: 'Email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          _field(
            label: 'Phone',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
          ),
          _sectionTitle(
            'Professional Information',
            Icons.medical_services_outlined,
          ),
          if (_specialties.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<int>(
                initialValue:
                    _specialties.any((item) => item['id'] == _specialtyId)
                    ? _specialtyId
                    : null,
                decoration: InputDecoration(
                  labelText: 'Specialty',
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _specialties.map((item) {
                  final id = item['id'];
                  return DropdownMenuItem<int>(
                    value: id is int ? id : int.tryParse(id.toString()),
                    child: Text(item['name']?.toString() ?? ''),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _specialtyId = value),
              ),
            ),
          _field(
            label: 'Professional bio',
            controller: _bioController,
            maxLines: 4,
          ),
          _field(
            label: 'Consultation fee',
            controller: _feeController,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null &&
                  value.isNotEmpty &&
                  int.tryParse(value) == null) {
                return 'Enter a valid whole number';
              }
              return null;
            },
          ),
          _field(
            label: 'Years of experience',
            controller: _experienceController,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null &&
                  value.isNotEmpty &&
                  int.tryParse(value) == null) {
                return 'Enter a valid whole number';
              }
              return null;
            },
          ),
          _sectionTitle('Clinic Information', Icons.local_hospital_outlined),
          _field(label: 'Clinic name', controller: _clinicNameController),
          _field(
            label: 'Clinic address',
            controller: _clinicAddressController,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
            const Icon(Icons.error_outline, size: 44, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 850;
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(isWide ? 28 : 18),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          _buildAvatarCard(),
                          const SizedBox(height: 16),
                          Card(
                            color: AppTheme.surface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: const BorderSide(color: AppTheme.border),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(isWide ? 24 : 18),
                              child: _buildForm(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
