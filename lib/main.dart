import 'package:flutter/material.dart';

void main() {
  runApp(const MyFlutterApp());
}

class MyFlutterApp extends StatelessWidget {
  const MyFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'my_flutter_app',
      home: Scaffold(),
    );
  }
}
