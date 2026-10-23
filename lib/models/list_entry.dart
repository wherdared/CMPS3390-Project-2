import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_list.dart';

// One game saved in a list, as the server stores it (just the RAWG id and status)
class ListEntry {
  final int id;
  final int rawgId;
  final String status;

  ListEntry({required this.id, required this.rawgId, required this.status});

  factory ListEntry.fromJson(Map<String, dynamic> json) {
    return ListEntry(
      id: json['id'],
      rawgId: json['rawg_id'],
      status: json['status'],
    );
  }

  // Asks the server for the games saved in one list
  static Future<List<ListEntry>> fetchForList(int userId, int listId) async {
    final uri = Uri.parse(
      '${UserList.baseUrl}/users/$userId/lists/$listId/games',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Server request failed (status ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as List;
    return data.map((item) => ListEntry.fromJson(item)).toList();
  }

  // Asks the server to remove one game from a list
  static Future<void> remove(int userId, int listId, int rawgId) async {
    final uri = Uri.parse(
      '${UserList.baseUrl}/users/$userId/lists/$listId/games/$rawgId',
    );

    final response = await http.delete(uri);

    if (response.statusCode == 200) return;
    if (response.statusCode == 400 || response.statusCode == 404) {
      final body = jsonDecode(response.body);
      throw ServerError(body['error'] ?? 'Could not remove game');
    }
    throw Exception('Server request failed (status ${response.statusCode})');
  }
}

// A game as the list popup shows it: the RAWG id plus the name and cover
// that were looked up from RAWG
class ListGame {
  final int rawgId;
  final String name;
  final String? imageUrl;

  ListGame({required this.rawgId, required this.name, this.imageUrl});
}