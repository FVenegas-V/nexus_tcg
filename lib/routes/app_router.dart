import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/navigation/screens/main_navigation_screen.dart';
import '../features/communities/screens/community_detail_screen.dart';
import '../features/posts/screens/create_post_screen.dart';
import '../features/posts/screens/post_detail_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/edit_extended_profile_screen.dart';
import '../features/profile/screens/change_password_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/testing/screens/phase2_test_screen.dart';
import '../features/communities/screens/communities_screen_simple.dart';
import '../features/reputation/screens/leaderboard_screen.dart';
import '../features/reputation/screens/reputation_dashboard_screen.dart';
import '../features/reputation/screens/public_profile_screen.dart';
import '../features/reputation/screens/rating_dialog_screen.dart';

/// Configuración del router de la aplicación
/// Maneja la navegación y protección de rutas basada en autenticación
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    // Lógica de redirección para proteger rutas basada en autenticación
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      final isLoggedIn = authProvider.isAuthenticated;
      final isOnAuthPage =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

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
        builder: (context, state) => const MainNavigationScreen(),
      ),
      // Ruta para recuperar contraseña
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // Ruta de prueba para Fase 2 APIs
      GoRoute(
        path: '/phase2-test',
        name: 'phase2-test',
        builder: (context, state) => const Phase2TestScreen(),
      ),
      // Ruta de prueba para Communities APIs
      GoRoute(
        path: '/communities-test',
        name: 'communities-test',
        builder: (context, state) => const CommunitiesScreenSimple(),
      ),
      // Ruta de detalle de comunidad
      GoRoute(
        path: '/community/:id',
        name: 'community-detail',
        builder: (context, state) {
          final communityIdString = state.pathParameters['id'] ?? '0';
          final communityId = int.tryParse(communityIdString) ?? 0;
          return CommunityDetailScreen(communityId: communityId);
        },
      ),
      // Ruta de creación de posts
      GoRoute(
        path: '/create-post',
        name: 'create-post',
        builder: (context, state) {
          final communityIdString = state.uri.queryParameters['communityId'];
          final communityId = communityIdString != null
              ? int.tryParse(communityIdString)
              : null;

          // Si no hay ID de comunidad válido, redirigir al home
          if (communityId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/');
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return CreatePostScreen(preselectedCommunityId: communityId);
        },
      ),
      // Ruta de detalle de posts
      GoRoute(
        path: '/post/:id',
        name: 'post-detail',
        builder: (context, state) {
          final postIdString = state.pathParameters['id'] ?? '0';
          final postId = int.tryParse(postIdString) ?? 0;
          return PostDetailScreen(postId: postId);
        },
      ),
      // Rutas de perfil de usuario
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: '/edit',
            name: 'profile-edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: '/edit-extended',
            name: 'profile-edit-extended',
            builder: (context, state) => const EditExtendedProfileScreen(),
          ),
          GoRoute(
            path: '/change-password',
            name: 'change-password',
            builder: (context, state) => const ChangePasswordScreen(),
          ),
        ],
      ),
      // Ruta de configuración general
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // Rutas del sistema de reputación
      GoRoute(
        path: '/leaderboard',
        name: 'leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/reputation/dashboard',
        name: 'reputation-dashboard',
        builder: (context, state) => const ReputationDashboardScreen(),
      ),
      GoRoute(
        path: '/reputation/user/:userId',
        name: 'public-profile',
        builder: (context, state) {
          final userIdString = state.pathParameters['userId'] ?? '0';
          final userId = int.tryParse(userIdString) ?? 0;
          final username = state.uri.queryParameters['username'] ?? 'Usuario';
          return PublicProfileScreen(userId: userId, username: username);
        },
      ),
      GoRoute(
        path: '/reputation/rate/:userId',
        name: 'rate-user',
        builder: (context, state) {
          final userIdString = state.pathParameters['userId'] ?? '0';
          final userId = int.tryParse(userIdString) ?? 0;
          final username = state.uri.queryParameters['username'] ?? 'Usuario';
          return RatingDialogScreen(
            targetUserId: userId,
            targetUserName: username,
          );
        },
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
