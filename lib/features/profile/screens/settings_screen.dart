import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/dialog_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Pantalla de configuraciones de la aplicación
/// Incluye configuraciones de notificaciones, tema, información de la app
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = false;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: AppColors.backgroundColor,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Sección de Notificaciones
            _SettingsSection(
              title: 'Notificaciones',
              icon: Icons.notifications_outlined,
              children: [
                _SwitchTile(
                  title: 'Notificaciones',
                  subtitle: 'Recibir notificaciones de la aplicación',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                      if (!value) {
                        _pushNotificationsEnabled = false;
                        _emailNotificationsEnabled = false;
                      }
                    });
                  },
                ),
                _SwitchTile(
                  title: 'Notificaciones Push',
                  subtitle: 'Notificaciones en tiempo real',
                  value: _pushNotificationsEnabled,
                  enabled: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _pushNotificationsEnabled = value;
                    });
                  },
                ),
                _SwitchTile(
                  title: 'Notificaciones por Email',
                  subtitle: 'Recibir emails sobre actividad importante',
                  value: _emailNotificationsEnabled,
                  enabled: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _emailNotificationsEnabled = value;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sección de Apariencia
            _SettingsSection(
              title: 'Apariencia',
              icon: Icons.palette_outlined,
              children: [
                _SwitchTile(
                  title: 'Tema Oscuro',
                  subtitle: 'Usar tema oscuro en la aplicación',
                  value: _darkModeEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                    // Implementar cambio de tema básico
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _darkModeEnabled
                                ? 'Tema oscuro activado'
                                : 'Tema claro activado',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sección de Cuenta
            _SettingsSection(
              title: 'Cuenta',
              icon: Icons.account_circle_outlined,
              children: [
                _OptionTile(
                  icon: Icons.person_outline,
                  title: 'Mi Perfil',
                  subtitle: 'Ver y editar información personal',
                  onTap: () => context.push('/profile'),
                ),
                _OptionTile(
                  icon: Icons.lock_outline,
                  title: 'Cambiar Contraseña',
                  subtitle: 'Actualizar contraseña de acceso',
                  onTap: () => context.push('/profile/change-password'),
                ),
                _OptionTile(
                  icon: Icons.logout,
                  title: 'Cerrar Sesión',
                  subtitle: 'Salir de la aplicación',
                  onTap: () => _showLogoutDialog(context),
                  isDestructive: true,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sección de Información
            _SettingsSection(
              title: 'Información',
              icon: Icons.info_outlined,
              children: [
                _OptionTile(
                  icon: Icons.description_outlined,
                  title: 'Términos y Condiciones',
                  subtitle: 'Leer términos de uso',
                  onTap: () => _showInfoDialog(
                    context,
                    'Términos y Condiciones',
                    'Próximamente: Términos y condiciones completos de Nexus TCG.',
                  ),
                ),
                _OptionTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Política de Privacidad',
                  subtitle: 'Información sobre privacidad',
                  onTap: () => _showInfoDialog(
                    context,
                    'Política de Privacidad',
                    'Próximamente: Política de privacidad detallada.',
                  ),
                ),
                _OptionTile(
                  icon: Icons.help_outline,
                  title: 'Ayuda y Soporte',
                  subtitle: 'Obtener ayuda',
                  onTap: () => _showInfoDialog(
                    context,
                    'Ayuda y Soporte',
                    'Para obtener ayuda, contacta a nuestro equipo de soporte:\n\nEmail: soporte@nexustcg.com\nTelefono: +56 9 1234 5678',
                  ),
                ),
                _OptionTile(
                  icon: Icons.info,
                  title: 'Acerca de Nexus TCG',
                  subtitle: 'Versión 1.0.0',
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) async {
    final confirmed = await DialogService.showLogoutConfirmDialog(context);
    if (confirmed && context.mounted) {
      if (context.mounted) {
        Provider.of<AuthProvider>(context, listen: false).logout();
      }
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    DialogService.showInfoDialog(
      context: context,
      title: title,
      content: content,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Nexus TCG',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryRed, AppColors.secondaryOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
      ),
      children: [
        const Text(
          'Nexus TCG es la plataforma definitiva para jugadores de Trading Card Games.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Conecta con otros jugadores, comparte cartas, organiza eventos y mucho más.',
        ),
        const SizedBox(height: 16),
        const Text('Desarrollado con Flutter y Django REST Framework.'),
      ],
    );
  }
}

/// Widget para sección de configuraciones
class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryRed, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// Widget para opciones con switch
class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: enabled ? AppColors.textPrimary : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: enabled ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeColor: AppColors.primaryRed,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

/// Widget para opciones de navegación
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : AppColors.textPrimary;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: color),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDestructive ? Colors.red[300] : Colors.grey[600],
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
