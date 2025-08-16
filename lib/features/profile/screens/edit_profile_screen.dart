import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/profile_provider.dart';
import '../models/user.dart';
import '../services/user_service.dart';

/// Pantalla para editar el perfil del usuario
/// Permite actualizar nombre, apellido y email
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Detectar cambios en los campos
    _firstNameController.addListener(_detectChanges);
    _lastNameController.addListener(_detectChanges);
    _emailController.addListener(_detectChanges);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final profileProvider = context.read<ProfileProvider>();
    final user = profileProvider.user;

    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _emailController.text = user.email;
    }
  }

  void _detectChanges() {
    final profileProvider = context.read<ProfileProvider>();
    final user = profileProvider.user;

    if (user != null) {
      final hasChanges =
          _firstNameController.text.trim() != user.firstName ||
          _lastNameController.text.trim() != user.lastName ||
          _emailController.text.trim() != user.email;

      if (hasChanges != _hasChanges) {
        setState(() {
          _hasChanges = hasChanges;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) {
      context.pop();
      return;
    }

    final profileProvider = context.read<ProfileProvider>();

    final success = await profileProvider.updateProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado exitosamente'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            profileProvider.errorMessage ?? 'Error al actualizar perfil',
          ),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar cambios'),
        content: const Text(
          '¿Estás seguro de que quieres salir sin guardar los cambios?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            // ignore: use_build_context_synchronously
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar Perfil'),
          centerTitle: true,
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          actions: [
            Consumer<ProfileProvider>(
              builder: (context, profileProvider, child) {
                return TextButton(
                  onPressed: profileProvider.isUpdating ? null : _saveProfile,
                  child: profileProvider.isUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Guardar',
                          style: TextStyle(
                            color: _hasChanges ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
        body: Consumer<ProfileProvider>(
          builder: (context, profileProvider, child) {
            if (profileProvider.user == null) {
              return const Center(
                child: Text('No se pudo cargar la información del usuario'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Header con avatar
                    _UserAvatarSection(user: profileProvider.user!),

                    const SizedBox(height: 32),

                    // Formulario de edición
                    _ProfileForm(
                      firstNameController: _firstNameController,
                      lastNameController: _lastNameController,
                      emailController: _emailController,
                      firstNameFocus: _firstNameFocus,
                      lastNameFocus: _lastNameFocus,
                      emailFocus: _emailFocus,
                      isUpdating: profileProvider.isUpdating,
                    ),

                    const SizedBox(height: 32),

                    // Información adicional
                    _AdditionalInfo(user: profileProvider.user!),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Sección del avatar del usuario
class _UserAvatarSection extends StatelessWidget {
  final User user;

  const _UserAvatarSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryRed,
                      AppColors.primaryRed.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryRed.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Botón de editar avatar (para futura implementación)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryOrange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            '@${user.username}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Formulario de edición del perfil
class _ProfileForm extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final FocusNode firstNameFocus;
  final FocusNode lastNameFocus;
  final FocusNode emailFocus;
  final bool isUpdating;

  const _ProfileForm({
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.firstNameFocus,
    required this.lastNameFocus,
    required this.emailFocus,
    required this.isUpdating,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Personal',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 16),

        // Campo de nombre
        TextFormField(
          controller: firstNameController,
          focusNode: firstNameFocus,
          enabled: !isUpdating,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ingresa tu nombre',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => lastNameFocus.requestFocus(),
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isNotEmpty && !UserService.isValidName(trimmed)) {
              return 'Nombre inválido';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Campo de apellido
        TextFormField(
          controller: lastNameController,
          focusNode: lastNameFocus,
          enabled: !isUpdating,
          decoration: const InputDecoration(
            labelText: 'Apellido',
            hintText: 'Ingresa tu apellido',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => emailFocus.requestFocus(),
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isNotEmpty && !UserService.isValidName(trimmed)) {
              return 'Apellido inválido';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Campo de email
        TextFormField(
          controller: emailController,
          focusNode: emailFocus,
          enabled: !isUpdating,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'tu@email.com',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) {
              return 'El email es requerido';
            }
            if (!UserService.isValidEmail(trimmed)) {
              return 'Email inválido';
            }
            return null;
          },
        ),
      ],
    );
  }
}

/// Información adicional no editable
class _AdditionalInfo extends StatelessWidget {
  final User user;

  const _AdditionalInfo({required this.user});

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
              'Información de la Cuenta',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 16),

            _InfoRow(
              icon: Icons.verified_user_outlined,
              label: 'Estado del Email',
              value: user.isEmailVerified ? 'Verificado' : 'No verificado',
              valueColor: user.isEmailVerified
                  ? AppColors.successGreen
                  : AppColors.errorRed,
            ),

            const SizedBox(height: 12),

            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Miembro desde',
              value: _formatDate(user.dateJoined),
            ),

            const SizedBox(height: 12),

            _InfoRow(
              icon: Icons.fingerprint,
              label: 'ID de Usuario',
              value: user.id.toString(),
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
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: valueColor != null ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
