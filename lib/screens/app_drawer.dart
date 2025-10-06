import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'residents_screen.dart';
import 'calendar_screen.dart';
import 'appointments_screen.dart';
import 'treatments_admin_screen.dart';
import 'notifications_screen.dart';
import 'family_communication_screen.dart';
import 'user_settings_screen.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'resident_profile_screen.dart';

class AppDrawer extends StatelessWidget {
  final String? currentRoute;
  final bool isFamily;
  final String? patientId;
  const AppDrawer({Key? key, this.currentRoute, this.isFamily = false, this.patientId}) : super(key: key);

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isFamily && patientId != null) {
      return Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.account_circle, color: Colors.white, size: 48),
                  SizedBox(height: 8),
                  Text('Cont familie', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profil pacient'),
              selected: currentRoute == 'profile',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResidentProfileScreen(
                      residentId: patientId!,
                      readOnly: true,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_month),
              title: Text('Calendar activități'),
              selected: currentRoute == 'calendar',
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CalendarScreen(residentId: patientId!)));
              },
            ),
            ListTile(
              leading: Icon(Icons.medical_services),
              title: Text('Programări la medic'),
              selected: currentRoute == 'appointments',
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AppointmentsScreen(residentId: patientId!)));
              },
            ),
            ListTile(
              leading: Icon(Icons.assignment_turned_in),
              title: Text('Administrare tratamente'),
              selected: currentRoute == 'treatments',
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TreatmentsAdminScreen(residentId: patientId!)));
              },
            ),
            ListTile(
              leading: Icon(Icons.phone),
              title: Text('Comunicare familie'),
              selected: currentRoute == 'family',
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => FamilyCommunicationScreen(residentId: patientId!)));
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Deconectare', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
              },
            ),
          ],
        ),
      );
    }
    // Staff/admin drawer
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.account_circle, color: Colors.white, size: 48),
                SizedBox(height: 8),
                Text('Meniu', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            selected: currentRoute == 'dashboard',
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Rezidenți'),
            selected: currentRoute == 'residents',
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResidentsScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.calendar_month),
            title: Text('Calendar activități'),
            selected: currentRoute == 'calendar',
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CalendarScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.medical_services),
            title: Text('Programări la medic'),
            selected: currentRoute == 'appointments',
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AppointmentsScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.assignment_turned_in),
            title: Text('Administrare tratamente'),
            selected: currentRoute == 'treatments',
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TreatmentsAdminScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications_active),
            title: Text('Notificări tratamente'),
            selected: currentRoute == 'notifications',
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => NotificationsScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.phone),
            title: Text('Comunicare familie'),
            selected: currentRoute == 'family',
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => FamilyCommunicationScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Setări & utilizatori'),
            selected: currentRoute == 'settings',
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UserSettingsScreen()));
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Deconectare', style: TextStyle(color: Colors.red)),
            onTap: () => logout(context),
          ),
        ],
      ),
    );
  }
}
