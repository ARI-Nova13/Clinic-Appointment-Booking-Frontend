import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:medicare_app/features/admins/data/admin_service.dart';
import 'package:medicare_app/theme/app_theme.dart';

class AdminPatientsScreen extends StatefulWidget {
  const AdminPatientsScreen({super.key});
  @override
  State<AdminPatientsScreen> createState() => _AdminPatientsScreenState();
}

class _AdminPatientsScreenState extends State<AdminPatientsScreen> {
  final AdminService _service = AdminService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _query = '';

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
      final result = await _service.getPatients();
      if (!mounted) return;
      setState(() {
        _items = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final message = e is DioException
          ? ((e.response?.data is Map && e.response?.data['detail'] != null)
                ? e.response?.data['detail'].toString()
                : e.message ?? 'Unable to load patients.')
          : e.toString();
      setState(() {
        _error = message;
        _loading = false;
      });
    }
  }

  String _primary(Map<String, dynamic> item) {
    final fullName = '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'.trim();
    if (fullName.isNotEmpty) return fullName;
    return (item['name'] ?? item['username'] ?? 'Patient').toString();
  }

  String _secondary(Map<String, dynamic> item) {
    final parts = <String>[];
    for (final key in ['email', 'phone', 'is_active']) {
      final value = item[key];
      if (value != null && value.toString().isNotEmpty) {
        parts.add(value.toString());
      }
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 850;
      final filtered = _items.where((item) {
        final text = item.values.join(' ').toLowerCase();
        return text.contains(_query.toLowerCase());
      }).toList();
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: EdgeInsets.all(wide ? 28 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patients',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'View registered patients and their contact details.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 18),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search patients...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                          child: filtered.isEmpty
                              ? ListView(
                                  children: const [
                                    SizedBox(height: 100),
                                    Center(child: Text('No records found.')),
                                  ],
                                )
                              : ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final item = filtered[index];
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
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: AppTheme.primary
                                              .withValues(alpha: .10),
                                          child: const Icon(
                                            Icons.personal_injury_outlined,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                        title: Text(
                                          _primary(item),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          _secondary(item).isEmpty
                                              ? '—'
                                              : _secondary(item),
                                        ),
                                        trailing: Text(
                                          (item['status'] ?? item['role'] ?? '')
                                              .toString(),
                                          style: const TextStyle(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
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
