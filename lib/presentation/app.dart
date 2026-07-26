import 'package:flutter/material.dart';

class AITreasureHuntApp extends StatelessWidget {
  const AITreasureHuntApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Treasure Hunt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: const Text('AI Treasure Hunt')),
        body: const Center(child: Text('App Repaired and Ready!')),
      ),
    );
  }
}
