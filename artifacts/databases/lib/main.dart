import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_item_screen.dart';
import 'screens/all_items_screen.dart';
import 'screens/item_detail_screen.dart';
import 'screens/view_all_categories_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // enable app check (use debug provider while developing/emulator)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // enable app check (use debug provider while developing/emulator)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

// force fetch a token so we can verify setup
  try {
    final token = await FirebaseAppCheck.instance.getToken(true);
    debugPrint('AppCheck token (prefix): ${token?.substring(0, 12)}...');
  } catch (e) {
    debugPrint('AppCheck token fetch failed: $e');
  }

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
        '/allItems': (context) => const AllItemsScreen(),
        '/itemDetail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ItemDetailScreen(item: args);
        },
        '/viewCategories': (context) => ViewAllCategoriesScreen(),
      },
    );
  }
}

