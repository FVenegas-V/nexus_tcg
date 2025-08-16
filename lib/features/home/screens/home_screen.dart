import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../posts/screens/feed_screen.dart';

/// Pantalla principal (Feed/Home) - Pantalla central del tab de navegación
/// Ahora delegada al FeedScreen con la implementación completa del feed
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Directamente mostrar el FeedScreen con botón de prueba temporal
    return Scaffold(
      body: const FeedScreen(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "test_apis_button", // Evitar conflicto de heroes
        onPressed: () => context.push('/communities-test'),
        icon: const Icon(Icons.bug_report),
        label: const Text('Probar APIs'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
