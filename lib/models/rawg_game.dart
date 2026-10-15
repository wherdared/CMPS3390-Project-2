import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class RawgGame {
  final int id;
  final String name;
  final String? imageUrl;

  RawgGame({required this.id, required this.name, this.imageUrl});

  factory RawgGame.fromJson(Map<String, dynamic> json) {
    return RawgGame(
      id: json['id'],
      name: json['name'],
      imageUrl: json['background_image'],
    );
  }

  static Future<List<RawgGame>> search(String query) async {
    final uri = Uri.https('api.rawg.io', '/api/games', {
      'key': rawgApiKey,
      'search': query,
      'page_size': '10',
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('RAWG request failed (status ${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    final results = data['results'] as List;
    return results.map((item) => RawgGame.fromJson(item)).toList();
  }
}