import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/dialog_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../models/user.dart';
import '../widgets/user_avatar.dart';

/// Pantalla principal del perfil de usuario
/// Muestra la información del usuario y opciones de configuración
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  void _loadProfile() {
    final profileProvider = context.read<ProfileProvider>();
    final authProvider = context.read<AuthProvider>();

    // Si no hay datos en el ProfileProvider pero sí en AuthProvider,
    // inicializar con los datos de AuthProvider
    if (!profileProvider.hasUser && authProvider.user != null) {
      profileProvider.updateUserFromData(authProvider.user!);
    } else if (!profileProvider.hasUser) {
      // Si no hay datos en ningún lado, cargar desde la API
      profileProvider.loadUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings');
            },
            tooltip: 'Configuración',
          ),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading) {
            return const _LoadingView();
          }

          if (profileProvider.hasError) {
            return _ErrorView(
              message: profileProvider.errorMessage ?? 'Error desconocido',
              onRetry: () => profileProvider.loadUserProfile(),
            );
          }

          if (!profileProvider.hasUser) {
            return const _EmptyView();
          }

          return _ProfileContent(user: profileProvider.user!);
        },
      ),
    );
  }
}

/// Vista de contenido principal del perfil
class _ProfileContent extends StatelessWidget {
  final User user;

  const _ProfileContent({required this.user});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<ProfileProvider>().refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Avatar y nombre
            _UserHeader(user: user),

            const SizedBox(height: 32),

            // Información del usuario
            _UserInfoCard(user: user),

            const SizedBox(height: 24),

            // Opciones de perfil
            _ProfileOptionsCard(),

            const SizedBox(height: 24),

            // Opciones de cuenta
            _AccountOptionsCard(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Header con avatar y nombre del usuario
class _UserHeader extends StatelessWidget {
  final User user;

  const _UserHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar circular con funcionalidad de edición
        UserAvatar(
          avatarUrl: user.avatar,
          userName: user.fullName.isNotEmpty ? user.fullName : user.username,
          size: 120,
          isEditable:
              false, // TODO: Habilitar cuando esté implementado el upload
          onAvatarChanged: (newAvatarPath) {
            // TODO: Implementar actualización de avatar
            debugPrint('Avatar cambiado: $newAvatarPath');
          },
        ),

        const SizedBox(height: 16),

        // Nombre del usuario
        Text(
          user.fullName.isNotEmpty ? user.fullName : user.username,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 4),

        // Username
        if (user.fullName.isNotEmpty)
          Text(
            '@${user.username}',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
      ],
    );
  }
}

/// Tarjeta con información del usuario
class _UserInfoCard extends StatelessWidget {
  final User user;

  const _UserInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Personal',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 16),

            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email,
              trailing: user.isEmailVerified
                  ? const Icon(Icons.verified, color: Colors.green, size: 20)
                  : const Icon(Icons.warning, color: Colors.orange, size: 20),
            ),

            const SizedBox(height: 12),

            _InfoRow(
              icon: Icons.person_outline,
              label: 'Nombre',
              value: user.firstName.isNotEmpty
                  ? user.firstName
                  : 'No especificado',
            ),

            const SizedBox(height: 12),

            _InfoRow(
              icon: Icons.person_outline,
              label: 'Apellido',
              value: user.lastName.isNotEmpty
                  ? user.lastName
                  : 'No especificado',
            ),

            const SizedBox(height: 12),

            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Miembro desde',
              value: _formatDate(user.dateJoined),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}

/// Fila de información
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Tarjeta con opciones de perfil
class _ProfileOptionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _OptionTile(
            icon: Icons.edit_outlined,
            title: 'Editar Perfil',
            subtitle: 'Actualizar información personal',
            onTap: () => context.push('/profile/edit'),
          ),

          const Divider(height: 1),

          _OptionTile(
            icon: Icons.lock_outline,
            title: 'Cambiar Contraseña',
            subtitle: 'Actualizar tu contraseña de acceso',
            onTap: () => context.push('/profile/change-password'),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con opciones de cuenta
class _AccountOptionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _OptionTile(
            icon: Icons.logout,
            title: 'Cerrar Sesión',
            subtitle: 'Salir de tu cuenta',
            onTap: () => _showLogoutDialog(context),
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    DialogService.showLogoutConfirmDialog(context).then((confirmed) {
      if (confirmed) {
        _logout(context);
      }
    });
  }

  void _logout(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();

    authProvider.logout();
    profileProvider.clear();

    context.go('/auth/login');
  }
}

/// Tile de opción clickeable
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryRed, size: 24),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

/// Vista de carga
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando perfil...'),
        ],
      ),
    );
  }
}

/// Vista de error
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error al cargar el perfil',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista vacía
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No se pudo cargar la información del perfil'),
        ],
      ),
    );
  }
}
