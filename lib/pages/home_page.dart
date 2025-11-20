import 'package:flutter/material.dart';

import 'camera_page.dart';
import 'market_page.dart'; // <- 新的行情页
import 'fertilizer_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  late final List<Widget> _pages = const [
    CameraPage(),
    MarketPage(), // <- 用行情页替换原来的 WeatherPage
    FertilizerPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 各子页面内部自己有 AppBar，这里不再放全局 AppBar
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_camera_outlined),
            label: '识别',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up), // <- “行情”图标
            label: '行情', // <- 文案从“天气”改为“行情”
          ),
          BottomNavigationBarItem(icon: Icon(Icons.spa_outlined), label: '施肥'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
