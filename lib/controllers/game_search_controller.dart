import 'package:flutter/foundation.dart';
import '../models/rawg_game.dart';

class GameSearchController extends ChangeNotifier {
  List<RawgGame> results = [];
  String? error;

    Future<void> search(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    try {
      results = await RawgGame.search(query);
      error = null;
    } catch (e) {
      debugPrint('Search failed: $e');
      results = [];
      error = 'Could not load games. Please try again.';
    }
    notifyListeners();
  }
}