import 'package:flutter/material.dart';

import '../widgets/trainer/trainer_bottom_nav.dart';
import 'library_screen.dart';
import 'placeholder_screens.dart';
import 'settings_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}
//TODO
//Add smooth transitions, work out a better transition and screen swap effect. 
//Make it look more sleek and custom to the app.

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    LibraryScreen(),
    TrainerPlaceholderScreen(),
    ProgressPlaceholderScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: TrainerBottomNav(
        selectedIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
