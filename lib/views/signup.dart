import 'package:flutter/material.dart';
import 'package:appdev_proj2/models/auth.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreen();
}

class _SignUpScreen extends State<SignUpScreen>{
  final _username = TextEditingController();
  final _password = TextEditingController();

  // added: same error popup as Log In
  void _inputError(String message) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("Error!"),
          content: Text(message),
        );
      }
    );
  }

  Future<void> _submit() async {
    // null = account created, otherwise an error message
    final error = await Auth.signup(_username.text.trim(), _password.text);

    // stop if this screen was closed while waiting for the server
    if (!mounted) return;

    if (error == null) {
      // account created: close Sign Up and go back to Log In
      Navigator.pop(context);
    } else {
      // failed: show the server's message, e.g. "Username is taken"
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
            Text("Sign Up", style: TextStyle(fontSize: 32)),
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
                  Navigator.pop(context);
                },
                child: Text("Already have an Account? Log In"),
              ),
          ]
        )
      )
    )
    
  );
}
