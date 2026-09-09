import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/theme/recytechtheme.dart';
import '../../data/models/unified_profile_model.dart';
import '../../data/models/collector_profile_model.dart';
import '../../data/repositories/collector_repository.dart';
import '../../data/repositories/unified_profile_repository.dart';
import '../../services/auth_provider.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';

class UnifiedProfileScreen extends StatefulWidget {
  const UnifiedProfileScreen({super.key});

  @override
  State<UnifiedProfileScreen> createState() => _UnifiedProfileScreenState();
}

class _UnifiedProfileScreenState extends State<UnifiedProfileScreen> {
  final UnifiedProfileRepository _repository = UnifiedProfileRepository();
  final CollectorRepository _collectorRepository = CollectorRepository();
  late Future<UnifiedProfile> _future;
  Future<CollectorProfile>? _collectorFuture;
  bool _changingDuty = false;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchProfile();
  }

  Future<void> _refresh() async {
    final future = _repository.fetchProfile();
    setState(() => _future = future);
    await future;
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, LoginScreen.route, (_) => false);
  }

  Future<void> _editProfile(UnifiedProfile profile) async {
    final updated = await showDialog<UnifiedProfile>(
      context: context,
      builder: (_) => _ProfileEditDialog(
        profile: profile,
        repository: _repository,
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _future = Future.value(updated));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  Future<void> _setDuty(bool active) async {
    if (_changingDuty) return;
    setState(() => _changingDuty = true);
    try {
      await _collectorRepository.updateDutyStatus(
        active ? 'Active' : 'Inactive',
      );
      if (mounted) {
        setState(() => _collectorFuture = _collectorRepository.fetchProfile());
      }
    } finally {
      if (mounted) setState(() => _changingDuty = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Profile & Account'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, SettingsScreen.route),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: FutureBuilder<UnifiedProfile>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry profile'),
              ),
            );
          }
          final profile = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                CircleAvatar(
                  radius: 42.r,
                  backgroundColor: RecyTechTheme.pill,
                  child: Icon(Icons.person,
                      size: 40.sp, color: RecyTechTheme.primary),
                ),
                SizedBox(height: 12.h),
                Text(profile.roleLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16.sp, fontWeight: FontWeight.w900)),
                SizedBox(height: 18.h),
                _row('Email', profile.email),
                _row(
                  'Account Status',
                  profile.accountStatus.isEmpty
                      ? profile.status
                      : profile.accountStatus,
                ),
                _row('User ID', profile.userId),
                _row('Profile ID', profile.profileId),
                ...profile.linkedProfileFields.entries
                    .where((entry) => !const ['_id', 'id'].contains(entry.key))
                    .where((entry) =>
                        entry.value is String ||
                        entry.value is num ||
                        entry.value is bool)
                    .map((entry) =>
                        _row(_label(entry.key), entry.value.toString())),
                if (profile.role == 'collector') _collectorOperations(),
                SizedBox(height: 10.h),
                OutlinedButton.icon(
                  onPressed: () => _editProfile(profile),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Profile'),
                ),
                SizedBox(height: 10.h),
                OutlinedButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _PasswordChangeDialog(
                      repository: _repository,
                    ),
                  ),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Change Password'),
                ),
                SizedBox(height: 10.h),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) => Card(
        child: ListTile(
          title: Text(label),
          trailing: Flexible(
            child: Text(value.trim().isEmpty ? 'Not supplied' : value,
                textAlign: TextAlign.right),
          ),
        ),
      );

  Widget _collectorOperations() {
    _collectorFuture ??= _collectorRepository.fetchProfile();
    return FutureBuilder<CollectorProfile>(
      future: _collectorFuture,
      builder: (context, snapshot) {
        final collector = snapshot.data;
        if (collector == null) return const SizedBox.shrink();
        return Card(
          child: SwitchListTile(
            title: const Text('Collector Duty Status'),
            subtitle: Text(
              '${collector.vehicleType} ${collector.vehiclePlate}'.trim(),
            ),
            value: collector.isActive,
            onChanged: _changingDuty ? null : _setDuty,
          ),
        );
      },
    );
  }

  String _label(String value) => value
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ');
}

class _ProfileEditDialog extends StatefulWidget {
  const _ProfileEditDialog({
    required this.profile,
    required this.repository,
  });

  final UnifiedProfile profile;
  final UnifiedProfileRepository repository;

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  final Map<String, TextEditingController> _controllers = {};
  String? _vehicleType;
  String? _message;
  bool _saving = false;

  List<String> get _fields => switch (widget.profile.role) {
        'household' => const ['firstName', 'lastName', 'phone', 'address'],
        'partner_org' => const [
            'firstName',
            'lastName',
            'organizationName',
            'contactPerson',
            'contactNumber',
            'address',
          ],
        'collector' => const [
            'firstName',
            'lastName',
            'phone',
            'vehicleType',
            'vehiclePlate',
          ],
        _ => const [],
      };

  @override
  void initState() {
    super.initState();
    for (final field in _fields.where((field) => field != 'vehicleType')) {
      _controllers[field] = TextEditingController(text: _value(field));
    }
    final initialVehicle = _value('vehicleType');
    _vehicleType =
        UnifiedProfileRepository.vehicleTypes.contains(initialVehicle)
            ? initialVehicle
            : null;
  }

  String _value(String key) => (widget.profile.userFields[key] ??
          widget.profile.linkedProfileFields[key] ??
          '')
      .toString();

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final draft = {
      for (final entry in _controllers.entries) entry.key: entry.value.text,
      if (widget.profile.role == 'collector') 'vehicleType': _vehicleType ?? '',
    };
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final updated = await widget.repository.updateProfile(
        role: widget.profile.role,
        draft: draft,
      );
      if (mounted) Navigator.pop(context, updated);
    } on UnifiedProfileException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Unable to update your profile.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final field in _fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: field == 'vehicleType'
                      ? DropdownButtonFormField<String>(
                          initialValue: _vehicleType,
                          decoration:
                              const InputDecoration(labelText: 'Vehicle Type'),
                          items: UnifiedProfileRepository.vehicleTypes
                              .map((value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ))
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _vehicleType = value),
                        )
                      : TextField(
                          controller: _controllers[field],
                          enabled: !_saving,
                          keyboardType:
                              const {'phone', 'contactNumber'}.contains(field)
                                  ? TextInputType.phone
                                  : TextInputType.text,
                          decoration: InputDecoration(labelText: _label(field)),
                        ),
                ),
              if (_message != null) Text(_message!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ],
      );

  String _label(String value) => value
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .split(' ')
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

class _PasswordChangeDialog extends StatefulWidget {
  const _PasswordChangeDialog({required this.repository});

  final UnifiedProfileRepository repository;

  @override
  State<_PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class PasswordFieldControllers {
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();

  void clear() {
    current.clear();
    next.clear();
    confirm.clear();
  }

  void dispose() {
    clear();
    current.dispose();
    next.dispose();
    confirm.dispose();
  }
}

class _PasswordChangeDialogState extends State<_PasswordChangeDialog> {
  final _fields = PasswordFieldControllers();
  String? _message;
  bool _submitting = false;

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_fields.current.text.isEmpty ||
        _fields.next.text.isEmpty ||
        _fields.confirm.text.isEmpty) {
      setState(() => _message = 'Complete all password fields.');
      return;
    }
    if (_fields.next.text != _fields.confirm.text) {
      setState(() => _message = 'New password entries do not match.');
      return;
    }
    final validation = UnifiedProfileRepository.validatePassword(
      _fields.current.text,
      _fields.next.text,
    );
    if (validation != null) {
      setState(() => _message = validation);
      return;
    }
    setState(() {
      _submitting = true;
      _message = null;
    });
    try {
      final message = await widget.repository.changePassword(
        currentPassword: _fields.current.text,
        newPassword: _fields.next.text,
      );
      _fields.clear();
      if (mounted) setState(() => _message = message);
    } on UnifiedProfileException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Unable to update your password.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: _fields.current,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            TextField(
              controller: _fields.next,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            TextField(
              controller: _fields.confirm,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration:
                  const InputDecoration(labelText: 'Confirm new password'),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_message!),
              ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'Updating...' : 'Update Password'),
          ),
        ],
      );
}
