import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _sound = true;
  bool _music = true;
  bool _notifications = true;
  bool _vibration = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        backgroundColor: AppTheme.canvas,
        title: const Text('Settings'),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Icon(Icons.arrow_back_ios_new, size: 18),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          _section('Audio', [
            _toggle('Sound effects', _sound, (v) => setState(() => _sound = v)),
            _toggle('Background music', _music, (v) => setState(() => _music = v)),
          ]),
          _section('Notifications', [
            _toggle('Push notifications', _notifications,
                (v) => setState(() => _notifications = v),),
          ]),
          _section('Gameplay', [
            _toggle('Haptic feedback', _vibration,
                (v) => setState(() => _vibration = v),),
          ]),
          _section('Account', [
            _action('Edit profile', () {}),
            _action('Change password', () {}),
          ]),
          _section('About', [
            _info('Version', '1.0.0'),
            _action('Privacy Policy', () {}),
            _action('Terms of Service', () {}),
          ]),
          const SizedBox(height: 12),
          // Logout
          GestureDetector(
            onTap: () => _confirmLogout(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(
                    color: AppTheme.errorRed.withOpacity(0.4), width: 1.5,),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Sign out',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.errorRed,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 24, 0, 10),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.inkLight,
              letterSpacing: 0.9,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.border, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              final child = e.value;
              if (e.key < children.length - 1) {
                return Column(
                  children: [
                    child,
                    const Divider(height: 1, color: AppTheme.border, indent: 18, endIndent: 18),
                  ],
                );
              }
              return child;
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _toggle(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppTheme.ink,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _action(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.ink,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppTheme.inkFaint),
          ],
        ),
      ),
    );
  }

  Widget _info(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppTheme.ink,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 15, color: AppTheme.inkLight),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Sign out?',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.ink,),),
        content: const Text(
          'You will need to sign in again.',
          style: TextStyle(color: AppTheme.inkMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.inkLight),),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out',
                style: TextStyle(
                    color: AppTheme.errorRed, fontWeight: FontWeight.w600,),),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go(AppRoutes.login);
    }
  }
}
