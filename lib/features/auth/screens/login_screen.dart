import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/nexus_logo.dart';
import '../providers/auth_provider.dart';
import '../services/validation_service.dart';
import '../widgets/auth_card.dart';
import '../widgets/custom_button.dart';
import '../../posts/providers/posts_provider.dart';
import '../../communities/providers/communities_provider_new.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      username: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      // Limpiar y recargar datos de otros providers después del login exitoso
      try {
        debugPrint(
          '🔄 Iniciando actualización de estado para nuevo usuario...',
        );

        final postsProvider = context.read<PostsProvider>();
        final communitiesProvider = context.read<CommunitiesProvider>();

        // Limpiar el estado anterior
        debugPrint('🧹 Limpiando estado anterior de posts...');
        postsProvider.clear();

        // Recargar las comunidades para el nuevo usuario
        debugPrint('🏠 Recargando comunidades para el nuevo usuario...');
        await communitiesProvider.loadCommunities();

        // Recargar los posts del feed para el nuevo usuario
        debugPrint('📰 Recargando posts del feed para el nuevo usuario...');
        await postsProvider.loadInitialPosts();

        debugPrint('✅ Estado actualizado exitosamente para el nuevo usuario');
      } catch (e) {
        debugPrint('⚠️ Error al actualizar estado: $e');
      }

      // Usar go_router en lugar de Navigator tradicional
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8B1E1E), // Color superior
              Color(0xFFF08A8A), // Color inferior
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Espacio superior
                    const SizedBox(height: 40),
                    const Center(child: NexusLogo(size: 200)),
                    const SizedBox(height: 40),
                    // Tarjeta de login sin logo (ya está arriba)
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return AuthCard(
                          title: 'Bienvenido de nuevo',
                          showLogo: false, // No mostrar logo en la tarjeta
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Email o Username',
                                    hintText: 'Email o Username',
                                  ),
                                  validator: (value) {
                                    return ValidationService.validateLoginField(
                                      value,
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleLogin(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'Password',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) =>
                                      ValidationService.validateRequired(
                                        value,
                                        'La contraseña',
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      print(
                                        '🔄 Intentando navegar a forgot-password',
                                      );
                                      context.go('/forgot-password');
                                      print('✅ Navegación ejecutada');
                                    },
                                    child: Text(
                                      '¿Olvidaste la contraseña?',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (authProvider.errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            authProvider.errorMessage!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.error,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                CustomButton(
                                  text: 'Login',
                                  onPressed: authProvider.isLoading
                                      ? null
                                      : _handleLogin,
                                  isLoading: authProvider.isLoading,
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '¿No tienes cuenta? ',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        authProvider.clearError();
                                        context.go('/register');
                                      },
                                      child: Text(
                                        'Regístrate',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
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
            ),
          ),
        ),
      ),
    );
  }
}
