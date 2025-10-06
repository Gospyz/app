import 'package:flutter/material.dart';

class ServicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Servicii')),
      body: Center(
        child: Text('Serviciile noastre', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
