import 'package:flutter/material.dart';
import 'package:mobile/components/header.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(
        title: 'Statistiques',
        description: 'Analyse détaillée de vos performances',
      ),
      body: Center(child: Text('Stats coming soon!')),
    );
  }
}
