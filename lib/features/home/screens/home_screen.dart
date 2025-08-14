import 'package:flutter/material.dart';
import '../../posts/screens/feed_screen.dart';

/// Pantalla principal (Feed/Home) - Pantalla central del tab de navegación
/// Ahora delegada al FeedScreen con la implementación completa del feed
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Directamente mostrar el FeedScreen
    return const FeedScreen();
  }
}
