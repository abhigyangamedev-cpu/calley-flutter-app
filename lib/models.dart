class AppUser {
  const AppUser({required this.id, required this.username, required this.email});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        username: (json['username'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
      );

  final String id;
  final String username;
  final String email;

  Map<String, dynamic> toJson() => {'_id': id, 'username': username, 'email': email};
}

/// Details typed on the registration screen, carried to the OTP screen so we
/// can log in (to obtain the user id) once the OTP is verified.
class PendingRegistration {
  const PendingRegistration({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;
}

class CallingList {
  const CallingList({required this.id, required this.name});

  factory CallingList.fromJson(Map<String, dynamic> json) => CallingList(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        name: (json['name'] ?? 'Untitled list').toString(),
      );

  final String id;
  final String name;
}

class ListDetails {
  const ListDetails({
    required this.pending,
    required this.called,
    required this.rescheduled,
    required this.callCount,
  });

  factory ListDetails.fromJson(Map<String, dynamic> json) => ListDetails(
        pending: _toInt(json['pending']),
        called: _toInt(json['called']),
        rescheduled: _toInt(json['rescheduled']),
        callCount: json['calls'] is List ? (json['calls'] as List).length : 0,
      );

  final int pending;
  final int called;
  final int rescheduled;

  /// Number of entries in the `calls` array returned by the API.
  final int callCount;

  /// Total numbers in the list. Prefer the real number of calls; fall back to
  /// pending + called (rescheduled calls are a subset of those).
  int get total => callCount > 0 ? callCount : pending + called;
}

int _toInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
