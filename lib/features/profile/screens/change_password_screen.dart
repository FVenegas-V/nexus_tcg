import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/profile_provider.dart';

/// Pantalla para cambio de contraseña del usuario autenticado
/// Requiere contraseña actual y nueva contraseña con confirmación
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _currentPasswordFocus = FocusNode();
  final _newPasswordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  /// Validar contraseña actual
  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña actual es requerida';
    }
    return null;
  }

  /// Validar nueva contraseña
  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La nueva contraseña es requerida';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (value == _currentPasswordController.text) {
      return 'La nueva contraseña debe ser diferente a la actual';
    }
    return null;
  }

  /// Validar confirmación de contraseña
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu nueva contraseña';
    }
    if (value != _newPasswordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  /// Cambiar contraseña
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );

      final success = await profileProvider.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contraseña cambiada exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Volver a la pantalla anterior
          context.pop();
        } else {
          // Mostrar error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                profileProvider.errorMessage ?? 'Error al cambiar contraseña',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Confirmar salida si hay cambios
  Future<bool> _onWillPop() async {
    // Si hay texto en algún campo, mostrar confirmación
    if (_currentPasswordController.text.isNotEmpty ||
        _newPasswordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty) {
      return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Descartar cambios'),
              content: const Text(
                '¿Estás seguro de que quieres salir sin cambiar la contraseña?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Salir'),
                ),
              ],
            ),
          ) ??
          false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            if (context.mounted) context.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          title: const Text('Cambiar Contraseña'),
          backgroundColor: AppColors.backgroundColor,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                context.pop();
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información de seguridad
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seguridad',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tu nueva contraseña debe tener al menos 8 caracteres y ser diferente a la actual.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Formulario
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Contraseña actual
                        TextFormField(
                          controller: _currentPasswordController,
                          focusNode: _currentPasswordFocus,
                          obscureText: _obscureCurrentPassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Contraseña actual',
                            hintText: 'Ingresa tu contraseña actual',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureCurrentPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureCurrentPassword =
                                      !_obscureCurrentPassword;
                                });
                              },
                            ),
                          ),
                          validator: _validateCurrentPassword,
                          onFieldSubmitted: (_) {
                            FocusScope.of(
                              context,
                            ).requestFocus(_newPasswordFocus);
                          },
                        ),

                        const SizedBox(height: 20),

                        // Nueva contraseña
                        TextFormField(
                          controller: _newPasswordController,
                          focusNode: _newPasswordFocus,
                          obscureText: _obscureNewPassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Nueva contraseña',
                            hintText: 'Ingresa tu nueva contraseña',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNewPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureNewPassword = !_obscureNewPassword;
                                });
                              },
                            ),
                          ),
                          validator: _validateNewPassword,
                          onFieldSubmitted: (_) {
                            FocusScope.of(
                              context,
                            ).requestFocus(_confirmPasswordFocus);
                          },
                        ),

                        const SizedBox(height: 20),

                        // Confirmar nueva contraseña
                        TextFormField(
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocus,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Confirmar nueva contraseña',
                            hintText: 'Confirma tu nueva contraseña',
                            prefixIcon: const Icon(Icons.lock_clock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: _validateConfirmPassword,
                          onFieldSubmitted: (_) => _changePassword(),
                        ),

                        const SizedBox(height: 32),

                        // Botón cambiar contraseña
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Cambiar Contraseña',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Información adicional de seguridad
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.security, color: Colors.amber.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Importante',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Después de cambiar tu contraseña, serás desconectado de todos los dispositivos por seguridad.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
