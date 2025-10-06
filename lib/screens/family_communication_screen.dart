import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'app_drawer.dart';

class FamilyCommunicationScreen extends StatefulWidget {
  final String? residentId;
  const FamilyCommunicationScreen({Key? key, this.residentId}) : super(key: key);
  @override
  State<FamilyCommunicationScreen> createState() => _FamilyCommunicationScreenState();
}

class _FamilyCommunicationScreenState extends State<FamilyCommunicationScreen> {
  String? selectedResidentId;
  String? selectedResidentName;
  final messageController = TextEditingController();
  File? _imageFile;
  bool _sending = false;
  final ImagePicker _picker = ImagePicker();
  String? _lastMessageId;

  @override
  void initState() {
    super.initState();
    // Dacă residentId este furnizat, setează-l ca residentId selectat
    if (widget.residentId != null) {
      setState(() {
        selectedResidentId = widget.residentId;
        // Poți adăuga și o interogare pentru a obține numele rezidentului, dacă este necesar
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File file) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final ref = FirebaseStorage.instance.ref().child('family_attachments/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  void _sendMessage() async {
    if (selectedResidentId == null || (messageController.text.trim().isEmpty && _imageFile == null)) return;
    setState(() { _sending = true; });
    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await _uploadImage(_imageFile!);
    }
    // Determină rolul utilizatorului curent
    final user = await FirebaseFirestore.instance.collection('users').doc(FirebaseFirestore.instance.app.options.projectId).get();
    final isFamily = widget.residentId != null;
    final fromRole = isFamily ? 'family' : 'personal';
    final doc = await FirebaseFirestore.instance.collection('family_messages').add({
      'residentId': selectedResidentId,
      'residentName': selectedResidentName,
      'message': messageController.text.trim(),
      'from': fromRole,
      'timestamp': DateTime.now().toIso8601String(),
      'imageUrl': imageUrl,
      if (fromRole == 'family') 'seenByStaff': false,
    });
    messageController.clear();
    setState(() {
      _imageFile = null;
      _sending = false;
      _lastMessageId = doc.id;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mesaj trimis!')),
    );
  }

  Widget _buildChat({String? residentId}) {
    final String? chatResidentId = residentId ?? selectedResidentId;
    final bool isFamily = widget.residentId != null;
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.teal),
              tooltip: 'Alege alt rezident',
              onPressed: () {
                setState(() {
                  selectedResidentId = null;
                  selectedResidentName = null;
                });
              },
            ),
            Text(selectedResidentName ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('family_messages')
                .where('residentId', isEqualTo: chatResidentId)
                // .orderBy('timestamp', descending: false) // eliminat pentru a evita problemele de index
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Eroare: \\${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              // Sortează mesajele după data și ora trimiterii (timestamp)
              docs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = DateTime.tryParse(aData['timestamp'] ?? '') ?? DateTime(2000);
                final bTime = DateTime.tryParse(bData['timestamp'] ?? '') ?? DateTime(2000);
                return aTime.compareTo(bTime);
              });
              if (docs.isEmpty) return Center(child: Text('Nu există mesaje pentru acest rezident.'));
              // Notificare vizuală la mesaj nou doar pentru staff/admin și doar dacă mesajul e de la familie
              final isStaff = !isFamily;
              if (isStaff && _lastMessageId != null && docs.isNotEmpty && docs.last.id != _lastMessageId) {
                final lastMsgData = docs.last.data() as Map<String, dynamic>;
                if (lastMsgData['from'] == 'family') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Mesaj nou de la familie!')),
                    );
                    _lastMessageId = docs.last.id;
                  });
                } else {
                  _lastMessageId = docs.last.id;
                }
              }
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final date = DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now();
                  final isPersonal = data['from'] == 'personal';
                  final isFamilyMsg = data['from'] == 'family';
                  // Conversație reală: family vede mesajele proprii la dreapta, staff la stânga
                  bool alignRight;
                  Color? bubbleColor;
                  if (isFamily) {
                    alignRight = isFamilyMsg;
                    bubbleColor = isFamilyMsg ? Colors.teal[100] : Colors.orange[100];
                  } else {
                    alignRight = isPersonal;
                    bubbleColor = isPersonal ? Colors.teal[100] : Colors.orange[100];
                  }
                  return Align(
                    alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data['imageUrl'] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Image.network(data['imageUrl'], width: 180, height: 180, fit: BoxFit.cover),
                            ),
                          if ((data['message'] ?? '').isNotEmpty)
                            Row(
                              mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
                              children: [
                                if (!alignRight && isFamilyMsg)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: Icon(Icons.family_restroom, color: Colors.orange, size: 18),
                                  ),
                                Expanded(child: Text(data['message'] ?? '', style: TextStyle(fontSize: 16))),
                              ],
                            ),
                          SizedBox(height: 4),
                          Text(
                            (isFamily && alignRight ? 'Eu · ' : isFamilyMsg ? 'Familie · ' : '') + date.toLocal().toString().substring(0, 16),
                            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
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
        if (_imageFile != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Image.file(_imageFile!, width: 120, height: 120, fit: BoxFit.cover),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () => setState(() => _imageFile = null),
                ),
              ],
            ),
          ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.attach_file, color: Colors.teal),
              tooltip: 'Atașează imagine',
              onPressed: _pickImage,
            ),
            Expanded(
              child: TextField(
                controller: messageController,
                decoration: InputDecoration(
                  labelText: isFamily ? 'Scrie mesajul către personal' : 'Scrie mesajul către familie',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: Colors.teal),
              tooltip: 'Trimite',
              onPressed: _sendMessage,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? filterResidentId = widget.residentId;
    final bool isFamily = widget.residentId != null;
    return Scaffold(
      drawer: widget.residentId != null ? AppDrawer(currentRoute: 'family', isFamily: true, patientId: widget.residentId) : AppDrawer(currentRoute: 'family'),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.phone, color: Colors.white),
            SizedBox(width: 8),
            Text('Comunicare cu familia', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.teal,
        // Fără acțiuni pentru familie
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: selectedResidentId == null && filterResidentId == null
            ? StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('residents').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  final docs = snapshot.data!.docs;
                  return ListView(
                    children: [
                      Card(
                        color: Colors.teal[50],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 6,
                        margin: EdgeInsets.only(bottom: 18),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              Icon(Icons.family_restroom, color: Colors.teal, size: 36),
                              SizedBox(width: 16),
                              Text('Selectează un rezident pentru a deschide conversația:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[900])),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      ...docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Card(
                          child: ListTile(
                            leading: Icon(Icons.person, color: Colors.teal),
                            title: Text(data['name'] ?? ''),
                            onTap: () {
                              setState(() {
                                selectedResidentId = doc.id;
                                selectedResidentName = data['name'];
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              )
            : _buildChat(residentId: filterResidentId ?? selectedResidentId),
      ),
    );
  }
}
