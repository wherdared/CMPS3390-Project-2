import 'package:flutter/material.dart';
import '../controllers/game_search_controller.dart';

class SearchResultsView extends StatefulWidget {
  const SearchResultsView({super.key});

  @override
  State<SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends State<SearchResultsView> {
  final GameSearchController controller = GameSearchController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _showDetails(int gameId, String gameName) {
    final future = controller.getDetails(gameId);
    final listsFuture = controller.getLists();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(gameName),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  debugPrint('Details failed: ${snapshot.error}');
                  return const Text(
                    'Could not load game details. Please try again.',
                  );
                }

                final details = snapshot.data!;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (details.imageUrl != null)
                        Image.network(
                          details.imageUrl!,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      if (details.rating != null) ...[
                        const SizedBox(height: 12),
                        Text('Rating: ${details.rating!.toStringAsFixed(1)} / 5'),
                      ],
                      if (details.description != null) ...[
                        const SizedBox(height: 12),
                        Text(details.description!),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            FutureBuilder(
              future: listsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const ElevatedButton(
                    onPressed: null,
                    child: Text('Add to list'),
                  );
                }
                if (snapshot.hasError) {
                  debugPrint('Lists failed: ${snapshot.error}');
                  return const ElevatedButton(
                    onPressed: null,
                    child: Text('Lists unavailable'),
                  );
                }

                final lists = snapshot.data!;
                if (lists.isEmpty) {
                  return const ElevatedButton(
                    onPressed: null,
                    child: Text('No Lists Yet'),
                  );
                }

                return MenuAnchor(
                  menuChildren: [
                    for (final list in lists)
                      MenuItemButton(
                        onPressed: () async {
                          String message;
                          try {
                            final added = 
                              await controller.addGameToList(list.id, gameId);
                            message = added
                              ? 'Added $gameName to ${list.name}'
                              : '$gameName is already in ${list.name}';
                          } catch (e) {
                            debugPrint('Add failed: $e');
                            message = 'Could not add $gameName. Please try again.';
                          }

                          if (!dialogContext.mounted) return;
                          Navigator.of(dialogContext).pop();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                        },
                        child: Text(list.name),
                      ),
                  ],
                  builder: (context, menuController, child) {
                    return ElevatedButton(
                      onPressed: () {
                        if (menuController.isOpen) {
                          menuController.close();
                        } else {
                          menuController.open();
                        }
                      },
                      child: const Text('Add to list'),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
    
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Games')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search for a game and press Enter',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: controller.search,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  if (controller.error != null) {
                    return Text(controller.error!);
                  }
                  if (controller.hasSearched && controller.results.isEmpty) {
                    return const Text('No games found. Try a different search.');
                  }
                  return ListView.builder(
                    itemCount: controller.results.length,
                    itemBuilder: (context, index) {
                      final game = controller.results[index];
                      return ListTile(
                        onTap: () => _showDetails(game.id, game.name),
                        leading: SizedBox(
                          width: 80,
                          height: 60,
                          child: game.imageUrl == null
                              ? const Icon(Icons.image_not_supported)
                              : Image.network(game.imageUrl!, fit: BoxFit.cover),
                        ),
                        title: Text(game.name),
                        subtitle: Text('ID: ${game.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}