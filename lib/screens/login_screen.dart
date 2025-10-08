import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLogin = true;
  bool isFamily = true;
  final codeController = TextEditingController();
  String error = '';

  Future<void> handleAuth() async {
    try {
      if (isLogin) {
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        
        // Verifică dacă documentul utilizatorului există
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
        
        if (!userDoc.exists) {
          // Creează un document implicit pentru utilizator dacă nu există
          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'email': emailController.text.trim(),
            'role': 'staff', // rol implicit
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      } else {
        // Doar familie/apartinator poate crea cont
        final code = codeController.text.trim();
        final codeSnap = await FirebaseFirestore.instance
            .collection('family_codes')
            .where('code', isEqualTo: code)
            .limit(1)
            .get();
        if (codeSnap.docs.isEmpty) {
          setState(() { error = 'Codul introdus nu este valid!'; });
          return;
        }
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        // Salvează asocierea familie-pacient
        final user = FirebaseAuth.instance.currentUser;
        final patientId = codeSnap.docs.first['patientId'];
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'email': user.email,
          'role': 'family',
          'patientId': patientId,
          'createdAt': DateTime.now().toIso8601String(),
        });
        // Marchează codul ca folosit (opțional)
        // await codeSnap.docs.first.reference.update({'used': true});
        setState(() { error = 'Cont creat cu succes!'; });
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen()),
      );
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 380),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 12,
              shadowColor: Colors.tealAccent,
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo.jpeg',
                      height: 110,
                    ),
                    SizedBox(height: 18),
                    Text(
                      isLogin ? "Autentificare" : "Creare cont",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[800],
                      ),
                    ),
                    SizedBox(height: 24),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.teal[25],
                      ),
                    ),
                    SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Parolă",
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.teal[25],
                      ),
                      onSubmitted: (_) => handleAuth(),
                    ),
                    SizedBox(height: 14),
                    if (!isLogin) ...[
                      TextField(
                        controller: codeController,
                        decoration: InputDecoration(
                          labelText: "Cod unic pacient",
                          prefixIcon: Icon(Icons.vpn_key),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          filled: true,
                          fillColor: Colors.teal[25],
                        ),
                      ),
                      SizedBox(height: 14),
                    ],
                    if (error.isNotEmpty)
                      Text(error, style: TextStyle(color: Colors.red)),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: handleAuth,
                      icon: Icon(Icons.login),
                      label: Text(isLogin ? "Intră în cont" : "Creează cont"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isLogin = !isLogin;
                          error = '';
                        });
                      },
                      child: Text(
                        isLogin
                            ? "Nu ai cont? Creează unul"
                            : "Ai deja cont? Autentifică-te",
                        style: TextStyle(color: Colors.teal[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
