import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'resident_profile_screen.dart';
import 'app_drawer.dart';

class ResidentsScreen extends StatefulWidget {
  @override
  State<ResidentsScreen> createState() => _ResidentsScreenState();
}

class _ResidentsScreenState extends State<ResidentsScreen> {
  void showAddResidentDialog() {
    showDialog(
      context: context,
      builder: (context) => AddResidentDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(currentRoute: 'residents'),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.people, color: Colors.white),
            SizedBox(width: 8),
            Text("Rezidenți"),
          ],
        ),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: showAddResidentDialog,
              icon: Icon(Icons.person_add),
              label: Text("Adaugă rezident"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('residents').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return Center(child: Text("Nu există rezidenți."));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.teal[50],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal[300],
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(data['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Camera: \\${data['room'] ?? ''}"),
                            if ((data['notes'] ?? '').isNotEmpty)
                              Text(data['notes'], style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.teal[700]),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResidentProfileScreen(residentId: doc.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Modernizez dialogul de adăugare rezident
class AddResidentDialog extends StatefulWidget {
  @override
  _AddResidentDialogState createState() => _AddResidentDialogState();
}

class _AddResidentDialogState extends State<AddResidentDialog> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final birthdateController = TextEditingController();
  final roomController = TextEditingController();
  final bloodTypeController = TextEditingController();
  final allergiesController = TextEditingController();
  final medicationController = TextEditingController();
  final contactController = TextEditingController();
  final familyController = TextEditingController();
  final notesController = TextEditingController();

  Future<void> addResident() async {
    if (_formKey.currentState!.validate()) {
      final residentRef = await FirebaseFirestore.instance.collection('residents').add({
        'name': nameController.text.trim(),
        'age': ageController.text.trim(),
        'birthdate': birthdateController.text.trim(),
        'room': roomController.text.trim(),
        'bloodType': bloodTypeController.text.trim(),
        'allergies': allergiesController.text.trim(),
        'medication': medicationController.text.trim(),
        'contact': contactController.text.trim(),
        'familyMember': familyController.text.trim(),
        'notes': notesController.text.trim(),
      });
      // Generează cod unic pentru familie/aparținător
      final code = _generateFamilyCode();
      await FirebaseFirestore.instance.collection('family_codes').add({
        'code': code,
        'patientId': residentRef.id,
        'createdAt': DateTime.now().toIso8601String(),
        'used': false,
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Rezident adăugat cu succes! Cod familie: $code")),
      );
    }
  }

  String _generateFamilyCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(7, (i) => chars[(DateTime.now().millisecondsSinceEpoch + i * 13) % chars.length]).join();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.person_add, color: Colors.teal),
          SizedBox(width: 8),
          Text("Adaugă rezident"),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: nameController, decoration: InputDecoration(labelText: "Nume", prefixIcon: Icon(Icons.person)), validator: (v) => v!.isEmpty ? "Obligatoriu" : null),
              TextFormField(controller: ageController, decoration: InputDecoration(labelText: "Vârstă", prefixIcon: Icon(Icons.cake)), keyboardType: TextInputType.number),
              TextFormField(
                controller: birthdateController,
                readOnly: true,
                decoration: InputDecoration(labelText: "Data nașterii", prefixIcon: Icon(Icons.calendar_today)),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    birthdateController.text = picked.toLocal().toString().split(' ')[0];
                  }
                },
              ),
              TextFormField(controller: roomController, decoration: InputDecoration(labelText: "Camera", prefixIcon: Icon(Icons.meeting_room))),
              DropdownButtonFormField<String>(
                value: bloodTypeController.text.isNotEmpty ? bloodTypeController.text : null,
                decoration: InputDecoration(labelText: "Grupă sanguină", prefixIcon: Icon(Icons.bloodtype)),
                items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => bloodTypeController.text = value!),
              ),
              TextFormField(controller: allergiesController, decoration: InputDecoration(labelText: "Alergii", prefixIcon: Icon(Icons.warning_amber))),
              TextFormField(controller: medicationController, decoration: InputDecoration(labelText: "Tratament", prefixIcon: Icon(Icons.medical_services))),
              TextFormField(controller: contactController, decoration: InputDecoration(labelText: "Număr de contact", prefixIcon: Icon(Icons.phone))),
              TextFormField(controller: familyController, decoration: InputDecoration(labelText: "Membru familie", prefixIcon: Icon(Icons.family_restroom))),
              TextFormField(controller: notesController, decoration: InputDecoration(labelText: "Observații", prefixIcon: Icon(Icons.note))),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("Anulează")),
        ElevatedButton.icon(
          onPressed: addResident,
          icon: Icon(Icons.save),
          label: Text("Salvează"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}