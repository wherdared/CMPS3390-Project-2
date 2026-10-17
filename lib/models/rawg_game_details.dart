import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class RawgGameDetails {
  final int id;
  final String name;
  final String? imageUrl;
  final String? description;
  final double? rating;

  RawgGameDetails({
    required this.id,
    required this.name,
    this.imageUrl,
    this.description,
    this.rating,
  });

  factory RawgGameDetails.fromJson(Map<String, dynamic> json) {
    final rawDescription = (json['description_raw'] as String?)?.trim();
    final ratingsCount = (json['ratings_count'] as num?) ?? 0;
    final rating = json['rating'] as num?;

    return RawgGameDetails(
      id: json['id'],
      name: json['name'],
      imageUrl: json['background_image'],
      description: (rawDescription == null || rawDescription.isEmpty)
        ? null
        : rawDescription,
        rating: (rating != null && ratingsCount > 0) ? rating.toDouble() : null,
    );
  }

  static Future<RawgGameDetails> fetch(int id) async {
    final uri = Uri.https('api.rawg.io', '/api/games/$id', {
      'key': rawgApiKey,
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Rawg request failed (status ${response.statusCode})');
    }

    return RawgGameDetails.fromJson(jsonDecode(response.body));
  }
}