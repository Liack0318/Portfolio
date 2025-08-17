import 'package:flutter/material.dart';

// This is the main screen for logging
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

//This holds the content and behavior of the logging screen
class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  //This keeps track whether remember me is selected.
  bool _rememberMe = false;

  // This runs when the user presses the login button
  void _login() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // If username or password is empty, show a message
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both username and password')),
      );
      return;
    }

    // If both fields are filled, move to the home screen
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _goToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  // Small window with instructions to recover password
  void _recoverPassword() {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: Text('Recover Password'),
            content: Text('Recovery instructions go here.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context), child: Text('OK')),
            ],
          ),
    );
  }

  // This build everything on the screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(height: 40),

              // Circle with logo inside
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade800,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Image.asset('assets/logo.webp'),
                  ),
                ),
              ),

              SizedBox(height: 16),

              // App name under the logo
              Text(
                'Inventory App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),

              SizedBox(height: 30),

              //Username field
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                  border: UnderlineInputBorder(), // underline only
                ),
              ),

              SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: UnderlineInputBorder(), // underline only
                ),
              ),

              // Row with checkbox and forgot paassword link
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (val) {
                      setState(() {
                        _rememberMe = val ?? false;
                      });
                    },
                  ),
                  Text('Remember me'),
                  Spacer(),
                  TextButton(
                    onPressed: _recoverPassword,
                    child: Text('Forgot Password?'),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Login button
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
                child: Text('Login'),
              ),

              // Link to go to registration screen
              TextButton(
                onPressed: _goToRegister,
                child: Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}