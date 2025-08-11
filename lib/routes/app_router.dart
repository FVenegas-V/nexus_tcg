import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/home/screens/home_screen.dart';

/// Configuración del router de la aplicación
/// Maneja la navegación y protección de rutas basada en autenticación
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    // Lógica de redirección basada en el estado de autenticación
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      final isLoggedIn = authProvider.isAuthenticated;
      final isOnAuthPage =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Si no está logueado y no está en página de auth, ir a login
      if (!isLoggedIn && !isOnAuthPage) {
        return '/login';
      }

      // Si está logueado y está en página de auth, ir a home
      if (isLoggedIn && isOnAuthPage) {
        return '/home';
      }

      return null; // No redireccionar
    },
    // Definición de rutas de la aplicación
    routes: [
      // Ruta de login
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      // Ruta de registro
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Ruta principal (requiere autenticación)
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      // Ruta temporal para recuperar contraseña
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Recuperar Contraseña - Próximamente')),
        ),
      ),
    ],
    // Página de error personalizada para rutas no encontradas
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'La ruta ${state.matchedLocation} no existe',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Ir al Login'),
            ),
          ],
        ),
      ),
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nexus TCG - Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '¡Bienvenido a Nexus TCG!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.user;
                if (user != null) {
                  return Text(
                    'Hola, ${user['username'] ?? 'Usuario'}!',
                    style: Theme.of(context).textTheme.bodyLarge,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<AuthProvider>().logout();
              },
              child: const Text('Cerrar Sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

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
            Icon(Icons.email_outlined, size: 64),
            SizedBox(height: 16),
            Text('Funcionalidad próximamente', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Esta pantalla se implementará en fase7-0005'),
          ],
        ),
      ),
    );
  }
}
