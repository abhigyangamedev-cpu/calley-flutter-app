import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

/// Signed-in user, registration time and language, persisted on the device.
class Session extends ChangeNotifier {
  Session._(this._prefs) : _user = _readUser(_prefs);

  static Future<Session> load() async =>
      Session._(await SharedPreferences.getInstance());

  static const _kUser = 'user';
  static const _kLanguage = 'language';

  final SharedPreferences _prefs;
  AppUser? _user;

  AppUser? get user => _user;
  bool get isSignedIn => _user != null && _user!.id.isNotEmpty;

  String get language => _prefs.getString(_kLanguage) ?? 'English';

  /// When this user registered on this device; null if they registered
  /// elsewhere (the API does not return a registration date).
  DateTime? get registeredAt {
    final user = _user;
    if (user == null) return null;
    return DateTime.tryParse(_prefs.getString(_registeredKey(user.email)) ?? '');
  }

  Future<void> setLanguage(String language) async {
    await _prefs.setString(_kLanguage, language);
    notifyListeners();
  }

  Future<void> signIn(AppUser user, {DateTime? registeredAt}) async {
    if (registeredAt != null) {
      await _prefs.setString(
          _registeredKey(user.email), registeredAt.toIso8601String());
    }
    await _prefs.setString(_kUser, jsonEncode(user.toJson()));
    _user = user;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _prefs.remove(_kUser);
    _user = null;
    notifyListeners();
  }

  static String _registeredKey(String email) =>
      'registeredAt:${email.trim().toLowerCase()}';

  static AppUser? _readUser(SharedPreferences prefs) {
    final raw = prefs.getString(_kUser);
    if (raw == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }
}
