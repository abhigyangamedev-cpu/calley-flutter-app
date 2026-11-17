import '../models.dart';
import 'api_client.dart';

/// In-memory stand-in for the Calley mock API, used when the real server is
/// unavailable (as of Nov 2026 mock-api.calleyacd.com answers every endpoint
/// with an Apache 404 page). Responses mirror the examples in the Postman
/// "Mock API V2" collection.
class DemoBackend {
  /// The OTP accepted in demo mode. It is shown on the OTP screen, because no
  /// email is actually sent.
  static const otp = '123456';

  static const _sampleListId = '68626fb697757cb741f449b9';

  final _users = <String, ({String id, String username, String password})>{};
  final _verified = <String>{};
  int _nextId = 1;

  String _key(String email) => email.trim().toLowerCase();

  void register({
    required String username,
    required String email,
    required String password,
  }) {
    final key = _key(email);
    if (_users.containsKey(key)) {
      throw const ApiException('User already exists');
    }
    _users[key] = (
      id: 'demo-user-${_nextId++}',
      username: username,
      password: password,
    );
  }

  void sendOtp(String email) {
    // Nothing to send: the demo OTP is fixed and displayed in the app.
  }

  void verifyOtp({required String email, required String otp}) {
    if (otp != DemoBackend.otp) throw const ApiException('Invalid OTP');
    _verified.add(_key(email));
  }

  AppUser login({required String email, required String password}) {
    final key = _key(email);
    final user = _users[key];
    if (user == null) {
      // Demo accounts only live in memory, so after an app restart let any
      // email sign in rather than locking the tester out.
      final created = (
        id: 'demo-user-${_nextId++}',
        username: email.split('@').first,
        password: password,
      );
      _users[key] = created;
      return AppUser(id: created.id, username: created.username, email: email.trim());
    }
    if (user.password != password) {
      throw const ApiException('Invalid email or password');
    }
    return AppUser(id: user.id, username: user.username, email: email.trim());
  }

  List<CallingList> getLists() =>
      const [CallingList(id: _sampleListId, name: 'Test List')];

  ListDetails getListDetails(String listId) => const ListDetails(
        pending: 27,
        called: 23,
        rescheduled: 11,
        callCount: 0,
      );
}
