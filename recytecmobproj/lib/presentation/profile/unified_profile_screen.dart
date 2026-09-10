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
  const UnifiedProfileScreen({
    super.key,
    this.repository,
    this.collectorRepository,
  });

  final UnifiedProfileRepository? repository;
  final CollectorRepository? collectorRepository;

  @override
  State<UnifiedProfileScreen> createState() => _UnifiedProfileScreenState();
}

class _UnifiedProfileScreenState extends State<UnifiedProfileScreen> {
  late final UnifiedProfileRepository _repository;
  late final CollectorRepository _collectorRepository;
  late Future<UnifiedProfile> _future;
  Future<CollectorProfile>? _collectorFuture;
  bool _changingDuty = false;
  Future<void>? _refreshing;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? UnifiedProfileRepository();
    _collectorRepository = widget.collectorRepository ?? CollectorRepository();
    _future = _repository.fetchProfile();
  }

  Future<void> _refresh() async {
    final active = _refreshing;
    if (active != null) return active;

    final future = _repository.fetchProfile();
    setState(() {
      _future = future;
      _collectorFuture = null;
    });
    final refresh = future.whenComplete(() {
      if (mounted) _refreshing = null;
    });
    _refreshing = refresh;
    await refresh;
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
    await _refresh();
    if (!mounted) return;
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
        await _refresh();
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
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, SettingsScreen.route),
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Refresh profile',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
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
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
              children: [
                _identityCard(profile),
                SizedBox(height: 22.h),
                _sectionTitle(
                  'Account details',
                  'Your verified contact and role information.',
                ),
                SizedBox(height: 12.h),
                _detailsCard(profile),
                if (profile.role == 'collector') _collectorOperations(),
                SizedBox(height: 22.h),
                _sectionTitle('Account actions', null),
                SizedBox(height: 12.h),
                _actionsCard(profile),
                SizedBox(height: 8.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _identityCard(UnifiedProfile profile) {
    final scheme = Theme.of(context).colorScheme;
    final rawStatus =
        profile.accountStatus.isEmpty ? profile.status : profile.accountStatus;
    final status =
        rawStatus.trim().isEmpty ? 'Status unavailable' : _title(rawStatus);

    return Card(
      key: const Key('profile-identity-card'),
      child: Padding(
        padding: EdgeInsets.all(18.w),
        child: Row(
          children: [
            Container(
              width: 68.w,
              height: 68.w,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                profile.role == 'partner_org'
                    ? Icons.business_outlined
                    : profile.role == 'collector'
                        ? Icons.local_shipping_outlined
                        : Icons.person_outline,
                size: 32.sp,
                color: scheme.primary,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.identityName ?? 'Name unavailable',
                    key: const Key('profile-display-name'),
                    style: TextStyle(
                      fontSize: 17.sp,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    profile.roleLabel,
                    key: const Key('profile-role-label'),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Semantics(
                    label: 'Account status: $status',
                    child: Container(
                      key: const Key('profile-account-status'),
                      padding: EdgeInsets.symmetric(
                        horizontal: 9.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

  Widget _sectionTitle(String title, String? subtitle) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 3.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.sp,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _detailsCard(UnifiedProfile profile) {
    final fields = _visibleFields(profile);
    return Card(
      key: const Key('profile-details-card'),
      child: Column(
        children: [
          for (var index = 0; index < fields.length; index++) ...[
            _detailRow(fields[index].$1, fields[index].$2, fields[index].$3),
            if (index != fields.length - 1)
              const Divider(height: 1, indent: 50),
          ],
        ],
      ),
    );
  }

  List<(String, String, IconData)> _visibleFields(UnifiedProfile profile) {
    String value(String key) =>
        (profile.linkedProfileFields[key] ?? profile.userFields[key] ?? '')
            .toString();

    return switch (profile.role) {
      'partner_org' => [
          ('Email', profile.email, Icons.email_outlined),
          ('Contact person', value('contactPerson'), Icons.badge_outlined),
          ('Contact number', value('contactNumber'), Icons.phone_outlined),
          ('Address', value('address'), Icons.location_on_outlined),
        ],
      'collector' => [
          ('Email', profile.email, Icons.email_outlined),
          ('Phone', value('phone'), Icons.phone_outlined),
          ('Vehicle type', value('vehicleType'), Icons.local_shipping_outlined),
          ('Vehicle plate', value('vehiclePlate'), Icons.pin_outlined),
        ],
      _ => [
          ('Email', profile.email, Icons.email_outlined),
          ('Phone', value('phone'), Icons.phone_outlined),
          ('Address', value('address'), Icons.location_on_outlined),
        ],
    };
  }

  Widget _detailRow(String label, String value, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    final display = value.trim().isEmpty ? 'Not supplied' : value.trim();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.sp, color: scheme.primary),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  display,
                  style:
                      TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionsCard(UnifiedProfile profile) => Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit profile'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editProfile(profile),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => _PasswordChangeDialog(repository: _repository),
              ),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: Icon(Icons.logout, color: RecyTechTheme.danger),
              title: Text(
                'Log out',
                style: TextStyle(
                  color: RecyTechTheme.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: _logout,
            ),
          ],
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
          margin: EdgeInsets.only(top: 14.h),
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

  String _title(String value) => value
      .replaceAll('_', ' ')
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
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
                  padding: const EdgeInsets.only(bottom: 14),
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
            const SizedBox(height: 14),
            TextField(
              controller: _fields.next,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 14),
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
