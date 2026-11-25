import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:medicare_app/features/admins/data/admin_service.dart';
import 'package:medicare_app/theme/app_theme.dart';

class AdminSpecialtiesScreen extends StatefulWidget {
  const AdminSpecialtiesScreen({super.key});

  @override
  State<AdminSpecialtiesScreen> createState() => _AdminSpecialtiesScreenState();
}

class _AdminSpecialtiesScreenState extends State<AdminSpecialtiesScreen> {
  final AdminService _service = AdminService();

  List<Map<String, dynamic>> _specialties = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.getSpecialties();

      if (!mounted) return;

      setState(() {
        _specialties = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      final message = _errorMessage(e, 'Unable to load specialties.');

      setState(() {
        _error = message;
        _loading = false;
      });
    }
  }

  String _errorMessage(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }

      return error.message ?? fallback;
    }

    return error.toString();
  }

  Future<void> _openEditor({Map<String, dynamic>? specialty}) async {
    if (_saving) return;

    final result = await showDialog<String>(
      context: context,
      builder: (_) => _SpecialtyEditorDialog(
        initialName: (specialty?['name'] ?? '').toString(),
        isEditing: specialty != null,
      ),
    );

    if (!mounted || result == null) return;

    setState(() => _saving = true);

    try {
      final id = int.tryParse('${specialty?['id']}');

      if (id == null) {
        await _service.createSpecialty(result);
      } else {
        await _service.updateSpecialty(specialtyId: id, name: result);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            id == null ? 'Specialty created.' : 'Specialty updated.',
          ),
        ),
      );

      await refresh();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(e, 'Could not save specialty.'))),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> specialty) async {
    final id = int.tryParse('${specialty['id']}');

    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete specialty?'),
        content: Text('Delete ${specialty['name'] ?? 'this specialty'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    try {
      await _service.deleteSpecialty(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Specialty deleted.')));

      await refresh();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage(e, 'Could not delete specialty.')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 850;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: EdgeInsets.all(wide ? 28 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Specialties',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Create and maintain the clinic specialty list.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : () => _openEditor(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add specialty'),
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
                            child: _specialties.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: const [
                                      SizedBox(height: 100),
                                      Center(
                                        child: Text('No specialties yet.'),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: _specialties.length,
                                    itemBuilder: (context, index) {
                                      final item = _specialties[index];

                                      return Card(
                                        elevation: 0,
                                        color: AppTheme.surface,
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          side: const BorderSide(
                                            color: AppTheme.border,
                                          ),
                                        ),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: AppTheme.primary
                                                .withValues(alpha: .10),
                                            child: const Icon(
                                              Icons
                                                  .medical_information_outlined,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                          title: Text(
                                            (item['name'] ?? 'Specialty')
                                                .toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'ID: ${item['id'] ?? '—'}',
                                          ),
                                          trailing: Wrap(
                                            children: [
                                              IconButton(
                                                tooltip: 'Edit',
                                                onPressed: _saving
                                                    ? null
                                                    : () => _openEditor(
                                                        specialty: item,
                                                      ),
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: 'Delete',
                                                onPressed: _saving
                                                    ? null
                                                    : () => _delete(item),
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                ),
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
}

class _SpecialtyEditorDialog extends StatefulWidget {
  final String initialName;
  final bool isEditing;

  const _SpecialtyEditorDialog({
    required this.initialName,
    required this.isEditing,
  });

  @override
  State<_SpecialtyEditorDialog> createState() => _SpecialtyEditorDialogState();
}

class _SpecialtyEditorDialogState extends State<_SpecialtyEditorDialog> {
  late final TextEditingController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit specialty' : 'Add specialty'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Specialty name',
            hintText: 'e.g. Cardiology',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter a specialty name.';
            }
            return null;
          },
          onFieldSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
