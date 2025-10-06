import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/services_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/contact_screen.dart';

void main() {
  runApp(GoldEventsApp());
}

class GoldEventsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gold Events',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/services': (context) => ServicesScreen(),
        '/gallery': (context) => GalleryScreen(),
        '/contact': (context) => ContactScreen(),
      },
    );
  }
}
