import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:recytecmobproj/core/theme/recytechtheme.dart';
import 'package:recytecmobproj/data/models/drop_off_record_model.dart';
import 'package:recytecmobproj/data/models/points_rewards_models.dart';
import 'package:recytecmobproj/data/models/user_model.dart';
import 'package:recytecmobproj/data/repositories/drop_off_repository.dart';
import 'package:recytecmobproj/data/repositories/points_rewards_repository.dart';
import 'package:recytecmobproj/services/auth_provider.dart';

import '../../../widgets/primary_button.dart';
import '../../auth/login_screen.dart';
import '../../settings/settings_screen.dart';
import '../history/history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  final DropOffRepository _dropOffRepository = ApiDropOffRepository();
  final PointsRewardsRepository _pointsRepository = PointsRewardsRepository();
  late Future<List<DropOffRecord>> _dropOffsFuture;
  late Future<PointsSummary> _pointsFuture;

  @override
  void initState() {
    super.initState();
    _dropOffsFuture = _dropOffRepository.getMyDropOffHistory();
    _pointsFuture = _pointsRepository.fetchPointsSummary();
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _profileImage = File(picked.path);
    });
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
        SizedBox(height: 2.h),
        Text(label,
            style: TextStyle(fontSize: 10.sp, color: RecyTechTheme.textMuted)),
      ],
    );
  }

  Widget _recentRow(DropOffRecord record) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.binName,
                    style: TextStyle(
                        fontSize: 11.sp, fontWeight: FontWeight.w800)),
                SizedBox(height: 2.h),
                Text(_formatDate(record.createdAt),
                    style: TextStyle(
                        fontSize: 9.5.sp, color: RecyTechTheme.textMuted)),
              ],
            ),
          ),
          Text(record.status,
              style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _displayName(UserModel? user) {
    if (user == null) return 'User';

    final fullName = user.fullName.trim();
    if (fullName.isNotEmpty) return fullName;

    final composedName = [
      user.firstName,
      user.lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    if (composedName.isNotEmpty) return composedName;

    final email = user.email.trim();
    if (email.isNotEmpty) return email.split('@').first;

    return 'User';
  }

  String _profileValue(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? 'Not set' : text;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final displayName = _displayName(user);

    return SafeArea(
      child: Scaffold(
        backgroundColor: RecyTechTheme.bg,
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              tooltip: 'Settings',
              onPressed: () => Navigator.pushNamed(
                context,
                SettingsScreen.route,
              ),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          children: [
            Text('My Profile',
                style:
                    TextStyle(fontSize: 12.sp, color: RecyTechTheme.textMuted)),
            SizedBox(height: 10.h),
            Center(
              child: GestureDetector(
                onTap: _pickProfileImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48.r,
                      backgroundColor: cs.primary.withValues(alpha: 0.12),
                      foregroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? Icon(Icons.person, size: 42.sp, color: cs.primary)
                          : null,
                    ),
                    Container(
                      width: 30.w,
                      height: 30.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primary,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(Icons.camera_alt,
                          size: 16.sp, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Center(
              child: Text(
                displayName,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900),
              ),
            ),
            SizedBox(height: 8.h),
            Center(
                child: Text('Designated-bin drop-off member',
                    style: TextStyle(
                        fontSize: 10.sp, color: RecyTechTheme.textMuted))),
            SizedBox(height: 8.h),
            _profileInfoCard('Email Address', _profileValue(user?.email), cs),
            SizedBox(height: 8.h),
            _profileInfoCard('Contact Number', _profileValue(user?.phone), cs),
            SizedBox(height: 14.h),
            const Divider(),
            FutureBuilder<List<DropOffRecord>>(
              future: _dropOffsFuture,
              builder: (context, snapshot) {
                final dropOffs = snapshot.data ?? <DropOffRecord>[];
                final credited = dropOffs
                    .where((record) => record.pointsStatus == 'credited')
                    .length;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat('${dropOffs.length}', 'Drop-Offs'),
                      _stat('$credited', 'Credited'),
                      FutureBuilder<PointsSummary>(
                        future: _pointsFuture,
                        builder: (context, pointsSnapshot) {
                          final balance = pointsSnapshot.data?.balance ?? 0;
                          return _stat('$balance', 'Points');
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            SizedBox(height: 12.h),
            Center(
                child: Text('Recent Drop-Offs',
                    style: TextStyle(
                        fontSize: 11.sp, fontWeight: FontWeight.w900))),
            SizedBox(height: 10.h),
            FutureBuilder<List<DropOffRecord>>(
              future: _dropOffsFuture,
              builder: (context, snapshot) {
                final dropOffs = snapshot.data ?? <DropOffRecord>[];
                final recentDropOffs = dropOffs.take(2).toList();
                return Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: RecyTechTheme.border),
                    borderRadius: BorderRadius.circular(20.r),
                    color: RecyTechTheme.card,
                    boxShadow: [
                      BoxShadow(
                        color: RecyTechTheme.primary.withValues(alpha: 0.07),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: dropOffs.isEmpty
                      ? Text(
                          'No drop-offs recorded yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            color: RecyTechTheme.textMuted,
                          ),
                        )
                      : Column(
                          children: [
                            for (final record in recentDropOffs) ...[
                              _recentRow(record),
                              if (record != recentDropOffs.last)
                                const Divider(),
                            ],
                          ],
                        ),
                );
              },
            ),
            SizedBox(height: 10.h),
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
                child: Text(
                  'View drop-off history >',
                  style: TextStyle(fontSize: 10.5.sp),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Center(
              child: auth.isLoading
                  ? SizedBox(
                      width: 220.w,
                      height: 44.h,
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  : PrimaryButton(
                      text: 'Logout',
                      filled: false,
                      width: 220.w,
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();
                        if (!context.mounted) return;

                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          LoginScreen.route,
                          (route) => false,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileInfoCard(String label, String value, ColorScheme cs) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: RecyTechTheme.border),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: RecyTechTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11.sp,
                color: RecyTechTheme.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
