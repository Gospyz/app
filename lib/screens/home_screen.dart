import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gold Events'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.amber),
              child: Text('Meniu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              title: Text('Acasă'),
              onTap: () => Navigator.pushReplacementNamed(context, '/'),
            ),
            ListTile(
              title: Text('Servicii'),
              onTap: () => Navigator.pushReplacementNamed(context, '/services'),
            ),
            ListTile(
              title: Text('Galerie'),
              onTap: () => Navigator.pushReplacementNamed(context, '/gallery'),
            ),
            ListTile(
              title: Text('Contact'),
              onTap: () => Navigator.pushReplacementNamed(context, '/contact'),
            ),
          ],
        ),
      ),
      body: Center(
        child: Text('Bine ați venit la Gold Events!', style: TextStyle(fontSize: 28)),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.amber,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('© 2025 Gold Events', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
