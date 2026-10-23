import 'package:flutter/foundation.dart';
import '../models/rawg_game.dart';
import '../models/rawg_game_details.dart';
import '../models/user_list.dart';
import '../models/auth.dart';

class GameSearchController extends ChangeNotifier {
  // Temporary until login exists: eveything uses the test user
  // static const int testUserId = 2;
  static int get testUserId => Auth.userId!; // user id of current user logged in

  List<RawgGame> results = [];
  String? error;
  bool hasSearched = false;
  bool isLoading = false;
  final Map<int, RawgGameDetails> _detailsCache = {};

    Future<void> search(String text) async {
    final query = text.trim();
    if (query.isEmpty || isLoading) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      results = await RawgGame.search(query);
      error = null;
    } catch (e) {
      debugPrint('Search failed: $e');
      results = [];
      error = 'Could not load games. Please try again.';
    }

    hasSearched = true;
    isLoading = false;
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

  Future<List<UserList>> getLists() {
    return UserList.fetchForUser(testUserId);
  }

  Future<bool> addGameToList(int listId, int rawgId) {
    return UserList.addGame(testUserId, listId, rawgId);
  }
}