import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../controllers/game_search_controller.dart';

class SearchResultsView extends StatefulWidget {
  const SearchResultsView({super.key});

  @override
  State<SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends State<SearchResultsView> {
  final GameSearchController controller = GameSearchController();
  final TextEditingController searchTextController = TextEditingController();

  @override
  void dispose() {
    searchTextController.dispose();
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
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: SizedBox(
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              details.imageUrl!,
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                            ),
                          ),
                        if (details.released != null) ...[
                          const SizedBox(height: 12),
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Release date: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: details.released),
                              ],
                            ),
                          ),
                        ],
                        if (details.publishers.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: details.publishers.length > 1
                                      ? 'Publishers: '
                                      : 'Publisher: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: details.publishers.join(', ')),
                              ],
                            ),
                          ),
                        ],
                        if (details.rating != null) ...[
                          const SizedBox(height: 12),
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Rating: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text:
                                      '${details.rating!.toStringAsFixed(1)} / 5',
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (details.genres.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Genres',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final genre in details.genres)
                                Chip(label: Text(genre)),
                            ],
                          ),
                        ],
                        if (details.platforms.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Platforms',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final platform in details.platforms)
                                Chip(label: Text(platform)),
                            ],
                          ),
                        ],
                        if (details.description != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'About',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(details.description!),
                        ],
                      ],
                    ),
                  );
                },
              ),
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
                            final added = await controller.addGameToList(
                              list.id,
                              gameId,
                            );
                            message = added
                                ? 'Added $gameName to ${list.name}'
                                : '$gameName is already in ${list.name}';
                          } catch (e) {
                            debugPrint('Add failed: $e');
                            message =
                                'Could not add $gameName. Please try again.';
                          }

                          if (!dialogContext.mounted) return;
                          Navigator.of(dialogContext).pop();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(message)));
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
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: searchTextController,
              builder: (context, value, _) {
                return TextField(
                  controller: searchTextController,
                  decoration: InputDecoration(
                    hintText: 'Search for a game and press Enter',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),

                    suffixIcon: value.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: searchTextController.clear,
                          ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: controller.search,
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  if (controller.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.error != null) {
                    return Text(controller.error!);
                  }
                  if (!controller.hasSearched) {
                    return const Center(
                      child: Text('Search for a game to get started'),
                    );
                  }
                  if (controller.hasSearched && controller.results.isEmpty) {
                    return const Text(
                      'No games found. Try a different search.',
                    );
                  }
                  return ListView.builder(
                    itemCount: controller.results.length,
                    itemBuilder: (context, index) {
                      final game = controller.results[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _showDetails(game.id, game.name),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 120,
                                    height: 90,
                                    child: game.imageUrl == null
                                        ? const Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                            ),
                                          )
                                        : Image.network(
                                            game.imageUrl!,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        game.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      if (game.released != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Release date: ${game.released}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
