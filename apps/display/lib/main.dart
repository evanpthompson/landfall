import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:display/src/data/local/app_database.dart';
import 'package:display/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape — the display is always a TV or monitor.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide system UI chrome for an immersive ambient display.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final database = AppDatabase();
  runApp(LandfallApp(database: database));
}
