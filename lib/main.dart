import 'package:appdev_proj2/models/auth.dart';
import 'package:appdev_proj2/views/home.dart';
import 'package:appdev_proj2/views/login.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // required before using a plugin
  await Auth.restore(); // load a saved login, if any
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Tracker',
      // Saved JWT? Skip straight to Home.
      home: Auth.userId != null ? const HomeScreen() : const LoginScreen(),
    );
  }
}
