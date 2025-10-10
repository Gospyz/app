import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_drawer.dart';

class ResidentMedicationsScreen extends StatefulWidget {
  final String residentId;
  final String residentName;

  const ResidentMedicationsScreen({
    Key? key,
    required this.residentId,
    required this.residentName,
  }) : super(key: key);

  @override
  State<ResidentMedicationsScreen> createState() => _ResidentMedicationsScreenState();
}

class _ResidentMedicationsScreenState extends State<ResidentMedicationsScreen> {
  bool get isFamily => widget.residentId.startsWith('family_');

  Future<void> _sendMedicationNotification({
    required String residentId,
    required String residentName,
    required String medicationName,
    required String dose,
    required String schedule,
    String? notes,
    bool isUpdate = false,
    bool isDelete = false,
  }) async {
    try {
      // Găsim aparținătorii care au activat notificările pentru medicamente
      final QuerySnapshot familyMembers = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'family')
          .where('patientId', isEqualTo: residentId)
          .get();

      for (var doc in familyMembers.docs) {
        // Verificăm preferințele de notificări ale aparținătorului
        final prefs = await FirebaseFirestore.instance
            .collection('users')
            .doc(doc.id)
            .collection('notification_preferences')
            .doc('settings')
            .get();

        if (prefs.exists && prefs.data()?['medications'] == true) {
          // Construim mesajul notificării
          String title;
          String message;
          
          if (isDelete) {
            title = 'Medicament șters';
            message = 'Medicamentul ${medicationName} a fost șters din schema de tratament pentru ${residentName}.';
          } else {
            final action = isUpdate ? "actualizat" : "adăugat";
            title = 'Medicament ${action}';
            message = 'Medicament ${action} pentru ${residentName}:\n'
                'Nume: ${medicationName}\n'
                'Doză: ${dose}\n'
                'Orar: ${schedule}' +
                (notes?.isNotEmpty == true ? '\nObservații: ${notes}' : '');
          }

          // Adăugăm notificarea în Firestore
          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': doc.id,
            'title': title,
            'message': message,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
            'type': 'medication',
            'residentId': residentId,
            'medicationName': medicationName,
            'schedule': schedule
          });
        }
      }
    } catch (e) {
      print('Eroare la trimiterea notificărilor: $e');
    }
  }

  void _showAddMedicationDialog() {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final doseController = TextEditingController();
    final scheduleController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Adaugă medicament'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Nume medicament', prefixIcon: Icon(Icons.medication)),
                  validator: (v) => v == null || v.isEmpty ? 'Completează numele' : null,
                ),
                TextFormField(
                  controller: doseController,
                  decoration: InputDecoration(labelText: 'Doză', prefixIcon: Icon(Icons.straighten)),
                ),
                TextFormField(
                  controller: scheduleController,
                  decoration: InputDecoration(labelText: 'Orar administrare', prefixIcon: Icon(Icons.schedule)),
                ),
                TextFormField(
                  controller: notesController,
                  decoration: InputDecoration(labelText: 'Observații', prefixIcon: Icon(Icons.note)),
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
                final docRef = await FirebaseFirestore.instance.collection('medications').add({
                  'residentId': widget.residentId,
                  'residentName': widget.residentName,
                  'name': nameController.text.trim(),
                  'dose': doseController.text.trim(),
                  'schedule': scheduleController.text.trim(),
                  'notes': notesController.text.trim(),
                });
                // Creez alertă
                await FirebaseFirestore.instance.collection('alerts').add({
                  'type': 'medicament',
                  'title': 'Medicament: ${nameController.text.trim()}',
                  'subtitle': 'Rezident: ${widget.residentName} | Orar: ${scheduleController.text.trim()}',
                  'seen': false,
                  'createdAt': DateTime.now().toIso8601String(),
                  'relatedId': docRef.id,
                });
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Medicament adăugat!')),
                );
              }
            },
            child: Text('Salvează'),
          ),
        ],
      ),
    );
  }

  void _showEditMedicationDialog(String docId, Map<String, dynamic> data) {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: data['name']);
    final doseController = TextEditingController(text: data['dose']);
    final scheduleController = TextEditingController(text: data['schedule']);
    final notesController = TextEditingController(text: data['notes']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Editează medicament'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Nume medicament', prefixIcon: Icon(Icons.medication)),
                  validator: (v) => v == null || v.isEmpty ? 'Completează numele' : null,
                ),
                TextFormField(
                  controller: doseController,
                  decoration: InputDecoration(labelText: 'Doză', prefixIcon: Icon(Icons.straighten)),
                ),
                TextFormField(
                  controller: scheduleController,
                  decoration: InputDecoration(labelText: 'Orar administrare', prefixIcon: Icon(Icons.schedule)),
                ),
                TextFormField(
                  controller: notesController,
                  decoration: InputDecoration(labelText: 'Observații', prefixIcon: Icon(Icons.note)),
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
                // Actualizăm medicamentul în Firestore
                await FirebaseFirestore.instance.collection('medications').doc(docId).update({
                  'name': nameController.text.trim(),
                  'dose': doseController.text.trim(),
                  'schedule': scheduleController.text.trim(),
                  'notes': notesController.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                // Trimitem notificări către aparținători despre actualizare
                await _sendMedicationNotification(
                  residentId: widget.residentId,
                  residentName: widget.residentName,
                  medicationName: nameController.text.trim(),
                  dose: doseController.text.trim(),
                  schedule: scheduleController.text.trim(),
                  notes: notesController.text.trim(),
                  isUpdate: true,
                );

                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Medicament actualizat și notificări trimise!')),
                );
              }
            },
            child: Text('Salvează'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMedication(String docId) async {
    // Obținem datele medicamentului înainte de ștergere
    final medicationDoc = await FirebaseFirestore.instance.collection('medications').doc(docId).get();
    final medicationData = medicationDoc.data() as Map<String, dynamic>;

    // Ștergem medicamentul
    await FirebaseFirestore.instance.collection('medications').doc(docId).delete();

    // Trimitem notificări către aparținători despre ștergere
    await _sendMedicationNotification(
      residentId: widget.residentId,
      residentName: widget.residentName,
      medicationName: medicationData['name'] ?? '',
      dose: medicationData['dose'] ?? '',
      schedule: medicationData['schedule'] ?? '',
      notes: medicationData['notes'],
      isDelete: true,
    );

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Medicament șters și notificări trimise!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.medical_services, color: Colors.white),
            SizedBox(width: 8),
            Text('Medicamente - ${widget.residentName}'),
          ],
        ),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // HEADER MODERNIZAT
            Card(
              color: Colors.teal[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 6,
              margin: EdgeInsets.only(bottom: 18),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Icon(Icons.medication, color: Colors.teal, size: 36),
                    SizedBox(width: 16),
                    Text('Medicamente rezident', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal[900])),
                  ],
                ),
              ),
            ),
            // LISTĂ MEDICAMENTE
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('medications')
                    .where('residentId', isEqualTo: widget.residentId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medication_outlined, color: Colors.grey, size: 64),
                        SizedBox(height: 16),
                        Text('Nu există medicamente salvate.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        color: Colors.teal[50],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: ListTile(
                          leading: Icon(Icons.medication, color: Colors.teal),
                          title: Text(data['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Doză: ${data['dose'] ?? ''}'),
                              Text('Orar: ${data['schedule'] ?? ''}'),
                              if ((data['notes'] ?? '').isNotEmpty) Text('Observații: ${data['notes']}'),
                            ],
                          ),
                          trailing: isFamily ? null : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                tooltip: 'Editează',
                                onPressed: () => _showEditMedicationDialog(doc.id, data),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Șterge',
                                onPressed: () => _deleteMedication(doc.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isFamily ? null : FloatingActionButton.extended(
        onPressed: _showAddMedicationDialog,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Adaugă medicament', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
