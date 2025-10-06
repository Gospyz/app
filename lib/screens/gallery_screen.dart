import 'package:flutter/material.dart';

class GalleryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Galerie Foto')),
      body: Center(
        child: Text('Galerie foto Gold Events', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
