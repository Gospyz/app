import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_drawer.dart';

class AppointmentsScreen extends StatefulWidget {
  final String? residentId;
  final String? residentName;
  const AppointmentsScreen({Key? key, this.residentId, this.residentName}) : super(key: key);
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isFamily = widget.residentId != null;
    final query = widget.residentId != null
        ? FirebaseFirestore.instance.collection('appointments').where('residentId', isEqualTo: widget.residentId)
        : FirebaseFirestore.instance.collection('appointments');
    return Scaffold(
      drawer: widget.residentId != null ? AppDrawer(currentRoute: 'appointments', isFamily: true, patientId: widget.residentId) : AppDrawer(currentRoute: 'appointments'),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.medical_services, color: Colors.white),
            SizedBox(width: 8),
            Text('Programări la medic'),
          ],
        ),
        backgroundColor: Colors.teal,
        actions: isFamily ? null : [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Adaugă programare',
            onPressed: () {
              showAddAppointmentDialog(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Eroare la încărcarea datelor: ${snapshot.error}'));
            }
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, color: Colors.grey, size: 64),
                  SizedBox(height: 16),
                  Text('Nu există programări salvate.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
            // Sortare locală după dată și oră
            final sortedDocs = List.from(docs);
            sortedDocs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aDateTime = DateTime.tryParse('${aData['date']} ${aData['time']}') ?? DateTime(2000);
              final bDateTime = DateTime.tryParse('${bData['date']} ${bData['time']}') ?? DateTime(2000);
              return aDateTime.compareTo(bDateTime);
            });
            return ListView.builder(
              itemCount: sortedDocs.length,
              itemBuilder: (context, index) {
                final doc = sortedDocs[index];
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  color: Colors.teal[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 5,
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal[200],
                      child: Icon(Icons.medical_services, color: Colors.teal[900]),
                    ),
                    title: Text(data['type'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rezident: ${data['residentName'] ?? ''}'),
                        Text('Data: ${data['date'] ?? ''}  Ora: ${data['time'] ?? ''}'),
                        if ((data['notes'] ?? '').isNotEmpty) Text('Observații: ${data['notes']}'),
                      ],
                    ),
                    trailing: isFamily ? null : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Editează',
                          onPressed: () {
                            _showEditAppointmentDialog(context, doc.id, data);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Șterge',
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('appointments').doc(doc.id).delete();
                          },
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
      floatingActionButton: isFamily ? null : (widget.residentId != null
          ? FloatingActionButton.extended(
              onPressed: () {
                showAddAppointmentDialog(context);
              },
              label: Text('Adaugă programare pentru \\${widget.residentName}'),
              icon: Icon(Icons.add),
              backgroundColor: Colors.teal,
            )
          : null),
    );
  }

  void showAddAppointmentDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController dateController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    final TextEditingController typeController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    String? selectedResidentId = widget.residentId;
    String? selectedResidentName = widget.residentName;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Adaugă programare'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.residentId == null)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('residents').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return CircularProgressIndicator();
                      final docs = snapshot.data!.docs;
                      return DropdownButtonFormField<String>(
                        value: selectedResidentId,
                        decoration: InputDecoration(labelText: 'Rezident'),
                        items: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text(data['name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) {
                          selectedResidentId = val;
                          final doc = docs.firstWhere((d) => d.id == val);
                          final data = doc.data() as Map<String, dynamic>;
                          selectedResidentName = data['name'];
                        },
                        validator: (v) => v == null ? 'Selectează un rezident' : null,
                      );
                    },
                  ),
                TextFormField(
                  controller: dateController,
                  readOnly: true,
                  decoration: InputDecoration(labelText: 'Data', prefixIcon: Icon(Icons.calendar_today)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                    }
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Selectează data' : null,
                ),
                TextFormField(
                  controller: timeController,
                  decoration: InputDecoration(labelText: 'Ora', prefixIcon: Icon(Icons.access_time)),
                  validator: (v) => v == null || v.isEmpty ? 'Completează ora' : null,
                ),
                TextFormField(
                  controller: typeController,
                  decoration: InputDecoration(labelText: 'Tip programare', prefixIcon: Icon(Icons.medical_services)),
                  validator: (v) => v == null || v.isEmpty ? 'Completează tipul' : null,
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
                await FirebaseFirestore.instance.collection('appointments').add({
                  'residentId': selectedResidentId,
                  'residentName': selectedResidentName,
                  'date': dateController.text,
                  'time': timeController.text,
                  'type': typeController.text,
                  'notes': notesController.text,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Programare adăugată!')),
                );
              }
            },
            child: Text('Salvează'),
          ),
        ],
      ),
    );
  }

  void _showEditAppointmentDialog(BuildContext context, String docId, Map<String, dynamic> data) {
    final _formKey = GlobalKey<FormState>();
    final dateController = TextEditingController(text: data['date']);
    final timeController = TextEditingController(text: data['time']);
    final typeController = TextEditingController(text: data['type']);
    final notesController = TextEditingController(text: data['notes']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Editează programare'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: dateController,
                  readOnly: true,
                  decoration: InputDecoration(labelText: 'Data', prefixIcon: Icon(Icons.calendar_today)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                    }
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Selectează data' : null,
                ),
                TextFormField(
                  controller: timeController,
                  decoration: InputDecoration(labelText: 'Ora', prefixIcon: Icon(Icons.access_time)),
                  validator: (v) => v == null || v.isEmpty ? 'Completează ora' : null,
                ),
                TextFormField(
                  controller: typeController,
                  decoration: InputDecoration(labelText: 'Tip programare', prefixIcon: Icon(Icons.medical_services)),
                  validator: (v) => v == null || v.isEmpty ? 'Completează tipul' : null,
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
                await FirebaseFirestore.instance.collection('appointments').doc(docId).update({
                  'date': dateController.text,
                  'time': timeController.text,
                  'type': typeController.text,
                  'notes': notesController.text,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Programare actualizată!')),
                );
              }
            },
            child: Text('Salvează'),
          ),
        ],
      ),
    );
  }
}
