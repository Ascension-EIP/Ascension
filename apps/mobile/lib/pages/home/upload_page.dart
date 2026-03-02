import 'package:flutter/material.dart';
import 'package:mobile/components/header.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(
        title: 'Uploader une vidéo',
        description:
            'Filmez ou importez votre session pour une analyse détaillée',
      ),
      body: Center(child: Text('Upload coming soon!')),
    );
  }
}
