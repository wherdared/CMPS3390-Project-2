import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth.dart'; // Auth.headers adds the login token to requests to our server


// an error that carries the server's own readable message like
// "You already have a list with that name"
class ServerError implements Exception {
  final String message;
  ServerError(this.message);
}

class UserList {
  final int id;
  final String name;
  final int gameCount;

  UserList({required this.id, required this.name, this.gameCount = 0});

  factory UserList.fromJson(Map<String, dynamic> json) {
    return UserList(
      id: json['id'], 
      name: json['name'],
      gameCount: json['game_count'] ?? 0,
      );
  }

  static const String baseUrl = 'http://localhost:3000';

  static Future<List<UserList>> fetchForUser(int userId) async {
    final uri = Uri.parse('$baseUrl/users/$userId/lists');

    final response = await http.get(uri, headers: Auth.headers); // sends the JWT so server know who's asking
    if (response.statusCode != 200) {
      throw Exception('Server request failed (status ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as List;
    return data.map((item) => UserList.fromJson(item)).toList();
  }


  // asks the server to create a list. 201 means it worked
  // if it rejects the name, it throws a server error with server's message
  static Future<UserList> create(int userId, String name) async {
    final uri = Uri.parse('$baseUrl/users/$userId/lists');

    final response = await http.post(
      uri,
      headers: Auth.headers, // JSON content type + login token
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 201) {
      return UserList.fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == 400 ||
        response.statusCode == 404 ||
        response.statusCode == 409) {
          final body = jsonDecode(response.body);
          throw ServerError(body['error'] ?? 'Could not create list');
    }
    throw Exception('Server request failed (status ${response.statusCode})');
  }

  // asks the server to rename the a list.
static Future<void> rename(int userId, int listId, String name) async {
  final uri = Uri.parse('$baseUrl/users/$userId/lists/$listId');

  final response = await http.patch(
    uri,
    headers: Auth.headers, // JSON content type + login token
    body: jsonEncode({'name': name}),
  );

  if (response.statusCode == 200) return;
  if (response.statusCode == 400 ||
      response.statusCode == 404 ||
      response.statusCode == 409) {
        final body = jsonDecode(response.body);
        throw ServerError(body['error'] ?? 'Could not rename list');
      }
      throw Exception('Server request failed (status ${response.statusCode})');
}

// asks the server to delete a list (including all the games in that list)
static Future<void> delete(int userId, int listId) async {
  final uri = Uri.parse('$baseUrl/users/$userId/lists/$listId');

  final response = await http.delete(uri, headers: Auth.headers); // sends the JWT so server know who's asking
  
  if (response.statusCode == 200) return;
  if (response.statusCode == 400 || response.statusCode == 404) {
    final body = jsonDecode(response.body);
    throw ServerError(body['error'] ?? 'Could not delete list');
  }
  throw Exception('Server request failed (status ${response.statusCode})');
}

  // returns true if the game was added, false if it was already in the list
  static Future<bool> addGame(int userId, int listId, int rawgId) async {
    final uri = Uri.parse('$baseUrl/users/$userId/lists/$listId/games');

    final response = await http.post(
      uri,
      headers: Auth.headers, // JSON content type + login token
      body: jsonEncode({'rawg_id': rawgId}),
    );

    if (response.statusCode == 201) return true;
    if (response.statusCode == 409) return false;
    throw Exception('Server request failed (status ${response.statusCode})');
  }
}