import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import 'common.dart';

/// App bar used by Dashboard and List detail (frames 06 and 08). The
/// hamburger appears automatically because those Scaffolds have a drawer.
PreferredSizeWidget calleyAppBar(BuildContext context, {String title = 'Dashboard'}) {
  return AppBar(
    title: Text(title),
    actions: [
      IconButton(
        tooltip: 'Support',
        icon: const Icon(Icons.headset_mic_outlined),
        onPressed: () => showComingSoon(context, 'Support'),
      ),
      IconButton(
        tooltip: 'Notifications',
        icon: const Icon(Icons.notifications_none),
        onPressed: () => showComingSoon(context, 'Notifications'),
      ),
      const SizedBox(width: 4),
    ],
  );
}

/// Five-tab bar from the design; the centre "calling" tab is the active one.
class CalleyBottomNav extends StatelessWidget {
  const CalleyBottomNav({super.key});

  static const _tabs = [
    (Icons.home_outlined, 'Home'),
    (Icons.contact_page_outlined, 'Contacts'),
    (Icons.play_arrow_rounded, 'Calling'),
    (Icons.phone_callback_outlined, 'Call logs'),
    (Icons.event_note_outlined, 'Schedule'),
  ];
  static const _active = 2;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < _tabs.length; i++)
                i == _active
                    ? Semantics(
                        selected: true,
                        label: _tabs[i].$2,
                        child: Container(
                          width: 56,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(_tabs[i].$1, color: Colors.white),
                        ),
                      )
                    : IconButton(
                        tooltip: _tabs[i].$2,
                        icon: Icon(_tabs[i].$1, color: AppColors.textSecondary),
                        onPressed: () => showComingSoon(context, _tabs[i].$2),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}
