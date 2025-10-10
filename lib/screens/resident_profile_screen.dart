import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'app_drawer.dart';

class ResidentProfileScreen extends StatefulWidget {
  final String residentId;
  final bool? readOnly;
  const ResidentProfileScreen({Key? key, required this.residentId, this.readOnly}) : super(key: key);

  @override
  _ResidentProfileScreenState createState() => _ResidentProfileScreenState();
}

class _ResidentProfileScreenState extends State<ResidentProfileScreen> {

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
    return Scaffold(
      drawer: (widget.readOnly ?? false)
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
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('residents')
            .doc(widget.residentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Eroare la încărcarea datelor: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() ?? <String, dynamic>{};
          final profilePhotoUrl = data['profilePhotoUrl'] as String?;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header cu poza și info principale
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundImage: (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty)
                                ? NetworkImage(profilePhotoUrl)
                                : null,
                            child: (profilePhotoUrl == null || profilePhotoUrl.isEmpty)
                                ? Icon(Icons.person, size: 36)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['name'] ?? '', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text('Data nașterii: ${data['birthdate'] ?? ''}', style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              OutlinedButton.icon(
                                onPressed: showProfilePhotoDialog,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Schimbă poză'),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () => showEditDialog(data),
                                icon: const Icon(Icons.edit),
                                label: const Text('Editează'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 1. Date personale
                  Card(
                    elevation: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          leading: Icon(Icons.info, color: Colors.teal),
                          title: Text('Date personale', style: Theme.of(context).textTheme.titleMedium),
                          trailing: IconButton(
                            icon: Icon(Icons.edit, color: Colors.teal),
                            onPressed: () => showEditDialog(data),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(title: Text('CNP (criptat)'), subtitle: Text(data['cnp'] ?? '')),
                        ListTile(title: Text('Cod intern/familie'), subtitle: Text(data['internalCode'] ?? '')),
                        ListTile(title: Text('Status juridic'), subtitle: Text(data['legalStatus'] ?? '')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. Contacte importante
                  Card(
                    elevation: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          leading: Icon(Icons.contact_phone, color: Colors.blue),
                          title: Text('Contacte importante', style: Theme.of(context).textTheme.titleMedium),
                          trailing: IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => showEditContactsDialog(data),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(title: Text('Persoană de contact principală'), subtitle: Text(data['mainContactName'] ?? '')),
                        ListTile(title: Text('Relație'), subtitle: Text(data['mainContactRelation'] ?? '')),
                        ListTile(title: Text('Telefon'), subtitle: Text(data['mainContactPhone'] ?? '')),
                        ListTile(title: Text('Email'), subtitle: Text(data['mainContactEmail'] ?? '')),
                        ListTile(title: Text('Persoană de rezervă'), subtitle: Text(data['backupContactName'] ?? '')),
                        ListTile(title: Text('Medicul de familie'), subtitle: Text(data['familyDoctor'] ?? '')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. Informații medicale
                  Card(
                    elevation: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          leading: Icon(Icons.medical_services, color: Colors.red),
                          title: Text('Informații medicale', style: Theme.of(context).textTheme.titleMedium),
                          trailing: IconButton(
                            icon: Icon(Icons.edit, color: Colors.red),
                            onPressed: () => showEditMedicalDialog(data),
                          ),
                        ),
                        const Divider(height: 1),
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

                  const SizedBox(height: 12),

                  // 4. Stare emoțională / cognitivă
                  Card(
                    elevation: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          leading: Icon(Icons.psychology, color: Colors.purple),
                          title: Text('Stare emoțională / cognitivă', style: Theme.of(context).textTheme.titleMedium),
                          trailing: IconButton(
                            icon: Icon(Icons.edit, color: Colors.purple),
                            onPressed: () => showEditEmotionalDialog(data),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(title: Text('Nivel de orientare'), subtitle: Text(data['orientation'] ?? '')),
                        ListTile(title: Text('Tulburări cognitive'), subtitle: Text(data['cognitiveIssues'] ?? '')),
                        ListTile(title: Text('Observații psihologice'), subtitle: Text(data['psychologicalNotes'] ?? '')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 5. Activități și preferințe
                  Card(
                    elevation: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          leading: Icon(Icons.sports_handball, color: Colors.green),
                          title: Text('Activități și preferințe', style: Theme.of(context).textTheme.titleMedium),
                          trailing: IconButton(
                            icon: Icon(Icons.edit, color: Colors.green),
                            onPressed: () => showEditPreferencesDialog(data),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(title: Text('Hobby-uri'), subtitle: Text(data['hobbies'] ?? '')),
                        ListTile(title: Text('Activități preferate'), subtitle: Text(data['favoriteActivities'] ?? '')),
                        ListTile(title: Text('Participare la evenimente'), subtitle: Text(data['eventParticipation'] ?? '')),
                        ListTile(title: Text('Preferințe alimentare'), subtitle: Text(data['foodPreferences'] ?? '')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 6. Fișiere și documente
                  Card(
                    elevation: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          leading: Icon(Icons.folder, color: Colors.orange),
                          title: Text('Fișiere și documente', style: Theme.of(context).textTheme.titleMedium),
                        ),
                        const Divider(height: 1),
                        ListTile(title: Text('Contract de internare'), subtitle: Text(data['contractFile'] ?? '')),
                        ListTile(title: Text('Buletin / CI scanat'), subtitle: Text(data['idFile'] ?? '')),
                        ListTile(title: Text('Rețete medicale'), subtitle: Text(data['prescriptionsFile'] ?? '')),
                        ListTile(title: Text('Plan de îngrijire personalizat'), subtitle: Text(data['carePlanFile'] ?? '')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
              label: Text("Din galerie"),
              onPressed: () async {
                Navigator.pop(context);
                await _pickAndUploadProfilePhoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text("Fă o poză"),
              onPressed: () async {
                Navigator.pop(context);
                await _pickAndUploadProfilePhoto(ImageSource.camera);
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

  Future<void> _pickAndUploadProfilePhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600);
      if (picked == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selectarea imaginii a fost anulată')),
        );
        return;
      }

      // Afișează dialog de progres
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Încarcă în Firebase Storage folosind bytes (compatibil web/desktop/mobile)
      Uint8List bytes = await picked.readAsBytes();
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('residents')
          .child(widget.residentId)
          .child('profile.jpg');

      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await storageRef.putData(bytes, metadata);
      final downloadUrl = await storageRef.getDownloadURL();

      // Salvează URL-ul în Firestore
      await FirebaseFirestore.instance
          .collection('residents')
          .doc(widget.residentId)
          .update({'profilePhotoUrl': downloadUrl});

      Navigator.of(context, rootNavigator: true).pop(); // închide progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Poză de profil actualizată')),
      );
    } on FirebaseException catch (e) {
      Navigator.of(context, rootNavigator: true).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare Firebase: ${e.message ?? e.code}')),
      );
    } catch (e) {
      Navigator.of(context, rootNavigator: true).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la încărcarea pozei: $e')),
      );
    }
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

  // Datele sunt ascultate în timp real prin StreamBuilder; nu mai e nevoie de fetch manual.

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