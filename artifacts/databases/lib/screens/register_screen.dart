import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';          // for FirebaseAuthException
import 'package:cloud_firestore/cloud_firestore.dart';      // (kept for future use)
import '../services/auth_service.dart';

// Screen to create a new account
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

// This holds the content and logic for the registration
class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Small helper to keep SnackBar usage consistent
  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // This runs when the user presses the register button
  Future<void> _register() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    // 1) Validate inputs
    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _snack('Please fill in all fields');
      return;
    }
    if (password != confirm) {
      _snack('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 2) Create account + save profile
      await _authService.register(
        name: name, phone: phone, email: email, password: password,
      );

      if (!mounted) return;

      // 3) STOP loading before navigating
      setState(() => _isLoading = false);

      // 4) Go back to Login and let Login show a success SnackBar
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
        arguments: {'msg': 'Account created. Please log in.'},
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack(_friendlyAuthError(e));        // shows 'email already in use', etc.
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack('Something went wrong. Please try again.');
    }
  }



  // Map FirebaseAuthException codes to readable messages
  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password': return 'Password is too weak (use at least 6 characters).';
      case 'email-already-in-use': return 'That email is already registered.';
      case 'invalid-email': return 'Email address is invalid.';
      case 'operation-not-allowed': return 'Email/password sign-in is disabled.';
      default: return 'Auth error: ${e.message ?? e.code}';
    }
  }

  // This takes the user to login
  void _goToLogin() {
    Navigator.pop(context);
  }

  // UI builder
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Circle with logo
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade800,
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Image(image: AssetImage('assets/logo.webp')),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // App name
              const Text(
                'Inventory App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 30),

              // Name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: UnderlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Phone
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: UnderlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Email (used as username)
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: UnderlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: UnderlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Confirm Password
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: UnderlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              // Register button
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(_isLoading ? 'Creating account...' : 'Register'),
              ),

              // Link to go back to login
              TextButton(
                onPressed: _goToLogin,
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
