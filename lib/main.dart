import 'package:flutter/material.dart';
import 'package:turf_client/firebase_options.dart';
import 'package:turf_client/screens/home/home_screen.dart';
import 'screens/auth_screens/login_screen.dart';
import 'screens/auth_screens/signup_screen.dart';
import 'splashscreen.dart'; // Import the Splashscreen
import 'package:firebase_core/firebase_core.dart'; // Import Firebase core

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // If you have generated platform-specific options
  ); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book MY Turf',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/', // Set initial route to Splashscreen
      routes: {
        '/': (context) => Splashscreen(), // Splashscreen as the initial route
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
