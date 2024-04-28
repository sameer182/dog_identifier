import 'package:dog_identifier/home.dart';
import 'package:flutter/material.dart';
import 'package:dog_identifier/splash_screen.dart';

void main() {
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


