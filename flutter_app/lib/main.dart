import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'services/firebase_options.dart';

export 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (CheckInFirebaseOptions.isConfigured) {
    await Firebase.initializeApp(
      options: CheckInFirebaseOptions.currentPlatform,
    );
  }
  runApp(const CheckInApp());
}
