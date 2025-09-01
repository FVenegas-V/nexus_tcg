import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../communities/screens/communities_screen_simple.dart';
import '../../home/screens/home_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../core/providers/tab_navigation_provider.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const CommunitiesScreenSimple(),
      const HomeScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TabNavigationProvider>(
      builder: (context, tabProvider, child) {
        return Scaffold(
          body: IndexedStack(
            index: tabProvider.currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: tabProvider.currentIndex,
            onTap: tabProvider.navigateToTab,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.groups),
                label: 'Comunidades',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        );
      },
    );
  }
}
