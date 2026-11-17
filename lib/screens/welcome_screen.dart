import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../config.dart';
import '../services/session.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'dashboard_screen.dart';

/// Frame 05. First screen after OTP verification.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final YoutubePlayerController _video = YoutubePlayerController.fromVideoId(
    videoId: kIntroVideoId,
    params: const YoutubePlayerParams(showFullscreenButton: true),
  );

  @override
  void dispose() {
    _video.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<Session>().user?.username ?? 'there';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      GreetingCard(name: name, subtitle: 'Calley Personal'),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ColoredBox(
                          color: AppColors.navy,
                          child: Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(14),
                                child: Text(
                                  'If you are here for the first time then ensure that '
                                  'you have uploaded the list to call from calley Web '
                                  'Panel hosted on $kWebPanelUrl',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12.5, height: 1.4),
                                ),
                              ),
                              YoutubePlayer(controller: _video, aspectRatio: 16 / 9),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CallActionRow(
                onStartCalling: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
