import 'package:appdev_proj2/views/search_results_view.dart';
import 'package:flutter/material.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreen();

}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage>{
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Text('Welcome, User!'),
          ElevatedButton(
            onPressed: null,
            child: Text('Sign Out'),
          )
        ],
      )
    )
    
  );
}

class _HomeScreen extends State<HomeScreen>{
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Game Tracker'),
        centerTitle: true,
        bottom: TabBar(
          tabs: [
            Tab(text: 'Home', icon: Icon(Icons.home)),
            Tab(text: 'Search', icon: Icon(Icons.search))
          ],
          ),
        ),

        body: TabBarView(
          children:
           [
            HomePage(),
            SearchResultsView(),
           ])
      )
  );
}