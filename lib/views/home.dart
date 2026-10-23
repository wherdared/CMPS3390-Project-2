import 'package:appdev_proj2/views/search_results_view.dart';
import 'package:appdev_proj2/views/lists.dart';
import 'package:flutter/material.dart';
import 'package:appdev_proj2/models/auth.dart';
import 'package:appdev_proj2/views/login.dart';


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
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Text('Welcome, ${Auth.username}!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ElevatedButton(
            onPressed: () {
              Auth.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
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
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Game Tracker'),
        centerTitle: true,
        bottom: TabBar(
          tabs: [
            Tab(text: 'Home', icon: Icon(Icons.home)),
            Tab(text: 'Search', icon: Icon(Icons.search)),
            Tab(text: 'Lists', icon: Icon(Icons.menu))
          ],
          ),
        ),

        body: TabBarView(
          children:
           [
            HomePage(),
            SearchResultsView(),
            ListScreen(),
           ])
      )
  );
}