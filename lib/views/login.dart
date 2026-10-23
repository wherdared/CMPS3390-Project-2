import 'package:appdev_proj2/views/signup.dart';
import 'package:flutter/material.dart';
import 'package:appdev_proj2/models/auth.dart';
import 'package:appdev_proj2/views/home.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreen();
}


class _LoginScreen extends State<LoginScreen>{
  final _username = TextEditingController();
  final _password = TextEditingController();

  void _inputError(String message) {
  showDialog(
    context: context,
    builder: (dialogContext){
      return AlertDialog(
        title: Text("Error!"),
        content: Text(message),
    );
  }
  );
}
  Future<void> _submit() async {
    // null = logged in, otherwise an error msg
    final error = await Auth.login(_username.text.trim(), _password.text); // trim() redundancy to avoid unexpected behavior
    if (!mounted) return; // stop if screen closed while waiting for server

    if (error == null) {
      // logged in: replace Log In with Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      _inputError(error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Text("Log In", style: TextStyle(fontSize: 32)),
            const SizedBox(height: 20),
            TextField(
                controller: _username,
                decoration: const InputDecoration(
                  hintText: 'Username',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textInputAction: null,
                onSubmitted: null,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                textInputAction: null,
                onSubmitted: null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: Text("Submit")),
              TextButton(
                onPressed: () {
                  Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SignUpScreen()));
                },
                child: Text("No account yet? Sign Up"),
              ),
          ]
        )
      )
    )
    
  );
}
