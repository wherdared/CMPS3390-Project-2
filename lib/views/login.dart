import 'package:appdev_proj2/views/signup.dart';
import 'package:flutter/material.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreen();
}


class _LoginScreen extends State<LoginScreen>{
  void _inputError() {
  showDialog(
    context: context,
    builder: (dialogContext){
      return AlertDialog(
        title: Text("Error!"),
        content: Text("This is an error message"),
    );
  }
  );
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
                onPressed: () => _inputError(),
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
