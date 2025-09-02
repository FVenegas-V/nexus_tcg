// lib/screens/notifications/notification_preferences_screen.dart

import 'package:flutter/material.dart';
import '../../core/models/notification_preferences_model.dart';
import '../../core/services/notification_preferences_service.dart';

/// Pantalla de configuración de preferencias de notificaciones
/// Fase 5-0005: UI para configurar preferencias de usuario
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final NotificationPreferencesService _service =
      NotificationPreferencesService();

  NotificationPreferencesModel? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final preferences = await _service.getPreferences();

      setState(() {
        _preferences = preferences;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePreference(String field, dynamic value) async {
    if (_preferences == null) return;

    try {
      setState(() {
        _isSaving = true;
      });

      final updatedPreferences = await _service.updateSinglePreference(
        field,
        value,
        _preferences!,
      );

      setState(() {
        _preferences = updatedPreferences;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferencia actualizada'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _resetToDefaults() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar configuración'),
        content: const Text(
          '¿Estás seguro de que quieres restaurar todas las preferencias a los valores por defecto?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (shouldReset != true) return;

    try {
      setState(() {
        _isSaving = true;
      });

      final defaultPreferences = await _service.resetToDefaults();

      setState(() {
        _preferences = defaultPreferences;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferencias restauradas a valores por defecto'),
        ),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferencias de Notificaciones'),
        actions: [
          if (_preferences != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'reset':
                    _resetToDefaults();
                    break;
                  case 'refresh':
                    _loadPreferences();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'reset',
                  child: ListTile(
                    leading: Icon(Icons.restore),
                    title: Text('Restaurar defaults'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'refresh',
                  child: ListTile(
                    leading: Icon(Icons.refresh),
                    title: Text('Actualizar'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando preferencias...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error cargando preferencias',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPreferences,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_preferences == null) {
      return const Center(
        child: Text('No se pudieron cargar las preferencias'),
      );
    }

    return Stack(
      children: [
        _buildPreferencesList(),
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Guardando cambios...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreferencesList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Configuración de Notificaciones',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Personaliza qué notificaciones quieres recibir y cómo.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Notificaciones in-app
        _buildSectionCard(
          title: 'Notificaciones en la App',
          subtitle: 'Estas notificaciones aparecen cuando usas la aplicación',
          icon: Icons.phone_android,
          children: [
            _buildSwitchTile(
              title: 'Nuevas publicaciones',
              subtitle:
                  'Notificaciones cuando hay nuevos posts en tus comunidades',
              value: _preferences!.appNewPosts,
              onChanged: (value) => _updatePreference('app_new_posts', value),
            ),
            _buildSwitchTile(
              title: 'Nuevos comentarios',
              subtitle: 'Cuando alguien comenta en tus publicaciones',
              value: _preferences!.appNewComments,
              onChanged: (value) =>
                  _updatePreference('app_new_comments', value),
            ),
            _buildSwitchTile(
              title: 'Respuestas a comentarios',
              subtitle: 'Cuando alguien responde a tus comentarios',
              value: _preferences!.appCommentReplies,
              onChanged: (value) =>
                  _updatePreference('app_comment_replies', value),
            ),
            _buildSwitchTile(
              title: 'Nuevas valoraciones',
              subtitle: 'Cuando recibes valoraciones de reputación',
              value: _preferences!.appNewRatings,
              onChanged: (value) => _updatePreference('app_new_ratings', value),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Notificaciones por email
        _buildSectionCard(
          title: 'Notificaciones por Email',
          subtitle: 'Emails enviados a tu dirección de correo',
          icon: Icons.email_outlined,
          children: [
            _buildSwitchTile(
              title: 'Valoraciones importantes',
              subtitle: 'Emails por valoraciones significativas de reputación',
              value: _preferences!.emailNewRatings,
              onChanged: (value) =>
                  _updatePreference('email_new_ratings', value),
            ),
            _buildSwitchTile(
              title: 'Comentarios importantes',
              subtitle: 'Emails por comentarios destacados en tus posts',
              value: _preferences!.emailImportantComments,
              onChanged: (value) =>
                  _updatePreference('email_important_comments', value),
            ),
            _buildSwitchTile(
              title: 'Resumen semanal',
              subtitle: 'Email con resumen de actividad semanal',
              value: _preferences!.emailWeeklySummary,
              onChanged: (value) =>
                  _updatePreference('email_weekly_summary', value),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Configuración de frecuencia
        _buildSectionCard(
          title: 'Frecuencia de Emails',
          subtitle: 'Con qué frecuencia recibir emails de resumen',
          icon: Icons.schedule,
          children: [_buildFrequencyTile()],
        ),

        const SizedBox(height: 16),

        // Información adicional
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Información',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Los cambios se guardan automáticamente\n'
                  '• Las notificaciones in-app son más inmediatas\n'
                  '• Los emails te mantienen al día cuando no usas la app\n'
                  '• Puedes cambiar estas preferencias en cualquier momento',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                if (_preferences!.updatedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Última actualización: ${_preferences!.updatedAt!.toLocal().toString().split('.')[0]}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
      ),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildFrequencyTile() {
    return ListTile(
      title: const Text('Frecuencia de resúmenes'),
      subtitle: Text(_preferences!.summaryFrequencyDisplayName),
      trailing: const Icon(Icons.arrow_forward_ios),
      contentPadding: EdgeInsets.zero,
      onTap: () => _showFrequencyDialog(),
    );
  }

  Future<void> _showFrequencyDialog() async {
    final selectedFrequency = await showDialog<FrequencyOption>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frecuencia de emails'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: FrequencyOption.values
              .map(
                (option) => RadioListTile<FrequencyOption>(
                  title: Text(option.displayName),
                  value: option,
                  groupValue: FrequencyOption.fromValue(
                    _preferences!.summaryFrequency,
                  ),
                  onChanged: (value) => Navigator.of(context).pop(value),
                  contentPadding: EdgeInsets.zero,
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (selectedFrequency != null) {
      await _updatePreference('summary_frequency', selectedFrequency.value);
    }
  }
}
