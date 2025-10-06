import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'resident_medications_screen.dart';
import 'appointments_screen.dart';
import 'app_drawer.dart';
import 'package:flutter/services.dart';

class ResidentProfileScreen extends StatefulWidget {
  final String residentId;
  final bool readOnly;

  ResidentProfileScreen({required this.residentId, this.readOnly = false});

  @override
  _ResidentProfileScreenState createState() => _ResidentProfileScreenState();
}

class _ResidentProfileScreenState extends State<ResidentProfileScreen> {
  late DocumentSnapshot residentSnapshot;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchResident();
  }

  Future<void> fetchResident() async {
    final doc = await FirebaseFirestore.instance
        .collection('residents')
        .doc(widget.residentId)
        .get();
    setState(() {
      residentSnapshot = doc;
      isLoading = false;
    });
  }

  void showEditDialog(Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['name']);
    final ageController = TextEditingController(text: data['age']);
    final birthdateController = TextEditingController(text: data['birthdate']);
    final roomController = TextEditingController(text: data['room']);
    final bloodTypeController = TextEditingController(text: data['bloodType']);
    final allergiesController = TextEditingController(text: data['allergies']);
    final medicationController = TextEditingController(text: data['medication']);
    final contactController = TextEditingController(text: data['contact']);
    final familyController = TextEditingController(text: data['familyMember']);
    final notesController = TextEditingController(text: data['notes']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Editează rezident"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Nume")),
              TextField(controller: ageController, decoration: InputDecoration(labelText: "Vârstă")),
              TextField(controller: birthdateController, decoration: InputDecoration(labelText: "Data nașterii")),
              TextField(controller: roomController, decoration: InputDecoration(labelText: "Camera")),
              TextField(controller: bloodTypeController, decoration: InputDecoration(labelText: "Grupă sanguină")),
              TextField(controller: allergiesController, decoration: InputDecoration(labelText: "Alergii")),
              TextField(controller: medicationController, decoration: InputDecoration(labelText: "Tratament")),
              TextField(controller: contactController, decoration: InputDecoration(labelText: "Număr de contact")),
              TextField(controller: familyController, decoration: InputDecoration(labelText: "Membru familie")),
              TextField(controller: notesController, decoration: InputDecoration(labelText: "Observații")),
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
              Navigator.pop(context);
              fetchResident();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Profil actualizat")),
              );
            },
            child: Text("Salvează"),
          ),
        ],
      ),
    );
  }

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

    fetchResident();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Scaffold(body: Center(child: CircularProgressIndicator()));

    final data = residentSnapshot.data() as Map<String, dynamic>;

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
        actions: [
          if (!widget.readOnly)
            IconButton(
              icon: Icon(Icons.edit),
              tooltip: 'Editează',
              onPressed: () => showEditDialog(data),
            )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ListView(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.teal[300],
                            child: Icon(Icons.person, color: Colors.white, size: 40),
                            radius: 36,
                          ),
                          SizedBox(width: 18),
                          Expanded(
                            child: Text(data['name'] ?? '', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text("Vârstă: ${data['age'] ?? ''}", style: TextStyle(fontSize: 16)),
                      Text("Camera: ${data['room'] ?? ''}", style: TextStyle(fontSize: 16)),
                      Divider(height: 30),
                      Text("🧺 Informații medicale", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ListTile(
                        leading: Icon(Icons.bloodtype, color: Colors.red[300]),
                        title: Text("Grupă sanguină"),
                        subtitle: Text(data['bloodType'] ?? ''),
                      ),
                      ListTile(
                        leading: Icon(Icons.warning_amber, color: Colors.orange[300]),
                        title: Text("Alergii"),
                        subtitle: Text(data['allergies'] ?? ''),
                      ),
                      ListTile(
                        leading: Icon(Icons.medical_services, color: Colors.blue[300]),
                        title: Text("Tratament curent"),
                        subtitle: Text(data['medication'] ?? ''),
                      ),
                      Divider(height: 30),
                      Text("📞 Informații personale", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ListTile(
                        leading: Icon(Icons.phone, color: Colors.teal),
                        title: Text("Număr de contact"),
                        subtitle: Text(data['contact'] ?? ''),
                      ),
                      ListTile(
                        leading: Icon(Icons.family_restroom, color: Colors.teal[200]),
                        title: Text("Membru familie"),
                        subtitle: Text(data['familyMember'] ?? ''),
                      ),
                      ListTile(
                        leading: Icon(Icons.note, color: Colors.grey[600]),
                        title: Text("Observații"),
                        subtitle: Text(data['notes'] ?? ''),
                      ),
                      Divider(height: 30),
                      FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('family_codes')
                            .where('patientId', isEqualTo: widget.residentId)
                            .limit(1)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Text('Eroare la încărcarea codului de familie', style: TextStyle(color: Colors.red));
                          }
                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return Text('Nu există cod de familie generat pentru acest pacient.', style: TextStyle(color: Colors.orange));
                          }
                          final code = docs.first['code'];
                          return Card(
                            color: Colors.teal[50],
                            margin: EdgeInsets.symmetric(vertical: 12),
                            child: ListTile(
                              leading: Icon(Icons.vpn_key, color: Colors.teal),
                              title: Text('Cod pentru creare cont familie/aparținător'),
                              subtitle: SelectableText(code, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              trailing: (!widget.readOnly)
                                  ? IconButton(
                                      icon: Icon(Icons.copy, color: Colors.teal),
                                      tooltip: 'Copiază codul',
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: code));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Cod copiat în clipboard!')),
                                        );
                                      },
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
