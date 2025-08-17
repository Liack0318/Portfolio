import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// This is the main screen for logging
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

//This holds the content and behavior of the logging screen
class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();        // email instead of username
  final _passwordController = TextEditingController();

  //This keeps track whether remember me is selected.
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    // If Register sent a message, show it after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['msg'] is String) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(args['msg']), backgroundColor: Colors.green),
        );
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Small helper to keep SnackBar usage consistent
  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // This runs when the user presses the login button
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // If username or password is empty, show a message
    if (email.isEmpty || password.isEmpty) {
      _snack('Please enter both email and password');
      return;
    }

    // Sign in with Firebase Auth
    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Derive a username to show on /home: prefer displayName, else email
      final displayName = cred.user?.displayName;
      final username = (displayName == null || displayName.isEmpty) ? email : displayName;

      if (!mounted) return;
      // If both fields are filled, move to the home screen
      Navigator.pushReplacementNamed(context, '/home', arguments: username);
    } on FirebaseAuthException catch (e) {
      _snack(_friendlyAuthError(e));
    } catch (_) {
      _snack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  // Small window with instructions to recover password
  Future<void> _recoverPassword() async {
    // Ask for email and send reset link through Firebase
    final controller = TextEditingController(text: _emailController.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Recover Password'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Enter your email'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Send')),
        ],
      ),
    );

    if (email == null || email.isEmpty) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _snack('Password reset email sent to $email', color: Colors.green);
    } on FirebaseAuthException catch (e) {
      _snack(_friendlyAuthError(e));
    } catch (_) {
      _snack('Could not send reset email. Please try again.');
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'invalid-credential':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Auth error: ${e.message ?? e.code}';
    }
  }

  // This build everything on the screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),

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

              const SizedBox(height: 16),

              // App name under the logo
              const Text(
                'Inventory App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 30),

              // Email field (replaces Username)
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: UnderlineInputBorder(), // underline only
                ),
              ),

              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  border: const UnderlineInputBorder(), // underline only
                ),
              ),

              // Row with checkbox and forgot password link
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
                  const Text('Remember me'),
                  const Spacer(),
                  TextButton(
                    onPressed: _recoverPassword,
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Login button
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(_isLoading ? 'Signing in...' : 'Login'),
              ),

              // Link to go to registration screen
              TextButton(
                onPressed: _goToRegister,
                child: const Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
