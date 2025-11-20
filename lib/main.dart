import 'package:flutter/material.dart';
import 'pages/home_page.dart'; // 确保指向你当前的新版 HomePage（含“行情”）

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI 柑橘助手',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFA726),
        ), // orange
        useMaterial3: true,
      ),
      home: const HomePage(), // 只放这一层
    );
  }
}
