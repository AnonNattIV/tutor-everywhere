import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  bool _isLoggedIn = false;
  String? _token;
  String? _userId;
  DateTime? _iat;
  DateTime? _exp;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get userId => _userId;
  DateTime? get iat => _iat;
  DateTime? get exp => _exp;

  Future<void> checkAuth() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      _token = token;
      _isLoggedIn = true;
      // TODO: Validate token
    }
    notifyListeners();
  }

  Future<void> login(String token, String userId) async {
    await _storage.write(key: 'auth_token', value: token);
    _token = token;
    _userId = userId;
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _token = null;
    _userId = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}