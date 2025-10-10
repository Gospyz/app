import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? selectedRange;
  bool loading = false;
  List<Map<String, dynamic>> residentReport = [];
  List<Map<String, dynamic>> activityReport = [];
  List<Map<String, dynamic>> medicationReport = [];

  Future<void> generateReports() async {
    setState(() { loading = true; });
    final start = selectedRange?.start ?? DateTime.now().subtract(Duration(days: 30));
    final end = selectedRange?.end ?? DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');

    // Rezidenți activi
    final residentsSnap = await FirebaseFirestore.instance
      .collection('residents')
      .where('status', isNotEqualTo: 'externat')
      .get();
    residentReport = residentsSnap.docs.map((doc) {
      final data = doc.data();
      return {
        'Nume': data['name'] ?? '',
        'Vârstă': data['age'] ?? '',
        'Stare': data['healthStatus'] ?? '',
        'Admis': data['admissionDate'] ?? '',
      };
    }).toList();

    // Activități
    final activitiesSnap = await FirebaseFirestore.instance
      .collection('activities')
      .where('date', isGreaterThanOrEqualTo: dateFormat.format(start))
      .where('date', isLessThanOrEqualTo: dateFormat.format(end))
      .get();
    activityReport = activitiesSnap.docs.map((doc) {
      final data = doc.data();
      return {
        'Titlu': data['title'] ?? '',
        'Data': data['date'] ?? '',
        'Ora': data['time'] ?? '',
        'Locație': data['location'] ?? '',
        'Participanți': (data['participants'] as List<dynamic>?)?.length ?? 0,
      };
    }).toList();

    // Medicamente administrate
    final medicationsSnap = await FirebaseFirestore.instance
      .collection('medications')
      .where('createdAt', isGreaterThanOrEqualTo: start)
      .where('createdAt', isLessThanOrEqualTo: end)
      .get();
    medicationReport = medicationsSnap.docs.map((doc) {
      final data = doc.data();
      return {
        'Rezident': data['residentName'] ?? '',
        'Medicament': data['name'] ?? '',
        'Doză': data['dose'] ?? '',
        'Orar': data['schedule'] ?? '',
      };
    }).toList();

    setState(() { loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rapoarte automate'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selectează perioada:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.date_range),
                  label: Text(selectedRange == null ? 'Alege interval' : '${DateFormat('dd.MM.yyyy').format(selectedRange!.start)} - ${DateFormat('dd.MM.yyyy').format(selectedRange!.end)}'),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDateRange: selectedRange,
                    );
                    if (picked != null) setState(() { selectedRange = picked; });
                  },
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.analytics),
                  label: Text('Generează rapoarte'),
                  onPressed: loading ? null : generateReports,
                ),
              ],
            ),
            SizedBox(height: 20),
            if (loading) Center(child: CircularProgressIndicator()),
            if (!loading && residentReport.isNotEmpty) ...[
              Text('Rezidenți activi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              DataTable(
                columns: [
                  DataColumn(label: Text('Nume')),
                  DataColumn(label: Text('Vârstă')),
                  DataColumn(label: Text('Stare')),
                  DataColumn(label: Text('Admis')),
                ],
                rows: residentReport.map((r) => DataRow(cells: [
                  DataCell(Text(r['Nume'].toString())),
                  DataCell(Text(r['Vârstă'].toString())),
                  DataCell(Text(r['Stare'].toString())),
                  DataCell(Text(r['Admis'].toString())),
                ])).toList(),
              ),
              SizedBox(height: 20),
            ],
            if (!loading && activityReport.isNotEmpty) ...[
              Text('Activități:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              DataTable(
                columns: [
                  DataColumn(label: Text('Titlu')),
                  DataColumn(label: Text('Data')),
                  DataColumn(label: Text('Ora')),
                  DataColumn(label: Text('Locație')),
                  DataColumn(label: Text('Participanți')),
                ],
                rows: activityReport.map((a) => DataRow(cells: [
                  DataCell(Text(a['Titlu'].toString())),
                  DataCell(Text(a['Data'].toString())),
                  DataCell(Text(a['Ora'].toString())),
                  DataCell(Text(a['Locație'].toString())),
                  DataCell(Text(a['Participanți'].toString())),
                ])).toList(),
              ),
              SizedBox(height: 20),
            ],
            if (!loading && medicationReport.isNotEmpty) ...[
              Text('Medicamente administrate:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              DataTable(
                columns: [
                  DataColumn(label: Text('Rezident')),
                  DataColumn(label: Text('Medicament')),
                  DataColumn(label: Text('Doză')),
                  DataColumn(label: Text('Orar')),
                ],
                rows: medicationReport.map((m) => DataRow(cells: [
                  DataCell(Text(m['Rezident'].toString())),
                  DataCell(Text(m['Medicament'].toString())),
                  DataCell(Text(m['Doză'].toString())),
                  DataCell(Text(m['Orar'].toString())),
                ])).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
