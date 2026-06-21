import 'package:flutter/material.dart';
import 'package:rs_iron/rs_iron.dart';

import 'app_module.rs_iron.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize DI container with all dependencies
  await IronCore.initialize((container) {
    container.registerGeneratedDependencies();
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget with IronCore, IronMixin {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'rs_iron Flutter Example',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    routerConfig: routerService.config,
  );
}
