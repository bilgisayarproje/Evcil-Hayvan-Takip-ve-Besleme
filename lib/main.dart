import 'package:flutter/material.dart'; //flutter kütüphanesini ekleme
import 'package:firebase_core/firebase_core.dart'; //firebase kütüphanesini ekleme
import 'auth_gate.dart'; //giriş ekranı dosyasını içeri aktarma
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); //flutterın başlatılması
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions
          .currentPlatform); //firebase kullanıma hazır hale getiriliyor
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mamamatik',
      home: AuthGate(),
    );
  }
}
