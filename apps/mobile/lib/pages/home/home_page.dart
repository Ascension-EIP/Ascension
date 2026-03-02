import 'package:flutter/material.dart';
import 'package:mobile/components/header.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(
        title: 'Ascension',
        description: 'Visualiser l\'invisible',
        descriptionColor: Color(0xFF00B5D3),
        logoPath: 'assets/images/logo.png',
      ),
      body: Center(child: Text('Home coming soon!')),
    );
  }
}
