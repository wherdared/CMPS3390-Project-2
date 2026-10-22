import 'package:flutter/foundation.dart';
import '../models/user_list.dart';
import '../models/rawg_game_details.dart';
import '../models/list_entry.dart';

class ListController extends ChangeNotifier {
  // temporary until login exists
  static const int testUserId = 2;

  List<UserList> lists = [];
  bool isLoading = false;
  String? error;

  // remember each game's name and cover after the first lookup, so repoening a list doesn't call RAWG again
  final Map<int, RawgGameDetails> _gameCache = {};

  // Asks the server for the user's lists and tells the screen when its done
  Future<void> loadLists() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      lists = await UserList.fetchForUser(testUserId);
    } catch (e) {
      lists = [];
      error = 'Could not load your lists. Is the server running?';
    }
    
    isLoading = false;
    notifyListeners();
  }

  // Creates a list. Returns null when it worked, or a message to show the user when it didn't
  Future<String?> createList(String name) async {
    // Checks the name before asking the server
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Please enter a list name.';
    if (trimmed.length > 50) return 'List name must be 50 characters or less.';

    try {
      await UserList.create(testUserId, trimmed);
    } on ServerError catch (e) {
      return e.message;     // server says no
    } catch (e) {
      debugPrint('Create list failed: $e');
      return 'Could not create list. Please try again.';
    }

    // if worked, reload the lists
    await loadLists();
    return null;
  }

  // Renames a list.
  Future<String?> renameList(int listId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Please enter a list name.';
    if (trimmed.length > 50) return 'List name must be 50 characters or less';

    try {
      await UserList.rename(testUserId, listId, trimmed);
    } on ServerError catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('Rename list failed: $e');
      return 'Could not rename list. Please try again.';
    }
    await loadLists();
    return null;
  }

  // deletes a list
  Future<String?> deleteList(int listId) async {
    try {
      await UserList.delete(testUserId, listId);
    } on ServerError catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('Delete list failed: $e');
      return 'Could not delete list. Please try again';
    }
    await loadLists();
    return null;
  }

  // gets the game in a list, server only returns RAWG's ids, so this looks up each game's name and cover from RAWG
  Future<List<ListGame>> getGames(int listId) async {
    final entries = await ListEntry.fetchForList(testUserId, listId);

    return Future.wait(entries.map((entry) async {
      try {
        final details = _gameCache[entry.rawgId] ??
            await RawgGameDetails.fetch(entry.rawgId);
        _gameCache[entry.rawgId] = details;
        return ListGame(
          rawgId: entry.rawgId,
          name: details.name,
          imageUrl: details.imageUrl,
        );
      } catch (e) {
        debugPrint('Game lookup failed for ${entry.rawgId}: $e');
        return ListGame(rawgId: entry.rawgId, name: 'Game #${entry.rawgId}');
      }
    }));
  }

  // Removes a game fron a list, Returns null when it work, or a message to show user when it didn't
  Future<String?> removeGame(int listId, int rawgId) async {
    try {
      await ListEntry.remove(testUserId, listId, rawgId);
    } on ServerError catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('Remove game failed: $e');
      return 'Could not remove game. Please try again.';
    }

    // reloads the lists so the game coun ton the list page updates
    await loadLists();
    return null;
  }
}