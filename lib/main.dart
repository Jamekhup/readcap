import 'package:flutter/material.dart';
import 'features/recorder/presentation/recorder_screen.dart';
import 'shared/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ReadcapApp());
}

class ReadcapApp extends StatelessWidget {
  const ReadcapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Readcap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RecorderScreen(),
    );
  }
}
