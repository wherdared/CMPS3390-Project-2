import 'package:flutter/material.dart';
import '../controllers/game_search_controller.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreen();

}

class _ListScreen extends State<ListScreen>{
  final GameSearchController controller = GameSearchController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

// list data to be added ------------------------------
  void _showItems(){
    showDialog(
      context: context,
      builder: (dialogContext){
        return AlertDialog(
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text("List Name"),
              ElevatedButton(
                onPressed: () => _editList(),
                child: Text("Edit"))
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: ListenableBuilder(
                  listenable: controller,
                  builder: (context, _){
                    return ListView.builder(
                      itemCount: 3,
                      itemBuilder: (context, index){
// game in list data to be added ------------------------------
                      return ListTile(
                        leading: SizedBox(
                          width:60,
                          height:80,
                          child: const Icon(Icons.image_not_supported),
                        ),
                        title: Text("Game Entry"),
                        subtitle: Text("ID: ###"),
                        trailing: ElevatedButton(onPressed: null, child: Icon(Icons.delete)),
                      );
                    }
                  );
                }
              )
            )
              ],
              
            ),
            )
          
        );
      }
      );
  }

  void _addList(){
    showDialog(
      context: context,
      builder: (dialogContext){
        return AlertDialog(
          
          title: Text("Add List"),
          content: SizedBox(
            width: double.maxFinite,
            height: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Enter new list name',
                  border: OutlineInputBorder(),
                  )
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  //create new list functionality to be added
                  onPressed: null,
                  child: Text("Confirm"))
              ],
            ),
          )
        );
      }
      );

  }

  void _editList(){
    showDialog(
      context: context,
      builder: (dialogContext){
        return AlertDialog(
          
          title: Text("Edit List"),
          content: SizedBox(
            width: double.maxFinite,
            height: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Rename list',
                  border: OutlineInputBorder(),
                  )
                ),
                const SizedBox(height: 40),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    //delete list + rename list functionality to be added -------------
                    ElevatedButton(
                      onPressed: null,
                      child: Text("Delete List", style: TextStyle(color: Colors.redAccent),)),
                    ElevatedButton(
                      onPressed: null,
                      child: Text("Rename")),
                  ],
                )
              ],
            ),
          )
        );
      }
      );
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
              Text('Your Lists', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton(onPressed: () => _addList(),
               child: Text('Add List'))
            ],),


            const SizedBox(width: 16),
            Expanded(
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _){
                  return ListView.builder(
                    itemCount: 3,
                    itemBuilder: (context, index){
// list data to be added ------------------------------
                      return ListTile(
                        onTap: () => _showItems(),
                        title: Text("List Name"),
                        subtitle: Text("## Games - by User"),
                      );
                    }
                  );
                }
              )
            )
          ]
        )
      
      )
      );

}

}