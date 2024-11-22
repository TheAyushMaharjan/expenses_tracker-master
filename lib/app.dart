import 'package:expenses_tracker/screens/Login/LoginPage.dart';
import 'package:flutter/material.dart'; // Import the LoginPage widget
import 'package:get/get.dart'; // Import GetX package

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( // Use GetMaterialApp instead of MaterialApp
      
      title: 'My Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginPage(), // Directly navigate to LoginPage
    );
  }
}
