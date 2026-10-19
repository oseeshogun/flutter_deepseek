import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/chat_screen.dart';
import 'theme/studio_theme.dart';

/// LinkedIn / demo capture overlays (badge + code strip + compact layout).
const _recordMode = bool.fromEnvironment('RECORD_MODE');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: StudioColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const StudioDemoApp());
}

class StudioDemoApp extends StatelessWidget {
  const StudioDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_deepseek Studio',
      debugShowCheckedModeBanner: false,
      theme: buildStudioTheme(),
      home: const ChatScreen(initialRecordMode: _recordMode),
    );
  }
}
