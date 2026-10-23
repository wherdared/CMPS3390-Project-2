import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'user_list.dart'; // for baseUrl (our server's address)

// Handles user authentication: stores JWT on app
// Supplies what server needs for authorization (what user can access)
// Everything is static, so any screen can use Auth.login(...) or Auth.userId, etc.
class Auth {
  static final storage = Platform.isMacOS
    ? const FlutterSecureStorage(
      mOptions: MacOsOptions(usesDataProtectionKeychain: false),
    )
    : const FlutterSecureStorage();


  // JWT from /login. leading _ makes it private to this file
  static String? _token;

  // User's id, used in URLS like /users/5/lists.
  // Server checks that it matches token (checkSameUser)
  static int? userId;

  // Added this so username is shown on Home
  static String? username;

  // Loads the saved login, if any
  static Future<void> restore() async {
    String? session = await storage.read(key: 'session');
    if (session != null) _remember(session);
  }
  // Keeps the token, id, and username from a /login response
  static void _remember(String json) {
    final session = jsonDecode(json);
    _token = session['token'];
    userId = session['userId'];
    username = session['username'];
  }

  // Sends user & pass to server, if checks passed, server returns
  // a signed JWT plus user's id & username
  // Returns null on success, or an error message to show the user
  static Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${UserList.baseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode != 200) {
        return jsonDecode(response.body)['error'] ?? 'Could not log in.';
      }

      _remember(response.body);
      await storage.write(key: 'session', value: response.body);
      return null;
    } catch (_) {
      return 'Could not reach the server.';
    }
  }

  // Creates account. User logs in afterwards
  // Returns null on success, or an error message
  static Future<String?> signup(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${UserList.baseUrl}/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode != 201) {
        return jsonDecode(response.body)['error'] ?? 'Could not sign up';
      }
      return null;
    } catch (e) {
      return 'Could not reach the server.';
    }
  }

  // Forgets the login, so app can't make requests w/user anymore
  static Future<void> logout() async {
    _token = null;
    await storage.delete(key: 'session');
  }

  // Added to every request to our server, carrying the JWT as
  // "Bearer <token>"
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };
}