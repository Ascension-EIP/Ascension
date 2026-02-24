import 'package:flutter/material.dart';
import 'package:mobile/components/header.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      body: Center(child: Text('Home coming soon!')),
    );
  }
}
