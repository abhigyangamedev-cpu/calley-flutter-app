import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'screens/language_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/api_client.dart';
import 'services/session.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = await Session.load();
  runApp(CalleyApp(session: session, api: ApiClient(demoFallback: true)));
}

class CalleyApp extends StatelessWidget {
  const CalleyApp({super.key, required this.session, required this.api});

  final Session session;
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: session),
        Provider.value(value: api),
      ],
      child: MaterialApp(
        title: 'Calley',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: session.isSignedIn
            ? const WelcomeScreen()
            : const LanguageScreen(),
        builder: (context, child) =>
            _DemoBanner(demoMode: api.demoMode, child: child!),
      ),
    );
  }
}

/// Thin strip at the top of every screen while the app runs on sample data
/// because the real API is unavailable.
class _DemoBanner extends StatelessWidget {
  const _DemoBanner({required this.demoMode, required this.child});

  final ValueListenable<bool> demoMode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: demoMode,
      child: child,
      builder: (context, demo, child) {
        if (!demo) return child!;
        final top = MediaQuery.paddingOf(context).top;
        return Column(
          children: [
            Material(
              color: const Color(0xFFF59E0B),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, top + 4, 12, 4),
                  child: const Text(
                    'Demo mode: server unavailable, showing sample data',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: child!,
              ),
            ),
          ],
        );
      },
    );
  }
}
