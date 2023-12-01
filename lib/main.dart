import 'package:flutter/material.dart';
import 'package:gestao_despesas/views/LoginScreen.dart';
import 'package:firebase_core/firebase_core.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyBLx-l4XZn5jtyBv7bA5Hovtz4t4bK7sQY",
      appId:  "1:1014146262633:web:90b1bf50bf378a5a8724f8",
      messagingSenderId:  "1014146262633",
      projectId: "gestao-despesas")
  );
  runApp(
    MaterialApp(
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: false),
    )
    );
}

