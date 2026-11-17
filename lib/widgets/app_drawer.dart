import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../screens/language_screen.dart';
import '../services/session.dart';
import '../theme.dart';
import 'common.dart';

/// Frame 09. Shows the signed-in user's name, email and registration time.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const _menu = [
    (Icons.rocket_launch_outlined, 'Getting Started'),
    (Icons.cloud_sync_outlined, 'Sync Data'),
    (Icons.emoji_events_outlined, 'Gamification'),
    (Icons.outbox_outlined, 'Send Logs'),
    (Icons.settings_outlined, 'Settings'),
    (Icons.help_outline, 'Help?'),
    (Icons.person_remove_outlined, 'Cancel Subscription'),
  ];
  static const _appInfo = [
    (Icons.info_outline, 'About Us'),
    (Icons.privacy_tip_outlined, 'Privacy Policy'),
    (Icons.system_update_outlined, 'Version $kAppVersion'),
    (Icons.share_outlined, 'Share App'),
  ];

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final user = session.user;
    final registeredAt = session.registeredAt;

    void comingSoon(String feature) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$feature is coming soon.')));
    }

    return Drawer(
      backgroundColor: AppColors.lightBlue,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: EdgeInsets.fromLTRB(
                16, MediaQuery.paddingOf(context).top + 20, 16, 18),
            child: Row(
              children: [
                UserAvatar(name: user?.username ?? '', size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: user?.username ?? 'Guest',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(
                            text: '  •  Personal',
                            style: TextStyle(fontSize: 12, color: Color(0xFFFCD34D)),
                          ),
                        ]),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(user?.email ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        registeredAt == null
                            ? 'Registered: not recorded on this device'
                            : 'Registered: '
                                '${DateFormat('d MMM yyyy, h:mm a').format(registeredAt)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final (icon, label) in _menu)
                  _DrawerItem(icon: icon, label: label, onTap: () => comingSoon(label)),
                const Divider(indent: 16, endIndent: 16),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('App Info',
                      style: TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
                for (final (icon, label) in _appInfo)
                  _DrawerItem(icon: icon, label: label, onTap: () => comingSoon(label)),
                _DrawerItem(
                  icon: Icons.logout,
                  label: 'Logout',
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final session = context.read<Session>();
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to see your lists.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed != true) return;
    await session.signOut();
    await navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LanguageScreen()),
      (_) => false,
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: AppColors.navy),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }
}
