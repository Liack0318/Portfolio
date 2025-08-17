import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_item_screen.dart';

void main() {
  runApp(const MyApp());
}

// Main part of the app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory App', // App name shown in the background or switcher

      // Overall design style and colors
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // this tells the app to show the login screen first
      initialRoute: '/login',
      // Navigation to the screens
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) {
          final username = ModalRoute.of(context)!.settings.arguments as String?;
          return HomeScreen(username: username ?? 'User');
        },
        '/addItem': (context) => const AddItemScreen(),
      },
    );
  }
}

