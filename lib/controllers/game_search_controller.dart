import 'package:flutter/foundation.dart';
import '../models/rawg_game.dart';
import '../models/rawg_game_details.dart';

class GameSearchController extends ChangeNotifier {
  List<RawgGame> results = [];
  String? error;
  bool hasSearched = false;
  final Map<int, RawgGameDetails> _detailsCache = {};

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

    hasSearched = true;
    notifyListeners();
  }

  // stores game details into a cache that way that second api call doesn't have to happen again
  Future<RawgGameDetails> getDetails(int id) async {
    final cached = _detailsCache[id];
    if (cached!= null) return cached;

    final details = await RawgGameDetails.fetch(id);
    _detailsCache[id] = details;
    return details;
  }
}