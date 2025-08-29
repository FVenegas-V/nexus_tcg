import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TestForgotPasswordScreen extends StatelessWidget {
  const TestForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_reset, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Pantalla de Recuperación de Contraseñas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('¡Funcionando correctamente!'),
          ],
        ),
      ),
    );
  }
}
