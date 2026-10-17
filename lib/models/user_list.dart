import 'dart:convert';
import 'package:http/http.dart' as http;

class UserList {
  final int id;
  final String name;

  UserList({required this.id, required this.name});

  factory UserList.fromJson(Map<String, dynamic> json) {
    return UserList(id: json['id'], name: json['name']);
  }

  static const String baseUrl = 'http://localhost:3000';

  static Future<List<UserList>> fetchForUser(int userId) async {
    final uri = Uri.parse('$baseUrl/users/$userId/lists');

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Server request failed (status ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as List;
    return data.map((item) => UserList.fromJson(item)).toList();
  }

  // returns true if the game was added, false if it was already in the list
  static Future<bool> addGame(int userId, int listId, int rawgId) async {
    final uri = Uri.parse('$baseUrl/users/$userId/lists/$listId/games');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'rawg_id': rawgId}),
    );

    if (response.statusCode == 201) return true;
    if (response.statusCode == 409) return false;
    throw Exception('Server request failed (status ${response.statusCode})');
  }
}