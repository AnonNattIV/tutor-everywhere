import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class AuthProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenStorageKey = 'auth_token';

  bool _isLoggedIn = false;
  String? _token;
  String? _userId;
  String? _role;
  DateTime? _iat;
  DateTime? _exp;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get userId => _userId;
  String? get role => _role;
  DateTime? get iat => _iat;
  DateTime? get exp => _exp;

  Future<void> checkAuth() async {
    final token = await _storage.read(key: _tokenStorageKey);
    if (token == null || token.trim().isEmpty) {
      _clearAuthState();
      notifyListeners();
      return;
    }

    try {
      final jwt = JWT.decode(token);
      final restoredUserId = jwt.payload['userId']?.toString() ?? '';
      final restoredRole = jwt.payload['role']?.toString() ?? '';
      final restoredIat = _epochToUtcDateTime(jwt.payload['iat']);
      final restoredExp = _epochToUtcDateTime(jwt.payload['exp']);

      final isExpired =
          restoredExp != null && restoredExp.isBefore(DateTime.now().toUtc());
      final hasIdentity = restoredUserId.isNotEmpty && restoredRole.isNotEmpty;

      if (!hasIdentity || isExpired) {
        await _storage.delete(key: _tokenStorageKey);
        _clearAuthState();
        notifyListeners();
        return;
      }

      _token = token;
      _userId = restoredUserId;
      _role = restoredRole;
      _iat = restoredIat;
      _exp = restoredExp;
      _isLoggedIn = true;
    } catch (_) {
      await _storage.delete(key: _tokenStorageKey);
      _clearAuthState();
    }

    notifyListeners();
  }

  Future<void> login(String token, String userId, String role) async {
    await _storage.write(key: _tokenStorageKey, value: token);
    _token = token;
    _userId = userId;
    _role = role;
    try {
      final jwt = JWT.decode(token);
      _iat = _epochToUtcDateTime(jwt.payload['iat']);
      _exp = _epochToUtcDateTime(jwt.payload['exp']);
    } catch (_) {
      _iat = null;
      _exp = null;
    }
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenStorageKey);
    _clearAuthState();
    notifyListeners();
  }

  DateTime? _epochToUtcDateTime(dynamic value) {
    int? seconds;
    if (value is int) {
      seconds = value;
    } else if (value is num) {
      seconds = value.toInt();
    } else if (value is String) {
      seconds = int.tryParse(value);
    }

    if (seconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }

  void _clearAuthState() {
    _isLoggedIn = false;
    _token = null;
    _userId = null;
    _role = null;
    _iat = null;
    _exp = null;
  }
}
