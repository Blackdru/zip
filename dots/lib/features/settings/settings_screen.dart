import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(
            'About',
            [
              _buildTile(
                icon: Icons.info_outline,
                title: 'Version',
                subtitle: '1.0.2',
                onTap: () {},
              ),
              _buildTile(
                icon: Icons.description_outlined,
                title: 'How to Play',
                subtitle: 'Learn the rules',
                onTap: () => _showHowToPlay(context),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildSection(
            'Legal',
            [
              _buildTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'View our privacy policy',
                onTap: () => _launchPrivacyPolicy(),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildSection(
            'Support',
            [
              _buildTile(
                icon: Icons.bug_report_outlined,
                title: 'Report a Bug',
                subtitle: 'Help us improve',
                onTap: () {},
              ),
              _buildTile(
                icon: Icons.star_outline,
                title: 'Rate Us',
                subtitle: 'Share your feedback',
                onTap: () => _launchPlayStore(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchPrivacyPolicy() async {
    final uri = Uri.parse('https://robotpdf.com/apps/connectdots');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchPlayStore() async {
    final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.budrock.dots');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: AppTheme.glassCard,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryCyan),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'How to Play',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRule(
                '1',
                'Connect the Dots',
                'Draw lines to connect pairs of colored dots',
              ),
              const SizedBox(height: 16),
              _buildRule(
                '2',
                'Fill the Grid',
                'Every cell on the board must be filled',
              ),
              const SizedBox(height: 16),
              _buildRule(
                '3',
                'No Overlaps',
                'Paths cannot cross or overlap each other',
              ),
              const SizedBox(height: 16),
              _buildRule(
                '4',
                'Complete All Pairs',
                'Connect all pairs to solve the puzzle',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  Widget _buildRule(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.primaryGradient,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
