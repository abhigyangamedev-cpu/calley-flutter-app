import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../models.dart';
import 'demo_backend.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Client for the Calley "Mock API V2" Postman collection.
class ApiClient {
  ApiClient({http.Client? client, this.demoFallback = false})
      : _client = client ?? _createClient();

  /// When true, the client switches to [DemoBackend] for the rest of the
  /// session as soon as the real server turns out to be unavailable.
  final bool demoFallback;

  /// Whether requests are currently being answered by [DemoBackend].
  final demoMode = ValueNotifier<bool>(false);

  final _demo = DemoBackend();

  static const host = 'mock-api.calleyacd.com';
  static final Uri _base = Uri.https(host, '/api/');

  final http.Client _client;

  static http.Client _createClient() {
    final io = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    if (kDebugMode) {
      // WORKAROUND (debug builds only): as of Nov 2026 the mock server presents
      // a TLS certificate issued for "cool-meninsky.74-208-123-142.plesk.page",
      // not for mock-api.calleyacd.com, so every verifying client rejects it.
      // Accept that certificate for this one host only. Release builds keep
      // full verification; remove this once the server certificate is fixed.
      io.badCertificateCallback = (cert, requestHost, port) => requestHost == host;
    }
    return IOClient(io);
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) =>
      _withDemo(
        () => _send('POST', 'auth/register',
            body: {'username': username, 'email': email, 'password': password}),
        () => _demo.register(username: username, email: email, password: password),
      );

  Future<void> sendOtp(String email) => _withDemo(
        () => _send('POST', 'auth/send-otp', body: {'email': email}),
        () => _demo.sendOtp(email),
      );

  Future<void> verifyOtp({required String email, required String otp}) => _withDemo(
        () => _send('POST', 'auth/verify-otp', body: {'email': email, 'otp': otp}),
        () => _demo.verifyOtp(email: email, otp: otp),
      );

  Future<AppUser> login({required String email, required String password}) =>
      _withDemo(() => _login(email: email, password: password),
          () => _demo.login(email: email, password: password));

  Future<AppUser> _login({required String email, required String password}) async {
    final data = await _send('POST', 'auth/login',
        body: {'email': email, 'password': password});
    final user = data is Map ? data['user'] : null;
    if (user is! Map<String, dynamic>) {
      throw const ApiException('Unexpected login response from the server.');
    }
    return AppUser.fromJson(user);
  }

  /// The docs show a single list object; also accept an array of them.
  Future<List<CallingList>> getLists({
    required String userId,
    required String email,
  }) =>
      _withDemo(() => _getLists(userId: userId, email: email), _demo.getLists);

  Future<List<CallingList>> _getLists({
    required String userId,
    required String email,
  }) async {
    final data = await _send('GET', 'list',
        query: {'userId': userId}, body: {'email': email});
    final List raw = switch (data) {
      List() => data,
      {'lists': List lists} => lists,
      Map() => [data],
      _ => const [],
    };
    return raw
        .whereType<Map<String, dynamic>>()
        .where((json) => json['_id'] != null || json['id'] != null)
        .map(CallingList.fromJson)
        .toList();
  }

  Future<ListDetails> getListDetails({
    required String listId,
    required String email,
  }) =>
      _withDemo(() => _getListDetails(listId: listId, email: email),
          () => _demo.getListDetails(listId));

  Future<ListDetails> _getListDetails({
    required String listId,
    required String email,
  }) async {
    final data = await _send('GET', 'list/${Uri.encodeComponent(listId)}',
        body: {'email': email});
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected list details response from the server.');
    }
    return ListDetails.fromJson(data);
  }

  /// Runs [real] against the server, or [demo] once demo mode is on. Switches
  /// demo mode on (when [demoFallback] allows) if the server is unavailable.
  Future<T> _withDemo<T>(Future<T> Function() real, T Function() demo) async {
    if (demoMode.value) return demo();
    try {
      return await real();
    } on _ServerUnavailable catch (e) {
      if (!demoFallback) throw ApiException(e.message);
      demoMode.value = true;
      return demo();
    }
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = _base.resolve(path).replace(queryParameters: query);
    // The Postman docs send a JSON body even on the GET requests, so use a raw
    // Request (http.get cannot carry a body).
    final request = http.Request(method, uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'application/json';
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const _ServerUnavailable('The server took too long to respond. Please try again.');
    } on HandshakeException {
      throw const _ServerUnavailable(
          'Could not open a secure connection to the server (certificate problem).');
    } on SocketException {
      throw const _ServerUnavailable(
          'Could not reach the server. Check your internet connection.');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    }

    dynamic data;
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } on FormatException {
        data = null;
      }
    }

    // A 404 without a JSON body (e.g. Apache's HTML "Not Found" page) means
    // the API itself is not deployed, rather than a resource being missing.
    if (response.statusCode == 404 && data == null) {
      throw const _ServerUnavailable('The Calley server is unavailable (HTTP 404).');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
          _messageFrom(data) ?? 'Request failed (HTTP ${response.statusCode}).');
    }
    return data;
  }

  static String? _messageFrom(dynamic data) {
    if (data is Map) {
      for (final key in const ['message', 'error', 'msg']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) return value;
      }
    }
    return null;
  }
}

class _ServerUnavailable implements Exception {
  const _ServerUnavailable(this.message);

  final String message;
}
