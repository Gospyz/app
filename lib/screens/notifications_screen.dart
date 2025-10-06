import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_drawer.dart';

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(currentRoute: 'notifications'),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.white),
            SizedBox(width: 8),
            Text('Notificări administrare tratamente/medicamente'),
          ],
        ),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // LISTĂ NOTIFICĂRI
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('treatments').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                  final treatments = snapshot.data!.docs;
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('medications').snapshots(),
                    builder: (context, medsSnapshot) {
                      if (!medsSnapshot.hasData) return SizedBox();
                      final meds = medsSnapshot.data!.docs;
                      final List<Widget> notifications = [];
                      // Notificări tratamente
                      for (final doc in treatments) {
                        final data = doc.data() as Map<String, dynamic>;
                        notifications.add(Card(
                          color: Colors.orange[50],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            leading: Icon(Icons.medical_services, color: Colors.orange),
                            title: Text("Tratament: ${data['type'] ?? ''}", style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Rezident: ${data['residentName'] ?? ''} | Data: ${data['date'] ?? ''} Ora: ${data['time'] ?? ''}"),
                            trailing: data['administered'] == true ? Icon(Icons.check, color: Colors.green) : null,
                          ),
                        ));
                      }
                      // Notificări medicamente
                      for (final doc in meds) {
                        final data = doc.data() as Map<String, dynamic>;
                        notifications.add(Card(
                          color: Colors.green[50],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            leading: Icon(Icons.medication, color: Colors.green),
                            title: Text("Medicament: ${data['name'] ?? ''}", style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Rezident: ${data['residentName'] ?? ''} | Orar: ${data['schedule'] ?? ''}"),
                          ),
                        ));
                      }
                      if (notifications.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off, color: Colors.grey, size: 64),
                              SizedBox(height: 16),
                              Text('Nu există notificări.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                            ],
                          ),
                        );
                      }
                      return ListView(
                        children: notifications,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
