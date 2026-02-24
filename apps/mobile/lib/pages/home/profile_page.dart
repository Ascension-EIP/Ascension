import 'package:flutter/material.dart';
import 'package:mobile/components/header.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(title: 'Profil', centerTitle: true),
      body: Center(child: Text('Profile coming soon!')),
    );
  }
}
