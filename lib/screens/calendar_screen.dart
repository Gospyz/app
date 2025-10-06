import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'app_drawer.dart';

class CalendarScreen extends StatefulWidget {
  final String? residentId;
  const CalendarScreen({Key? key, this.residentId}) : super(key: key);
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selectedDate = DateTime.now();
  final titleController = TextEditingController();
  final timeController = TextEditingController();
  final locationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    final bool isFamily = widget.residentId != null;

    return Scaffold(
      drawer: widget.residentId != null
          ? AppDrawer(currentRoute: 'calendar', isFamily: true, patientId: widget.residentId)
          : AppDrawer(currentRoute: 'calendar'),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.calendar_month, color: Colors.white),
            SizedBox(width: 8),
            Text("Calendar activități"),
          ],
        ),
        backgroundColor: Colors.teal,
        actions: isFamily ? null : [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Adaugă activitate',
            onPressed: () {
              // ...codul pentru adăugare activitate...
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // SELECTOR DATĂ
            ListTile(
              title: Text("Data selectată: $formattedDate", style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Icon(Icons.calendar_today, color: Colors.teal),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
            ),
            // FORMULAR ADĂUGARE ACTIVITATE (doar staff)
            if (!isFamily)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: "Titlu",
                            prefixIcon: Icon(Icons.title),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: timeController,
                          decoration: InputDecoration(
                            labelText: "Ora",
                            prefixIcon: Icon(Icons.access_time),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: locationController,
                          decoration: InputDecoration(
                            labelText: "Locație",
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: addActivity,
                          icon: Icon(Icons.add),
                          label: Text("Adaugă activitate"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // LISTĂ ACTIVITĂȚI
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: widget.residentId != null
                    ? FirebaseFirestore.instance
                        .collection('activities')
                        .where('date', isEqualTo: formattedDate)
                        .where('residentId', isEqualTo: widget.residentId)
                        .orderBy('time')
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('activities')
                        .where('date', isEqualTo: formattedDate)
                        .orderBy('time')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, color: Colors.grey, size: 64),
                        SizedBox(height: 16),
                        Text('Nicio activitate pentru această zi.', style: TextStyle(fontSize: 18, color: Colors.grey)),
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
                          title: Text(data['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ora: ${data['time'] ?? ''}'),
                              Text('Locație: ${data['location'] ?? ''}'),
                            ],
                          ),
                          trailing: isFamily ? null : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                tooltip: 'Editează',
                                onPressed: () {
                                  // ...codul pentru editare activitate...
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Șterge',
                                onPressed: () async {
                                  // ...codul pentru ștergere activitate...
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
          ],
        ),
      ),
    );
  }

  void addActivity() {
    // Implementați logica pentru a adăuga o activitate
  }
}
