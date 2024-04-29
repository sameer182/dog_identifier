import 'package:dog_identifier/home.dart';
import 'package:flutter/material.dart';
import 'package:dog_identifier/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async{
  // Load environment variables from the .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Error loading .env file: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Breed Prediction',
      // home: HomeScreen(),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}


