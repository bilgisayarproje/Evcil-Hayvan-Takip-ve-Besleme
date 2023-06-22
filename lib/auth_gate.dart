import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:mamamatik_proje/anasayfa.dart';
import 'package:firebase_database/firebase_database.dart';

FirebaseDatabase database = FirebaseDatabase.instance;

DatabaseReference ref = FirebaseDatabase.instance.ref("users/123");

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  static const String _title = 'Mamamatik';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SignInScreen(
              providerConfigs: [EmailProviderConfiguration()],
            );
          }
          return Scaffold(
            body: Mamamatik(),
          );
        });
  }
}
