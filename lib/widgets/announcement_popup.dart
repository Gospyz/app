import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementPopup extends StatefulWidget {
  const AnnouncementPopup({Key? key}) : super(key: key);

  @override
  State<AnnouncementPopup> createState() => _AnnouncementPopupState();
}

class _AnnouncementPopupState extends State<AnnouncementPopup> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return SizedBox.shrink();
        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        if (data['shown'] == true) return SizedBox.shrink();
        return FutureBuilder(
          future: Future.delayed(Duration(milliseconds: 500)),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return SizedBox.shrink();
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(data['title'] ?? 'Anunț'),
                  content: Text(data['body'] ?? ''),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('announcements').doc(doc.id).update({'shown': true});
                        Navigator.pop(context);
                      },
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            });
            return SizedBox.shrink();
          },
        );
      },
    );
  }
}
