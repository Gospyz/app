import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';
import 'residents_screen.dart';
import 'calendar_screen.dart';
import 'appointments_screen.dart';
import 'treatments_admin_screen.dart';
import 'notifications_screen.dart';
import 'family_communication_screen.dart';
import 'user_settings_screen.dart';
import 'app_drawer.dart';

import 'resident_profile_screen.dart';
import '../widgets/announcement_popup.dart';

class DashboardScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return null;
      }
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) {
        // Creează un document implicit pentru utilizator dacă nu există
        final defaultData = {
          'email': user.email,
          'role': 'staff',
          'createdAt': DateTime.now().toIso8601String(),
        };
        await _firestore.collection('users').doc(user.uid).set(defaultData);
        return defaultData;
      }
      
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  Future<int> getTotalResidents() async {
    final snapshot = await _firestore.collection('residents').where('status', isNotEqualTo: 'externat').get();
    return snapshot.docs.where((doc) => (doc.data() as Map<String, dynamic>)['status'] != 'externat').length;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<Map<String, dynamic>?>(
          future: getCurrentUserData(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (!userSnapshot.hasData || userSnapshot.data == null) {
              return Scaffold(body: Center(child: Text('Eroare la încărcarea datelor utilizatorului.')));
            }
            final userData = userSnapshot.data;
            final isFamily = userData != null && userData['role'] == 'family';
            if (isFamily) {
              final patientId = userData['patientId'];
              return Scaffold(
                drawer: AppDrawer(currentRoute: 'profile', isFamily: true, patientId: patientId),
                appBar: AppBar(
                  title: Row(
                    children: [
                      Icon(Icons.person, color: Colors.white),
                      SizedBox(width: 8),
                      Text("Profil pacient asociat"),
                    ],
                  ),
                  backgroundColor: Colors.teal,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.logout),
                      tooltip: 'Deconectare',
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                        );
                      },
                    )
                  ],
                ),
                body: ResidentProfileScreen(residentId: patientId, readOnly: true),
              );
            }
            // Dashboard pentru staff
            final today = DateTime.now();
            final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
            return Scaffold(
              drawer: AppDrawer(currentRoute: 'dashboard'),
              appBar: AppBar(
                title: Row(
                  children: [
                    Icon(Icons.home, color: Colors.white),
                    SizedBox(width: 8),
                    Text("Dashboard"),
                  ],
                ),
                backgroundColor: Colors.teal,
                actions: [
                  IconButton(
                    icon: Icon(Icons.logout),
                    tooltip: 'Deconectare',
                    onPressed: () => logout(context),
                  )
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    // HEADER MODERNIZAT
                    Card(
                      color: Colors.teal[50],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 6,
                      margin: EdgeInsets.only(bottom: 18),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.teal[300],
                              child: Icon(Icons.emoji_people, color: Colors.white, size: 40),
                              radius: 36,
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Bine ai venit!",
                                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal[900]),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Accesează rapid funcțiile importante ale centrului.",
                                    style: TextStyle(fontSize: 16, color: Colors.teal[800]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                // BADGE MESAJ NOU
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('family_messages')
                      .where('seenByStaff', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return SizedBox.shrink();
                    final count = snapshot.data!.docs.length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_unread, color: Colors.purple, size: 24),
                          SizedBox(width: 6),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text('$count mesaje noi de la familie', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // TOTAL REZIDENȚI
                FutureBuilder<int>(
                  future: getTotalResidents(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 4,
                      margin: EdgeInsets.only(bottom: 18),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal[200],
                          child: Icon(Icons.people, color: Colors.teal[900], size: 28),
                        ),
                        title: Text("Rezidenți internați", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Numărul total de rezidenți activi în centru."),
                        trailing: AnimatedSwitcher(
                          duration: Duration(milliseconds: 500),
                          child: Text(
                            "${snapshot.data}",
                            key: ValueKey(snapshot.data),
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal[800]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // ALERTE TRATAMENTE/MEDICAMENTE
                Text("Alerte tratamente și medicamente", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[900])),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('alerts').where('seen', isEqualTo: false).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                    final alerts = snapshot.data!.docs;
                    if (alerts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 28),
                            SizedBox(width: 8),
                            Text("Nu există alerte noi.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: alerts.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Card(
                          color: Colors.orange[50],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange[200],
                              child: Icon(
                                data['type'] == 'medicament' ? Icons.medication : Icons.medical_services,
                                color: Colors.orange[900],
                              ),
                            ),
                            title: Text(data['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(data['subtitle'] ?? ''),
                            trailing: IconButton(
                              icon: Icon(Icons.visibility, color: Colors.teal),
                              tooltip: 'Marchează ca văzut',
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('alerts').doc(doc.id).update({'seen': true});
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                SizedBox(height: 20),
                // PROGRAMĂRI DE AZI
                Text("Programări de azi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('appointments')
                      .where('date', isEqualTo: todayStr)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.event_available, color: Colors.green, size: 28),
                            SizedBox(width: 8),
                            Text("Nu există programări pentru azi.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Card(
                          color: Colors.blue[50],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[200],
                              child: Icon(Icons.medical_services, color: Colors.blue[900]),
                            ),
                            title: Text(data['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Rezident: "+(data['residentName'] ?? '')), 
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                SizedBox(height: 20),
                // MESAJ NOU DE LA FAMILIE
                Text("Mesaje noi de la familie", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple[900])),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('family_messages')
                      .where('seenByStaff', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;
                    final newMsgCount = docs.length;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (newMsgCount > 0)
                          Row(
                            children: [
                              Icon(Icons.mark_email_unread, color: Colors.purple, size: 24),
                              SizedBox(width: 6),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text('$newMsgCount mesaje noi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        if (newMsgCount == 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Icon(Icons.mark_email_read, color: Colors.green, size: 28),
                                SizedBox(width: 8),
                                Text("Nu există mesaje noi de la familie.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                              ],
                            ),
                          ),
                        ...docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return Card(
                            color: Colors.purple[50],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.purple[200],
                                child: Icon(Icons.mark_email_unread, color: Colors.purple[900]),
                              ),
                              title: Text(data['message'] ?? '[Atașament]', style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("Rezident: "+(data['residentName'] ?? '')), 
                              trailing: IconButton(
                                icon: Icon(Icons.visibility, color: Colors.teal),
                                tooltip: 'Marchează ca văzut',
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('family_messages').doc(doc.id).update({'seenByStaff': true});
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
          },
        ),
        AnnouncementPopup(),
      ],
    );
  }
}
