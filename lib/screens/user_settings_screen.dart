import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_role.dart';
import 'app_drawer.dart';
import '../services/settings_service.dart';
import '../services/firestore_settings_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';

class UserSettingsScreen extends StatefulWidget {
  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  // Controllers and variables for mass messaging
  final TextEditingController _massMsgSubjectCtrl = TextEditingController();
  final TextEditingController _massMsgBodyCtrl = TextEditingController();
  bool _massMsgEmail = true;
  bool _massMsgPush = false;
  bool _massMsgSms = false;

  // Controllers and variables for announcements
  final TextEditingController _announcementTitleCtrl = TextEditingController();
  final TextEditingController _announcementBodyCtrl = TextEditingController();
  bool _announcementHomepage = false;

  // Controllers and variables for auto notifications
  final TextEditingController _autoNotifTitleCtrl = TextEditingController();
  final TextEditingController _autoNotifBodyCtrl = TextEditingController();
  DateTime? _autoNotifDate;
final SettingsService _settingsService = SettingsService();
final FirestoreSettingsService _firestoreSettings = FirestoreSettingsService();

  // State pentru secțiuni
  String _locationName = '';
  String _locationAddress = '';
  String _locationAdmin = '';
  bool _notifEmail = true;
  bool _notifPush = true;
  bool _notifSms = false;
  bool _darkMode = false;
  String _language = 'RO';
  
  // Preferințe notificări aparținători
  bool _notifyMedicalAppointments = true;
  bool _notifyMedications = true;
  bool _notifyActivities = true;
  bool _notifyDailyUpdates = true;
  bool _notifyWeeklyUpdates = false;


  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notification_preferences')
          .doc('settings')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _notifyMedicalAppointments = data['medicalAppointments'] ?? true;
          _notifyMedications = data['medications'] ?? true;
          _notifyActivities = data['activities'] ?? true;
          _notifyDailyUpdates = data['dailyUpdates'] ?? true;
          _notifyWeeklyUpdates = data['weeklyUpdates'] ?? false;
        });
      }
    }
  }

  Future<void> _saveNotificationPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notification_preferences')
          .doc('settings')
          .set({
        'medicalAppointments': _notifyMedicalAppointments,
        'medications': _notifyMedications,
        'activities': _notifyActivities,
        'dailyUpdates': _notifyDailyUpdates,
        'weeklyUpdates': _notifyWeeklyUpdates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preferințele au fost salvate!')),
      );
    }
  }

  Future<void> _loadSettings() async {
    // Încarcă din Firestore, apoi salvează local
    final loc = await _firestoreSettings.getLocationInfo();
    final notif = await _firestoreSettings.getNotifPrefs();
    final dark = await _firestoreSettings.getThemeMode();
    final lang = await _firestoreSettings.getLanguage();
    await _settingsService.saveLocationInfo(loc['name']!, loc['address']!, loc['admin']!);
    await _settingsService.saveNotifPrefs(notif['email']!, notif['push']!, notif['sms']!);
    await _settingsService.saveThemeMode(dark);
    await _settingsService.saveLanguage(lang);
    setState(() {
      _locationName = loc['name'] ?? '';
      _locationAddress = loc['address'] ?? '';
      _locationAdmin = loc['admin'] ?? '';
      _notifEmail = notif['email'] ?? true;
      _notifPush = notif['push'] ?? true;
      _notifSms = notif['sms'] ?? false;
      _darkMode = dark;
      _language = lang;
    });
  }

  Future<void> _editLocationDialog() async {
    final nameCtrl = TextEditingController(text: _locationName);
    final addrCtrl = TextEditingController(text: _locationAddress);
    final adminCtrl = TextEditingController(text: _locationAdmin);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editează informații locație'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Nume complex/clădire')),
            TextField(controller: addrCtrl, decoration: InputDecoration(labelText: 'Adresă completă')),
            TextField(controller: adminCtrl, decoration: InputDecoration(labelText: 'Administrator/responsabil')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Anulează')),
          ElevatedButton(
            onPressed: () async {
              await _firestoreSettings.saveLocationInfo(nameCtrl.text, addrCtrl.text, adminCtrl.text);
              await _settingsService.saveLocationInfo(nameCtrl.text, addrCtrl.text, adminCtrl.text);
              setState(() {
                _locationName = nameCtrl.text;
                _locationAddress = addrCtrl.text;
                _locationAdmin = adminCtrl.text;
              });
              Navigator.pop(context);
            },
            child: Text('Salvează'),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final _formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    UserRole selectedRole = UserRole.staff;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Adaugă utilizator nou'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                  validator: (v) => v == null || v.isEmpty ? 'Completează emailul' : null,
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: 'Parolă', prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6 ? 'Minim 6 caractere' : null,
                ),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  decoration: InputDecoration(labelText: 'Rol', prefixIcon: Icon(Icons.person)),
                  items: UserRole.values.map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(userRoleToString(role)),
                  )).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedRole = val!;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Anulează')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );
                  await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
                    'email': emailController.text.trim(),
                    'role': userRoleToString(selectedRole),
                  });
                  Navigator.pop(context);
                  setState(() {});
                  if (userRoleToString(selectedRole) == 'Aparținător') {
                    _showFamilyDataDialog(cred.user!.uid);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Utilizator adăugat!')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Eroare: $e')),
                  );
                }
              }
            },
            child: Text('Salvează'),
          ),
        ],
      ),
    );
  }

  void _showFamilyDataDialog(String userId) {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();
    final cnpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Date personale aparținător'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Nume și prenume'),
                  validator: (v) => v == null || v.isEmpty ? 'Completează numele' : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Telefon'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Completează telefonul' : null,
                ),
                TextFormField(
                  controller: relationController,
                  decoration: InputDecoration(labelText: 'Rudă cu rezidentul (ex: fiu, fiică, soț)'),
                  validator: (v) => v == null || v.isEmpty ? 'Completează relația' : null,
                ),
                TextFormField(
                  controller: cnpController,
                  decoration: InputDecoration(labelText: 'CNP'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Completează CNP' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                // Salvează datele în Firestore la secțiunea Date Apartinator
                await FirebaseFirestore.instance.collection('users').doc(userId).collection('date_apartinator').doc('info').set({
                  'nume': nameController.text.trim(),
                  'telefon': phoneController.text.trim(),
                  'relatie': relationController.text.trim(),
                  'cnp': cnpController.text.trim(),
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Datele aparținătorului au fost salvate!')),
                );
              }
            },
            child: Text('Salvează'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(String userId, Map<String, dynamic> data) {
    final _formKey = GlobalKey<FormState>();
    final emailController = TextEditingController(text: data['email']);
    UserRole selectedRole = stringToUserRole(data['role'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Editează utilizator'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                  validator: (v) => v == null || v.isEmpty ? 'Completează emailul' : null,
                ),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  decoration: InputDecoration(labelText: 'Rol', prefixIcon: Icon(Icons.person)),
                  items: UserRole.values.map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(userRoleToString(role)),
                  )).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedRole = val!;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Anulează')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await FirebaseFirestore.instance.collection('users').doc(userId).update({
                  'email': emailController.text.trim(),
                  'role': userRoleToString(selectedRole),
                });
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Utilizator actualizat!')),
                );
              }
            },
            child: Text('Salvează'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email de resetare trimis!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare: $e')),
      );
    }
  }

  Future<void> _deleteUser(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).delete();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Utilizator șters!')),
    );
  }

  void _toggleBlockUser(String userId, bool currentBlocked) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'blocked': !currentBlocked,
    });
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(!currentBlocked ? 'Cont blocat!' : 'Cont deblocat!')),
    );
  }

  void _showSetPasswordDialog(String userId, String email) {
    final _formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Setează parolă nouă'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: passwordController,
            decoration: InputDecoration(labelText: 'Parolă nouă', prefixIcon: Icon(Icons.lock)),
            obscureText: true,
            validator: (v) => v == null || v.length < 6 ? 'Minim 6 caractere' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Anulează')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  // Schimbă parola efectiv în Firebase Auth
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Email de resetare parolă trimis către $email!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Eroare: $e')),
                  );
                }
              }
            },
            child: Text('Salvează'),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(Map<String, dynamic> data) {
    final _formKey = GlobalKey<FormState>();
    final emailController = TextEditingController(text: data['email']);
    UserRole selectedRole = stringToUserRole(data['role'] ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Profilul meu'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                  readOnly: true,
                ),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  decoration: InputDecoration(labelText: 'Rol', prefixIcon: Icon(Icons.person)),
                  items: UserRole.values.map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(userRoleToString(role)),
                  )).toList(),
                  onChanged: null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Închide')),
        ],
      ),
    );
  }

  String userSearch = '';

  @override
  Widget build(BuildContext context) {
    final isFamily = FirebaseAuth.instance.currentUser?.email?.contains('family.com') ?? false;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: AppDrawer(currentRoute: 'settings'),
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.settings, color: Colors.white),
              SizedBox(width: 8),
              Text('Setări și utilizatori'),
            ],
          ),
          backgroundColor: Colors.teal,
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.settings), text: 'Setări'),
              Tab(icon: Icon(Icons.people), text: 'Utilizatori'),
            ],
          ),
          actions: [
            if (!isFamily)
              IconButton(
                icon: Icon(Icons.person_add),
                tooltip: 'Adaugă utilizator',
                onPressed: _showAddUserDialog,
              ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Setări generale
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // Card Mesaje în masă
                  Card(
                    color: Colors.blue[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      leading: Icon(Icons.message, color: Colors.blue[800]),
                      title: Text('Mesaje în masă', style: TextStyle(fontWeight: FontWeight.bold)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              TextField(
                                decoration: InputDecoration(labelText: 'Subiect mesaj'),
                                controller: _massMsgSubjectCtrl,
                              ),
                              TextField(
                                decoration: InputDecoration(labelText: 'Conținut mesaj'),
                                controller: _massMsgBodyCtrl,
                                maxLines: 3,
                              ),
                              Row(
                                children: [
                                  Checkbox(value: _massMsgEmail, onChanged: (v) => setState(() => _massMsgEmail = v ?? true)),
                                  Text('Email'),
                                  SizedBox(width: 16),
                                  Checkbox(value: _massMsgPush, onChanged: (v) => setState(() => _massMsgPush = v ?? false)),
                                  Text('Notificare push'),
                                  SizedBox(width: 16),
                                  Checkbox(value: _massMsgSms, onChanged: (v) => setState(() => _massMsgSms = v ?? false)),
                                  Text('SMS'),
                                ],
                              ),
                              ElevatedButton.icon(
                                icon: Icon(Icons.send),
                                label: Text('Trimite mesaj'),
                                onPressed: _sendMassMessage,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Card Informații locație
                  Card(
                    color: Colors.teal[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      leading: Icon(Icons.location_city, color: Colors.teal[800]),
                      title: Text('Informații despre locație', style: TextStyle(fontWeight: FontWeight.bold)),
                      children: [
                        ListTile(
                          title: Text('Numele complexului / clădirii'),
                          subtitle: Text(_locationName.isEmpty ? 'Nesetat' : _locationName),
                          trailing: Icon(Icons.edit),
                          onTap: _editLocationDialog,
                        ),
                        ListTile(
                          title: Text('Adresă completă'),
                          subtitle: Text(_locationAddress.isEmpty ? 'Nesetat' : _locationAddress),
                          trailing: Icon(Icons.edit),
                          onTap: _editLocationDialog,
                        ),
                        ListTile(
                          title: Text('Administrator / responsabil'),
                          subtitle: Text(_locationAdmin.isEmpty ? 'Nesetat' : _locationAdmin),
                          trailing: Icon(Icons.edit),
                          onTap: _editLocationDialog,
                        ),
                      ],
                    ),
                  ),
                  // Card Creare anunțuri
                  Card(
                    color: Colors.green[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      leading: Icon(Icons.announcement, color: Colors.green[800]),
                      title: Text('Creare anunțuri', style: TextStyle(fontWeight: FontWeight.bold)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              TextField(
                                decoration: InputDecoration(labelText: 'Titlu anunț'),
                                controller: _announcementTitleCtrl,
                              ),
                              TextField(
                                decoration: InputDecoration(labelText: 'Conținut anunț'),
                                controller: _announcementBodyCtrl,
                                maxLines: 3,
                              ),
                              Row(
                                children: [
                                  Checkbox(value: _announcementHomepage, onChanged: (v) => setState(() => _announcementHomepage = v ?? false)),
                                  Text('Afișează pe homepage'),
                                ],
                              ),
                              ElevatedButton.icon(
                                icon: Icon(Icons.add),
                                label: Text('Creează anunț'),
                                onPressed: _createAnnouncement,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Card Programare notificări automate
                  // Card Preferințe notificări aparținători
                  Card(
                    color: Colors.purple[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      leading: Icon(Icons.notifications_active, color: Colors.purple[800]),
                      title: Text('Preferințe notificări aparținători', style: TextStyle(fontWeight: FontWeight.bold)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Selectează tipurile de notificări pe care dorești să le primești:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              SizedBox(height: 16),
                              CheckboxListTile(
                                title: Text('Programări medicale'),
                                subtitle: Text('Consultații, analize, tratamente'),
                                value: _notifyMedicalAppointments,
                                onChanged: (value) => setState(() => _notifyMedicalAppointments = value ?? true),
                              ),
                              CheckboxListTile(
                                title: Text('Administrare medicamente'),
                                subtitle: Text('Medicamente administrate, modificări în schema de tratament'),
                                value: _notifyMedications,
                                onChanged: (value) => setState(() => _notifyMedications = value ?? true),
                              ),
                              CheckboxListTile(
                                title: Text('Activități și evenimente'),
                                subtitle: Text('Participare la activități sociale, terapii, etc.'),
                                value: _notifyActivities,
                                onChanged: (value) => setState(() => _notifyActivities = value ?? true),
                              ),
                              Divider(),
                              Text('Frecvența actualizărilor generale:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              SizedBox(height: 8),
                              CheckboxListTile(
                                title: Text('Actualizări zilnice'),
                                subtitle: Text('Primești un rezumat la sfârșitul fiecărei zile'),
                                value: _notifyDailyUpdates,
                                onChanged: (value) {
                                  setState(() {
                                    _notifyDailyUpdates = value ?? true;
                                    if (value == true) {
                                      _notifyWeeklyUpdates = false;
                                    }
                                  });
                                },
                              ),
                              CheckboxListTile(
                                title: Text('Actualizări săptămânale'),
                                subtitle: Text('Primești un rezumat la sfârșitul fiecărei săptămâni'),
                                value: _notifyWeeklyUpdates,
                                onChanged: (value) {
                                  setState(() {
                                    _notifyWeeklyUpdates = value ?? false;
                                    if (value == true) {
                                      _notifyDailyUpdates = false;
                                    }
                                  });
                                },
                              ),
                              SizedBox(height: 16),
                              Center(
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.save),
                                  label: Text('Salvează preferințele'),
                                  onPressed: _saveNotificationPreferences,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple[700],
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Card(
                    color: Colors.red[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      leading: Icon(Icons.schedule, color: Colors.red[800]),
                      title: Text('Programare notificări automate', style: TextStyle(fontWeight: FontWeight.bold)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              TextField(
                                decoration: InputDecoration(labelText: 'Titlu notificare'),
                                controller: _autoNotifTitleCtrl,
                              ),
                              TextField(
                                decoration: InputDecoration(labelText: 'Conținut notificare'),
                                controller: _autoNotifBodyCtrl,
                                maxLines: 2,
                              ),
                              Row(
                                children: [
                                  Text('Data și ora: '),
                                  TextButton(
                                    child: Text(_autoNotifDate == null ? 'Selectează' : _autoNotifDate.toString()),
                                    onPressed: _pickAutoNotifDate,
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                icon: Icon(Icons.schedule_send),
                                label: Text('Programează notificare'),
                                onPressed: _scheduleAutoNotification,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tab 2: Utilizatori
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Caută utilizator',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) {
                            setState(() {
                              userSearch = val.toLowerCase();
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.account_circle, color: Colors.teal),
                        tooltip: 'Profilul meu',
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                            if (doc.exists) _showProfileDialog(doc.data()!);
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text('Utilizatori', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return Text('Eroare la încărcare: ${snapshot.error}');
                        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                        final docs = snapshot.data!.docs;
                        final familyUsers = docs.where((doc) => (doc.data() as Map<String, dynamic>)['role'] == 'family').toList();
                        final otherUsers = docs.where((doc) => (doc.data() as Map<String, dynamic>)['role'] != 'family').toList();
                        if (docs.isEmpty) return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.group_off, color: Colors.grey, size: 64),
                              SizedBox(height: 16),
                              Text('Nu există utilizatori.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                            ],
                          ),
                        );
                        return ListView(
                          children: [
                            if (familyUsers.isNotEmpty) ...[
                              Text('Conturi familie/aparținător', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                              ...familyUsers.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final blocked = data['blocked'] == true;
                                return Card(
                                  margin: EdgeInsets.symmetric(vertical: 4),
                                  color: Colors.teal[50],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  child: ListTile(
                                    leading: Icon(Icons.family_restroom, color: blocked ? Colors.grey : Colors.teal[700]),
                                    title: Text(data['email'] ?? '', style: TextStyle(decoration: blocked ? TextDecoration.lineThrough : null)),
                                    subtitle: Text('Pacient asociat: ${data['patientId'] ?? '-'}${blocked ? ' (blocat)' : ''}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(blocked ? Icons.lock_open : Icons.lock, color: Colors.purple),
                                          tooltip: blocked ? 'Deblochează cont' : 'Blochează cont',
                                          onPressed: () => _toggleBlockUser(doc.id, blocked),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red),
                                          tooltip: 'Șterge',
                                          onPressed: () => _deleteUser(doc.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                              SizedBox(height: 18),
                            ],
                            if (otherUsers.isNotEmpty) ...[
                              Text(
                                'Personal & administratori',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              ),
                              ...otherUsers.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final blocked = data['blocked'] == true;
                                return Card(
                                  margin: EdgeInsets.symmetric(vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  child: ListTile(
                                    leading: Icon(Icons.person, color: blocked ? Colors.grey : Colors.teal),
                                    title: Text(
                                      data['email'] ?? '',
                                      style: TextStyle(
                                        decoration: blocked ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    subtitle: Text('Rol: ${data['role'] ?? ''}${blocked ? ' (blocat)' : ''}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(blocked ? Icons.lock_open : Icons.lock, color: Colors.purple),
                                          tooltip: blocked ? 'Deblochează cont' : 'Blochează cont',
                                          onPressed: () => _toggleBlockUser(doc.id, blocked),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.edit, color: Colors.orange),
                                          tooltip: 'Editează',
                                          onPressed: () => _showEditUserDialog(doc.id, data),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.lock_reset, color: Colors.blue),
                                          tooltip: 'Resetează parolă (email)',
                                          onPressed: () => _resetPassword(data['email'] ?? ''),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.password, color: Colors.indigo),
                                          tooltip: 'Setează parolă nouă (admin)',
                                          onPressed: () => _showSetPasswordDialog(doc.id, data['email'] ?? ''),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red),
                                          tooltip: 'Șterge',
                                          onPressed: () => _deleteUser(doc.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMassMessage() async {
    await FirebaseFirestore.instance.collection('mass_messages').add({
      'subject': _massMsgSubjectCtrl.text,
      'body': _massMsgBodyCtrl.text,
      'email': _massMsgEmail,
      'push': _massMsgPush,
      'sms': _massMsgSms,
      'createdAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mesaj trimis către backend!')));
    _massMsgSubjectCtrl.clear();
    _massMsgBodyCtrl.clear();
    setState(() {
      _massMsgEmail = true;
      _massMsgPush = false;
      _massMsgSms = false;
    });
  }

  Future<void> _createAnnouncement() async {
    await FirebaseFirestore.instance.collection('announcements').add({
      'title': _announcementTitleCtrl.text,
      'body': _announcementBodyCtrl.text,
      'homepage': _announcementHomepage,
      'createdAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Anunț creat!')));
    _announcementTitleCtrl.clear();
    _announcementBodyCtrl.clear();
    setState(() {
      _announcementHomepage = false;
    });
  }

  Future<void> _scheduleAutoNotification() async {
    if (_autoNotifDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selectează data și ora!')));
      return;
    }
    await FirebaseFirestore.instance.collection('scheduled_notifications').add({
      'title': _autoNotifTitleCtrl.text,
      'body': _autoNotifBodyCtrl.text,
      'scheduledAt': _autoNotifDate,
      'createdAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Notificare programată!')));
    _autoNotifTitleCtrl.clear();
    _autoNotifBodyCtrl.clear();
    setState(() {
      _autoNotifDate = null;
    });
  }

  Future<void> _pickAutoNotifDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _autoNotifDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }
}
