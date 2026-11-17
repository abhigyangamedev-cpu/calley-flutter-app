import 'dart:convert';

import 'package:calley/models.dart';
import 'package:calley/screens/language_screen.dart';
import 'package:calley/screens/list_detail_screen.dart';
import 'package:calley/screens/otp_screen.dart';
import 'package:calley/screens/register_screen.dart';
import 'package:calley/services/api_client.dart';
import 'package:calley/services/session.dart';
import 'package:calley/theme.dart';
import 'package:calley/widgets/app_drawer.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake server keyed by path, recording the paths that were called.
ApiClient fakeApi(Map<String, Object> responses, List<String> calls) {
  return ApiClient(
    client: MockClient((request) async {
      calls.add(request.url.path);
      final body = responses[request.url.path];
      return body == null
          ? http.Response('{"message":"Not found"}', 404)
          : http.Response(jsonEncode(body), 200,
              headers: {'content-type': 'application/json'});
    }),
  );
}

Future<Session> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  required ApiClient api,
  Map<String, Object> prefs = const {},
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(prefs);
  final session = await Session.load();
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: session),
      Provider.value(value: api),
    ],
    child: MaterialApp(theme: buildTheme(), home: screen),
  ));
  return session;
}

const _user = {'_id': 'u1', 'username': 'Swati Sharma', 'email': 'swati@example.com'};

void main() {
  testWidgets('only English can be chosen, then Select opens registration',
      (tester) async {
    await pumpScreen(tester, const LanguageScreen(), api: fakeApi({}, []));

    await tester.tap(find.text('Hindi'));
    await tester.pump();
    expect(find.textContaining('Hindi is coming soon'), findsOneWidget);

    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('registration validates, registers, sends OTP and opens OTP screen',
      (tester) async {
    final calls = <String>[];
    final api = fakeApi({
      '/api/auth/register': {'message': 'User registered'},
      '/api/auth/send-otp': {'message': 'OTP sent'},
    }, calls);
    await pumpScreen(tester, const RegisterScreen(), api: api);

    await tester.tap(find.text('Sign Up'));
    await tester.pump();
    expect(find.text('Enter your name'), findsOneWidget);
    expect(calls, isEmpty);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Swati');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email address'), 'swati@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'secret1');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'WhatsApp number'), '9876543210');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Mobile number'), '9876543210');
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value, isTrue);

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(calls, ['/api/auth/register', '/api/auth/send-otp']);
    expect(find.byType(OtpScreen), findsOneWidget);
    expect(find.text('swati@example.com'), findsOneWidget);

    // Dispose the OTP screen so its resend countdown timer is cancelled.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('list detail shows totals and status counts from the API',
      (tester) async {
    final api = fakeApi({
      '/api/list/l1': {
        'pending': 28,
        'called': 22,
        'rescheduled': 9,
        'calls': List.generate(50, (i) => {'FirstName': 'N$i'}),
      },
    }, []);
    await pumpScreen(
      tester,
      const ListDetailScreen(list: CallingList(id: 'l1', name: 'Test List')),
      api: api,
      prefs: {'user': jsonEncode(_user)},
    );
    await tester.pumpAndSettle();

    expect(find.text('Test List'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('28'), findsOneWidget);
    expect(find.text('22'), findsOneWidget);
    expect(find.text('09'), findsOneWidget);
    expect(find.byType(CallStatusDonut), findsOneWidget);
  });

  testWidgets('drawer shows name, email and registration time', (tester) async {
    await pumpScreen(
      tester,
      const Scaffold(drawer: AppDrawer(), body: SizedBox()),
      api: fakeApi({}, []),
      prefs: {
        'user': jsonEncode(_user),
        'registeredAt:swati@example.com': DateTime(2026, 11, 16, 10, 42).toIso8601String(),
      },
    );
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    expect(find.textContaining('Swati Sharma'), findsOneWidget);
    expect(find.text('swati@example.com'), findsOneWidget);
    expect(find.text('Registered: 16 Nov 2026, 10:42 AM'), findsOneWidget);
  });
}
