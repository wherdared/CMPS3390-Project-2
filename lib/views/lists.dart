import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../controllers/list_controller.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreen();
}

class _ListScreen extends State<ListScreen> {
  final ListController controller = ListController();

  // loads the user's lists when the screen opens
  @override
  void initState() {
    super.initState();
    controller.loadLists();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // list data to be added ------------------------------
  void _showItems(int listId, String listName) {
    var gamesFuture = controller.getGames(listId);
    String? errorText;
    bool isRemoving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Runs when game's trash button is tapped
            Future<void> remove(int rawgId) async {
              if (isRemoving) return;
              setDialogState(() {
                isRemoving = true;
                errorText = null;
              });

              final error = await controller.removeGame(listId, rawgId);
              if (!dialogContext.mounted) return;

              setDialogState(() {
                isRemoving = false;
                if (error == null) {
                  gamesFuture = controller.getGames(listId);
                } else {
                  errorText = error;
                }
              });
            }

            return AlertDialog(
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Text(listName, overflow: TextOverflow.ellipsis),
                  ),
                  // changed it so when a list is renamed or deleted, this popup would close
                  ElevatedButton(
                    onPressed: () async {
                      final changed = await _editList(listId, listName);
                      if (changed && dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                    child: Text("Edit"),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 360, // a fixed height so the games have room to scroll
                child: Column(
                  children: [
                    if (errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    Expanded(
                      child: FutureBuilder(
                        future: gamesFuture,
                        builder: (context, snapshot) {
                          // spinner for when the games load
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          // message if server can't be reached
                          if (snapshot.hasError) {
                            debugPrint(
                              'Loading games failed: ${snapshot.error}',
                            );
                            return const Text(
                              'Could not load games. Is the server running?',
                            );
                          }

                          final games = snapshot.data!;
                          if (games.isEmpty) {
                            return const Text(
                              'This list has no games yet. Add some from the Search tab',
                            );
                          }
                          return ListView.builder(
                            itemCount: games.length,
                            itemBuilder: (context, index) {
                              // game in list data to be added ------------------------------
                              final game = games[index];
                              return ListTile(
                                leading: SizedBox(
                                  width: 60,
                                  height: 80,
                                  child: game.imageUrl == null
                                      ? const Icon(Icons.image_not_supported)
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            game.imageUrl!,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                ),
                                title: Text(game.name),
                                trailing: ElevatedButton(
                                  onPressed: isRemoving
                                      ? null
                                      : () => remove(game.rawgId),
                                  child: const Icon(Icons.delete),
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
          },
        );
      },
    );
  }

  void _addList() {
    final nameController = TextEditingController();
    String? errorText;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        // lets popup redraw itself to show the error message without rebuilding whole screen
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (isSaving) return;
              setDialogState(() {
                isSaving = true;
                errorText = null;
              });

              final error = await controller.createList(nameController.text);
              if (!dialogContext.mounted) return;

              if (error == null) {
                // closes popup if worked
                Navigator.of(dialogContext).pop();
              } else {
                // show why it didn't
                setDialogState(() {
                  isSaving = false;
                  errorText = error;
                });
              }
            }

            return AlertDialog(
              title: Text("Add List"),
              content: SizedBox(
                width: double.maxFinite,
                height: 200, // changed this so that the error message could fit
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter new list name',
                        border: OutlineInputBorder(),
                        errorText: errorText,
                      ),
                      onSubmitted: (_) => submit(),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      //create new list functionality to be added
                      onPressed: isSaving ? null : submit,
                      child: Text("Confirm"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // changed it so that it now takes the list's id and name, and returns true if the list was renamed/deleted
  Future<bool> _editList(int listId, String listName) async {
    final nameController = TextEditingController(text: listName);
    String? errorText;
    bool isWorking = false;

    final changed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // runs when rename button is tapped
            Future<void> rename() async {
              if (isWorking) return;
              setDialogState(() {
                isWorking = true;
                errorText = null;
              });

              final error = await controller.renameList(
                listId,
                nameController.text,
              );
              if (!dialogContext.mounted) return;

              if (error == null) {
                Navigator.of(dialogContext).pop(true);
              } else {
                setDialogState(() {
                  isWorking = false;
                  errorText = error;
                });
              }
            }

            // runs when delete list button is tapped
            Future<void> delete() async {
              if (isWorking) return;

              final confirmed = await showDialog<bool>(
                context: dialogContext,
                builder: (confirmContext) {
                  return AlertDialog(
                    title: const Text("Delete list?"),
                    content: Text(
                      'This will remove "$listName" and all the games in it. This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(confirmContext).pop(false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(confirmContext).pop(true),
                        child: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (confirmed != true || !dialogContext.mounted) return;

              setDialogState(() {
                isWorking = true;
                errorText = null;
              });

              final error = await controller.deleteList(listId);
              if (!dialogContext.mounted) return;

              if (error == null) {
                Navigator.of(dialogContext).pop(true);
              } else {
                setDialogState(() {
                  isWorking = false;
                  errorText = error;
                });
              }
            }

            return AlertDialog(
              title: Text("Edit List"),
              content: SizedBox(
                width: double.maxFinite,
                height: 200, // changed to 200 for error message
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Rename list',
                        border: const OutlineInputBorder(),
                        errorText: errorText,
                      ),
                      onSubmitted: (_) => rename(),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        //delete list + rename list functionality to be added -------------
                        ElevatedButton(
                          onPressed: isWorking ? null : delete,
                          child: Text(
                            "Delete List",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: isWorking ? null : rename,
                          child: Text("Rename"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    return changed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  'Your Lists',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton(
                  onPressed: () => _addList(),
                  child: Text('Add List'),
                ),
              ],
            ),

            const SizedBox(width: 16),
            Expanded(
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  // loading symbol
                  if (controller.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // message if the server can't be reached
                  if (controller.error != null) {
                    return Text(controller.error!);
                  }
                  // message when the user has no lists yet
                  if (controller.lists.isEmpty) {
                    return const Text(
                      'You have no lists yet. Tap Add List to create a one',
                    );
                  }
                  return ListView.builder(
                    itemCount: controller.lists.length,
                    itemBuilder: (context, index) {
                      final list = controller.lists[index];
                      return ListTile(
                        onTap: () => _showItems(list.id, list.name),
                        title: Text(list.name),
                        // i dropped the "by user" since only the user would be able to see their own lists
                        subtitle: Text(
                          list.gameCount == 1
                              ? '1 game'
                              : '${list.gameCount} games',
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
