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
                  return ListView.builder(
                    itemCount: controller.results.length,
                    itemBuilder: (context, index) {
                      final game = controller.results[index];
                      return ListTile(
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