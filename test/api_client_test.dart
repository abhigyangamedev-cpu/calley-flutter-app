import 'dart:convert';

import 'package:calley/services/api_client.dart';
import 'package:calley/services/demo_backend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late List<http.Request> requests;

  ApiClient clientReturning(Object? body, {int status = 200}) {
    requests = [];
    return ApiClient(
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(jsonEncode(body), status,
            headers: {'content-type': 'application/json'});
      }),
    );
  }

  test('register posts JSON to /api/auth/register', () async {
    final api = clientReturning({'message': 'User registered'}, status: 201);
    await api.register(username: 'Dhrubo', email: 'd@yopmail.com', password: '123456');

    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.toString(), 'https://mock-api.calleyacd.com/api/auth/register');
    expect(jsonDecode(request.body),
        {'username': 'Dhrubo', 'email': 'd@yopmail.com', 'password': '123456'});
  });

  test('login returns the user from the response', () async {
    final api = clientReturning({
      'message': 'Login successful',
      'user': {'_id': 'u1', 'username': 'Dhrubo', 'email': 'd@yopmail.com'},
    });
    final user = await api.login(email: 'd@yopmail.com', password: '123456');
    expect(user.id, 'u1');
    expect(user.username, 'Dhrubo');
  });

  test('getLists accepts the single object shown in the docs', () async {
    final api = clientReturning(
        {'_id': 'l1', 'name': 'Test List', 'agents': [], 'clientId': 'u1'});
    final lists = await api.getLists(userId: 'u1', email: 'd@yopmail.com');

    expect(lists.map((l) => l.name), ['Test List']);
    expect(requests.single.method, 'GET');
    expect(requests.single.url.queryParameters, {'userId': 'u1'});
    expect(jsonDecode(requests.single.body), {'email': 'd@yopmail.com'});
  });

  test('getLists accepts an array', () async {
    final api = clientReturning([
      {'_id': 'l1', 'name': 'A'},
      {'_id': 'l2', 'name': 'B'},
    ]);
    final lists = await api.getLists(userId: 'u1', email: 'e@x.com');
    expect(lists.map((l) => l.id), ['l1', 'l2']);
  });

  test('getListDetails counts calls for the total', () async {
    final api = clientReturning({
      'pending': 27,
      'called': 23,
      'rescheduled': 11,
      'calls': List.generate(50, (i) => {'FirstName': 'N$i'}),
    });
    final d = await api.getListDetails(listId: 'l1', email: 'e@x.com');

    expect(requests.single.url.path, '/api/list/l1');
    expect((d.pending, d.called, d.rescheduled, d.total), (27, 23, 11, 50));
  });

  test('server error message is surfaced', () async {
    final api = clientReturning({'message': 'User already exists'}, status: 400);
    expect(
      () => api.register(username: 'a', email: 'a@b.co', password: '123456'),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', 'User already exists')),
    );
  });

  group('demo fallback', () {
    ApiClient apacheNotFound({required bool fallback}) => ApiClient(
          demoFallback: fallback,
          client: MockClient((_) async => http.Response(
              '<html><title>404 Not Found</title></html>', 404,
              headers: {'content-type': 'text/html'})),
        );

    test('without fallback, an HTML 404 is a readable error', () async {
      final api = apacheNotFound(fallback: false);
      await expectLater(
        api.register(username: 'a', email: 'a@b.co', password: '123456'),
        throwsA(isA<ApiException>()),
      );
      expect(api.demoMode.value, isFalse);
    });

    test('with fallback, the full flow runs on sample data', () async {
      final api = apacheNotFound(fallback: true);
      await api.register(username: 'Asha', email: 'asha@x.com', password: '123456');
      expect(api.demoMode.value, isTrue);
      await api.sendOtp('asha@x.com');
      await expectLater(
        api.verifyOtp(email: 'asha@x.com', otp: '000000'),
        throwsA(isA<ApiException>()),
      );
      await api.verifyOtp(email: 'asha@x.com', otp: DemoBackend.otp);
      final user = await api.login(email: 'asha@x.com', password: '123456');
      expect(user.username, 'Asha');
      final lists = await api.getLists(userId: user.id, email: user.email);
      final d = await api.getListDetails(listId: lists.single.id, email: user.email);
      expect((d.pending, d.called, d.rescheduled, d.total), (27, 23, 11, 50));
    });

    test('a JSON 404 from a working API is not treated as an outage', () async {
      final api = ApiClient(
        demoFallback: true,
        client: MockClient((_) async => http.Response(
            jsonEncode({'message': 'List not found'}), 404,
            headers: {'content-type': 'application/json'})),
      );
      await expectLater(
        api.getListDetails(listId: 'x', email: 'e@x.com'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'List not found')),
      );
      expect(api.demoMode.value, isFalse);
    });
  });
}

