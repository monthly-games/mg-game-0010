import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/shop_manager.dart';
import 'shop_tab.dart';
import 'crafting_tab.dart';
import 'package:mg_common_game/systems/settings/settings_manager.dart';
import 'package:mg_common_game/core/ui/screens/settings_screen.dart' as common;
import 'package:get_it/get_it.dart';
import 'dungeon_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    ShopTab(),
    CraftingTab(),
    DungeonTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('던전 샵 시뮬레이터'),
        actions: [
          // 골드 표시
          Consumer<ShopManager>(
            builder: (context, shop, _) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${shop.gold}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => common.SettingsScreen(
                    settingsManager: GetIt.I<SettingsManager>(),
                    title: 'Settings',
                    accentColor: const Color(0xFF8B4513),
                    onClose: () => Navigator.of(context).pop(),
                    version: '1.0.0',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: '상점',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: '제작',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.terrain),
            label: '던전',
          ),
        ],
      ),
    );
  }
}
