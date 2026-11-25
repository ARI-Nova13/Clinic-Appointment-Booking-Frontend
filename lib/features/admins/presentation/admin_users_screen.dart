import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:medicare_app/features/admins/data/admin_service.dart';
import 'package:medicare_app/theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService _service = AdminService();
  List<Map<String, dynamic>> _users = [];
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
      final result = await _service.getUsers();
      if (!mounted) return;
      setState(() {
        _users = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _message(e);
        _loading = false;
      });
    }
  }

  String _message(Object e) {
    if (e is DioException) {
      final d = e.response?.data;
      if (d is Map && d['detail'] != null) return d['detail'].toString();
      return e.message ?? 'Could not load users.';
    }
    return e.toString();
  }

  Future<void> _toggle(Map<String, dynamic> user) async {
    final id = int.tryParse('${user['id']}');
    if (id == null) return;
    final active = user['is_active'] == true;
    try {
      await _service.setUserActive(userId: id, isActive: !active);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!active ? 'User activated.' : 'User deactivated.'),
        ),
      );
      await refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_message(e))));
    }
  }

  Future<void> _delete(Map<String, dynamic> user) async {
    final id = int.tryParse('${user['id']}');
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text('Delete ${_name(user)}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteUser(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User deleted.')));
      await refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_message(e))));
    }
  }

  String _name(Map<String, dynamic> u) {
    final full = '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim();
    return full.isEmpty ? (u['username'] ?? 'User').toString() : full;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 850;
      final filtered = _users.where((u) {
        final value =
            '${_name(u)} ${u['username'] ?? ''} ${u['email'] ?? ''} ${u['role'] ?? ''}'
                .toLowerCase();
        return value.contains(_query.toLowerCase());
      }).toList();
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: EdgeInsets.all(wide ? 28 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Users',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Manage all accounts and their access.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 18),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search users...',
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
                                    Center(child: Text('No users found.')),
                                  ],
                                )
                              : ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final user = filtered[index];
                                    final active = user['is_active'] == true;
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
                                            Icons.person_outline,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                        title: Text(
                                          _name(user),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${user['email'] ?? 'No email'}  •  ${(user['role'] ?? 'user').toString()}  •  ${active ? 'Active' : 'Inactive'}',
                                        ),
                                        isThreeLine: false,
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (value) =>
                                              value == 'toggle'
                                              ? _toggle(user)
                                              : _delete(user),
                                          itemBuilder: (_) => [
                                            PopupMenuItem(
                                              value: 'toggle',
                                              child: Text(
                                                active
                                                    ? 'Deactivate'
                                                    : 'Activate',
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Delete'),
                                            ),
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
