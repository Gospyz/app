import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'resident_medications_screen.dart';
import 'appointments_screen.dart';
import 'app_drawer.dart';
import 'package:flutter/services.dart';

class ResidentProfileScreen extends StatefulWidget {
  final String residentId;
  final bool? readOnly;
  const ResidentProfileScreen({Key? key, required this.residentId, this.readOnly}) : super(key: key);

  @override
  _ResidentProfileScreenState createState() => _ResidentProfileScreenState();
}

class _ResidentProfileScreenState extends State<ResidentProfileScreen> {
  bool isLoading = true;
  DocumentSnapshot? residentSnapshot;
  List<bool> expandedPanels = List.generate(6, (i) => false);
  Map<String, dynamic> get data => residentSnapshot?.data() as Map<String, dynamic>? ?? {};
  String? get profilePhotoUrl => data['profilePhotoUrl'];

  Future<void> dischargeResident() async {
    final now = DateTime.now();
    await FirebaseFirestore.instance
        .collection('residents')
        .doc(widget.residentId)
        .update({
      'status': 'externat',
      'dischargeDate': now.toIso8601String(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Rezidentul a fost externat.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    fetchResident();
    if (isLoading) return Scaffold(body: Center(child: CircularProgressIndicator()));
    final data = residentSnapshot?.data() as Map<String, dynamic>? ?? {};
    List<bool> expandedPanels = List.generate(6, (i) => false);
    String? profilePhotoUrl = data['profilePhotoUrl'];

    return Scaffold(
      drawer: (widget.readOnly ?? false) && (widget.residentId != null)
          ? AppDrawer(currentRoute: 'profile', isFamily: true, patientId: widget.residentId)
          : AppDrawer(currentRoute: 'profile'),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.person, color: Colors.white),
            SizedBox(width: 8),
            Text("Profil Rezident", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: ExpansionPanelList(
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                expandedPanels[index] = !isExpanded;
              });
            },
            children: [
              // 1. Date personale extinse
              ExpansionPanel(
                headerBuilder: (context, isExpanded) => ListTile(
                  leading: Icon(Icons.info, color: Colors.teal),
                  title: Text('Date personale'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.teal),
                        onPressed: () {
                          showEditDialog(data);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.camera_alt, color: Colors.teal),
                        onPressed: () {
                          showProfilePhotoDialog();
                        },
                      ),
                    ],
                  ),
                ),
                body: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(title: Text('Nume complet'), subtitle: Text(data['name'] ?? '')),
                      ListTile(title: Text('Data nașterii'), subtitle: Text(data['birthdate'] ?? '')),
                      profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
                          ? ListTile(
                              title: Text('Poză de profil'),
                              subtitle: Image.network(profilePhotoUrl, height: 80),
                            )
                          : ListTile(title: Text('Poză de profil'), subtitle: Text('Nu există poză încărcată')),
                      ListTile(title: Text('CNP (criptat)'), subtitle: Text(data['cnp'] ?? '')),
                      ListTile(title: Text('Cod intern/familie'), subtitle: Text(data['internalCode'] ?? '')),
                      ListTile(title: Text('Status juridic'), subtitle: Text(data['legalStatus'] ?? '')),
                    ],
                  ),
                ),
                isExpanded: expandedPanels[0],
              ),
              // 2. Contacte importante
              ExpansionPanel(
                headerBuilder: (context, isExpanded) => ListTile(
                  leading: Icon(Icons.contact_phone, color: Colors.blue),
                  title: Text('Contacte importante'),
                  trailing: IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      showEditContactsDialog(data);
                    },
                  ),
                ),
                body: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(title: Text('Persoană de contact principală'), subtitle: Text(data['mainContactName'] ?? '')),
                      ListTile(title: Text('Relație'), subtitle: Text(data['mainContactRelation'] ?? '')),
                      ListTile(title: Text('Telefon'), subtitle: Text(data['mainContactPhone'] ?? '')),
                      ListTile(title: Text('Email'), subtitle: Text(data['mainContactEmail'] ?? '')),
                      ListTile(title: Text('Persoană de rezervă'), subtitle: Text(data['backupContactName'] ?? '')),
                      ListTile(title: Text('Medicul de familie'), subtitle: Text(data['familyDoctor'] ?? '')),
                    ],
                  ),
                ),
                isExpanded: expandedPanels[1],
              ),
              // 3. Informații medicale detaliate
              ExpansionPanel(
                headerBuilder: (context, isExpanded) => ListTile(
                  leading: Icon(Icons.medical_services, color: Colors.red),
                  title: Text('Informații medicale'),
                  trailing: IconButton(
                    icon: Icon(Icons.edit, color: Colors.red),
                    onPressed: () {
                      showEditMedicalDialog(data);
                    },
                  ),
                ),
                body: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(title: Text('Grupa sanguină'), subtitle: Text(data['bloodType'] ?? '')),
                      ListTile(title: Text('Alergii'), subtitle: Text(data['allergies'] ?? '')),
                      ListTile(title: Text('Diagnostic(e) principale'), subtitle: Text(data['diagnosis'] ?? '')),
                      ListTile(title: Text('Tratament curent'), subtitle: Text(data['medication'] ?? '')),
                      ListTile(title: Text('Orar tratament'), subtitle: Text(data['medicationSchedule'] ?? '')),
                      ListTile(title: Text('Istoric medical'), subtitle: Text(data['medicalHistory'] ?? '')),
                      ListTile(title: Text('Mobilitate'), subtitle: Text(data['mobility'] ?? '')),
                      ListTile(title: Text('Dietă specială'), subtitle: Text(data['diet'] ?? '')),
                    ],
                  ),
                ),
                isExpanded: expandedPanels[2],
              ),
              // 4. Stare emoțională / cognitivă
              ExpansionPanel(
                headerBuilder: (context, isExpanded) => ListTile(
                  leading: Icon(Icons.psychology, color: Colors.purple),
                  title: Text('Stare emoțională / cognitivă'),
                  trailing: IconButton(
                    icon: Icon(Icons.edit, color: Colors.purple),
                    onPressed: () {
                      showEditEmotionalDialog(data);
                    },
                  ),
                ),
                body: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(title: Text('Nivel de orientare'), subtitle: Text(data['orientation'] ?? '')),
                      ListTile(title: Text('Tulburări cognitive'), subtitle: Text(data['cognitiveIssues'] ?? '')),
                      ListTile(title: Text('Observații psihologice'), subtitle: Text(data['psychologicalNotes'] ?? '')),
                    ],
                  ),
                ),
                isExpanded: expandedPanels[3],
              ),
              // 5. Activități și preferințe
              ExpansionPanel(
                headerBuilder: (context, isExpanded) => ListTile(
                  leading: Icon(Icons.sports_handball, color: Colors.green),
                  title: Text('Activități și preferințe'),
                  trailing: IconButton(
                    icon: Icon(Icons.edit, color: Colors.green),
                    onPressed: () {
                      showEditPreferencesDialog(data);
                    },
                  ),
                ),
                body: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(title: Text('Hobby-uri'), subtitle: Text(data['hobbies'] ?? '')),
                      ListTile(title: Text('Activități preferate'), subtitle: Text(data['favoriteActivities'] ?? '')),
                      ListTile(title: Text('Participare la evenimente'), subtitle: Text(data['eventParticipation'] ?? '')),
                      ListTile(title: Text('Preferințe alimentare'), subtitle: Text(data['foodPreferences'] ?? '')),
                    ],
                  ),
                ),
                isExpanded: expandedPanels[4],
              ),
              // 6. Fișiere și documente
              ExpansionPanel(
                headerBuilder: (context, isExpanded) => ListTile(
                  leading: Icon(Icons.folder, color: Colors.orange),
                  title: Text('Fișiere și documente'),
                ),
                body: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(title: Text('Contract de internare'), subtitle: Text(data['contractFile'] ?? '')),
                      ListTile(title: Text('Buletin / CI scanat'), subtitle: Text(data['idFile'] ?? '')),
                      ListTile(title: Text('Rețete medicale'), subtitle: Text(data['prescriptionsFile'] ?? '')),
                      ListTile(title: Text('Plan de îngrijire personalizat'), subtitle: Text(data['carePlanFile'] ?? '')),
                      // TODO: Adaugă funcționalitate upload/download
                    ],
                  ),
                ),
                isExpanded: expandedPanels[5],
              ),
            ],
          ),
        ),
      ),
    );
  }
// ...existing code...
  void showProfilePhotoDialog() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Încarcă poză de profil"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.photo_library),
              label: Text("Selectează poză"),
              onPressed: () async {
                // TODO: Implementare upload folosind image_picker și Firebase Storage
                // După upload, salvează URL în Firestore la profilePhotoUrl
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Funcționalitate upload în lucru")),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Anulează")),
        ],
      ),
    );
  }

  void showEditContactsDialog(Map<String, dynamic> data) {
    final mainContactNameController = TextEditingController(text: data['mainContactName'] ?? '');
    final mainContactRelationController = TextEditingController(text: data['mainContactRelation'] ?? '');
    final mainContactPhoneController = TextEditingController(text: data['mainContactPhone'] ?? '');
    final mainContactEmailController = TextEditingController(text: data['mainContactEmail'] ?? '');
    final backupContactNameController = TextEditingController(text: data['backupContactName'] ?? '');
    final familyDoctorController = TextEditingController(text: data['familyDoctor'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Editează contacte importante"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: mainContactNameController, decoration: InputDecoration(labelText: "Persoană de contact principală")),
              TextField(controller: mainContactRelationController, decoration: InputDecoration(labelText: "Relație")),
              TextField(controller: mainContactPhoneController, decoration: InputDecoration(labelText: "Telefon")),
              TextField(controller: mainContactEmailController, decoration: InputDecoration(labelText: "Email")),
              TextField(controller: backupContactNameController, decoration: InputDecoration(labelText: "Persoană de rezervă")),
              TextField(controller: familyDoctorController, decoration: InputDecoration(labelText: "Medicul de familie")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Anulează")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('residents')
                  .doc(widget.residentId)
                  .update({
                'mainContactName': mainContactNameController.text.trim(),
                'mainContactRelation': mainContactRelationController.text.trim(),
                'mainContactPhone': mainContactPhoneController.text.trim(),
                'mainContactEmail': mainContactEmailController.text.trim(),
                'backupContactName': backupContactNameController.text.trim(),
                'familyDoctor': familyDoctorController.text.trim(),
              });
              Navigator.pop(context);
              fetchResident();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Contacte actualizate")),
              );
            },
            child: Text("Salvează"),
          ),
        ],
      ),
    );
  }

  void showEditMedicalDialog(Map<String, dynamic> data) {
    final bloodTypeController = TextEditingController(text: data['bloodType'] ?? '');
    final allergiesController = TextEditingController(text: data['allergies'] ?? '');
    final diagnosisController = TextEditingController(text: data['diagnosis'] ?? '');
    final medicationController = TextEditingController(text: data['medication'] ?? '');
    final medicationScheduleController = TextEditingController(text: data['medicationSchedule'] ?? '');
    final medicalHistoryController = TextEditingController(text: data['medicalHistory'] ?? '');
    final mobilityController = TextEditingController(text: data['mobility'] ?? '');
    final dietController = TextEditingController(text: data['diet'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Editează informații medicale"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: bloodTypeController, decoration: InputDecoration(labelText: "Grupa sanguină")),
              TextField(controller: allergiesController, decoration: InputDecoration(labelText: "Alergii")),
              TextField(controller: diagnosisController, decoration: InputDecoration(labelText: "Diagnostic(e) principale")),
              TextField(controller: medicationController, decoration: InputDecoration(labelText: "Tratament curent")),
              TextField(controller: medicationScheduleController, decoration: InputDecoration(labelText: "Orar tratament")),
              TextField(controller: medicalHistoryController, decoration: InputDecoration(labelText: "Istoric medical")),
              TextField(controller: mobilityController, decoration: InputDecoration(labelText: "Mobilitate")),
              TextField(controller: dietController, decoration: InputDecoration(labelText: "Dietă specială")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Anulează")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('residents')
                  .doc(widget.residentId)
                  .update({
                'bloodType': bloodTypeController.text.trim(),
                'allergies': allergiesController.text.trim(),
                'diagnosis': diagnosisController.text.trim(),
                'medication': medicationController.text.trim(),
                'medicationSchedule': medicationScheduleController.text.trim(),
                'medicalHistory': medicalHistoryController.text.trim(),
                'mobility': mobilityController.text.trim(),
                'diet': dietController.text.trim(),
              });
              Navigator.pop(context);
              fetchResident();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Date medicale actualizate")),
              );
            },
            child: Text("Salvează"),
          ),
        ],
      ),
    );
  }

  void showEditEmotionalDialog(Map<String, dynamic> data) {
    final orientationController = TextEditingController(text: data['orientation'] ?? '');
    final cognitiveIssuesController = TextEditingController(text: data['cognitiveIssues'] ?? '');
    final psychologicalNotesController = TextEditingController(text: data['psychologicalNotes'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Editează stare emoțională / cognitivă"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: orientationController, decoration: InputDecoration(labelText: "Nivel de orientare")),
              TextField(controller: cognitiveIssuesController, decoration: InputDecoration(labelText: "Tulburări cognitive")),
              TextField(controller: psychologicalNotesController, decoration: InputDecoration(labelText: "Observații psihologice")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Anulează")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('residents')
                  .doc(widget.residentId)
                  .update({
                'orientation': orientationController.text.trim(),
                'cognitiveIssues': cognitiveIssuesController.text.trim(),
                'psychologicalNotes': psychologicalNotesController.text.trim(),
              });
              Navigator.pop(context);
              fetchResident();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Date emoționale/cognitive actualizate")),
              );
            },
            child: Text("Salvează"),
          ),
        ],
      ),
    );
  }

  void showEditPreferencesDialog(Map<String, dynamic> data) {
    final hobbiesController = TextEditingController(text: data['hobbies'] ?? '');
    final favoriteActivitiesController = TextEditingController(text: data['favoriteActivities'] ?? '');
    final eventParticipationController = TextEditingController(text: data['eventParticipation'] ?? '');
    final foodPreferencesController = TextEditingController(text: data['foodPreferences'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Editează activități și preferințe"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: hobbiesController, decoration: InputDecoration(labelText: "Hobby-uri")),
              TextField(controller: favoriteActivitiesController, decoration: InputDecoration(labelText: "Activități preferate")),
              TextField(controller: eventParticipationController, decoration: InputDecoration(labelText: "Participare la evenimente")),
              TextField(controller: foodPreferencesController, decoration: InputDecoration(labelText: "Preferințe alimentare")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Anulează")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('residents')
                  .doc(widget.residentId)
                  .update({
                'hobbies': hobbiesController.text.trim(),
                'favoriteActivities': favoriteActivitiesController.text.trim(),
                'eventParticipation': eventParticipationController.text.trim(),
                'foodPreferences': foodPreferencesController.text.trim(),
              });
              Navigator.pop(context);
              fetchResident();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Preferințe actualizate")),
              );
            },
            child: Text("Salvează"),
          ),
        ],
      ),
    );
  }

  Future<void> fetchResident() async {
    return await FirebaseFirestore.instance
        .collection('residents')
        .doc(widget.residentId)
        .get()
        .then((snapshot) {
      setState(() {
        residentSnapshot = snapshot;
        isLoading = false;
      });
    }).catchError((error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Eroare la încărcarea datelor rezidentului: $error")),
      );
    });
  }

  void showEditDialog(Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['name'] ?? '');
    final birthdateController = TextEditingController(text: data['birthdate'] ?? '');
    final cnpController = TextEditingController(text: data['cnp'] ?? '');
    final internalCodeController = TextEditingController(text: data['internalCode'] ?? '');
    final legalStatusController = TextEditingController(text: data['legalStatus'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Editează date personale"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Nume complet")),
              TextField(controller: birthdateController, decoration: InputDecoration(labelText: "Data nașterii")),
              TextField(controller: cnpController, decoration: InputDecoration(labelText: "CNP (criptat)")),
              TextField(controller: internalCodeController, decoration: InputDecoration(labelText: "Cod intern/familie")),
              TextField(controller: legalStatusController, decoration: InputDecoration(labelText: "Status juridic")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Anulează")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('residents')
                  .doc(widget.residentId)
                  .update({
                'name': nameController.text.trim(),
                'birthdate': birthdateController.text.trim(),
                'cnp': cnpController.text.trim(),
                'internalCode': internalCodeController.text.trim(),
                'legalStatus': legalStatusController.text.trim(),
              });
              Navigator.pop(context);
              fetchResident();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Date personale actualizate")),
              );
            },
            child: Text("Salvează"),
          ),
        ],
      ),
    );
  }
}