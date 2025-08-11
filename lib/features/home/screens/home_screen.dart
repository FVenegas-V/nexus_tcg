import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// Pantalla de inicio temporal de la aplicación
/// Muestra información básica del usuario y permite cerrar sesión
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nexus TCG - Inicio'),
        actions: [
          // Botón de cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de bienvenida
            const Icon(Icons.home, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              '¡Bienvenido a Nexus TCG!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Pantalla de inicio temporal',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            // Información del usuario autenticado
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'Estado de Autenticación:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Usuario: ${authProvider.user?['username'] ?? "No disponible"}',
                        ),
                        Text(
                          'Email: ${authProvider.user?['email'] ?? "No disponible"}',
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            await authProvider.logout();
                          },
                          child: const Text('Cerrar Sesión'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
