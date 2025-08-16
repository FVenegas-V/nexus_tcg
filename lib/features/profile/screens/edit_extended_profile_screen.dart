import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/user_profile_service.dart';
import '../providers/profile_provider.dart';

/// Pantalla para editar el perfil extendido del usuario
/// Incluye biografía, ubicación, juegos favoritos, etc.
class EditExtendedProfileScreen extends StatefulWidget {
  const EditExtendedProfileScreen({super.key});

  @override
  State<EditExtendedProfileScreen> createState() =>
      _EditExtendedProfileScreenState();
}

class _EditExtendedProfileScreenState extends State<EditExtendedProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();

  final _bioFocus = FocusNode();
  final _locationFocus = FocusNode();

  final UserProfileService _userProfileService = UserProfileService();

  bool _isLoading = false;
  bool _hasChanges = false;
  String? _errorMessage;

  UserProfile? _currentProfile;
  String _selectedPlayStyle = '';
  String _selectedExperienceLevel = '';
  List<String> _selectedFavoriteGames = [];

  // Opciones disponibles
  final List<String> _playStyles = ['competitive', 'casual', 'collector'];
  final List<String> _experienceLevels = ['beginner', 'intermediate', 'expert'];
  final List<String> _availableGames = [
    'Magic: The Gathering',
    'Pokémon TCG',
    'Yu-Gi-Oh!',
    'Dragon Ball Super',
    'One Piece',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    // Detectar cambios
    _bioController.addListener(_detectChanges);
    _locationController.addListener(_detectChanges);
  }

  @override
  void dispose() {
    _bioController.dispose();
    _locationController.dispose();
    _bioFocus.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileData = await _userProfileService.getUserProfile();

      if (profileData != null) {
        _currentProfile = UserProfile.fromJson(profileData);

        // Cargar datos en los controladores
        _bioController.text = _currentProfile?.bio ?? '';
        _locationController.text = _currentProfile?.location ?? '';
        _selectedPlayStyle = _currentProfile?.playStyle ?? '';
        _selectedExperienceLevel = _currentProfile?.experienceLevel ?? '';
        _selectedFavoriteGames = List<String>.from(
          _currentProfile?.favoriteGames ?? <String>[],
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar perfil: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _detectChanges() {
    if (_currentProfile == null) return;

    final hasChanges =
        _bioController.text.trim() != (_currentProfile?.bio ?? '') ||
        _locationController.text.trim() != (_currentProfile?.location ?? '') ||
        _selectedPlayStyle != (_currentProfile?.playStyle ?? '') ||
        _selectedExperienceLevel != (_currentProfile?.experienceLevel ?? '') ||
        _selectedFavoriteGames.join(',') !=
            (_currentProfile?.favoriteGames.join(',') ?? '');

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) {
      context.pop();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _userProfileService.updateUserProfile(
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        playStyle: _selectedPlayStyle.isEmpty ? null : _selectedPlayStyle,
        experienceLevel: _selectedExperienceLevel.isEmpty
            ? null
            : _selectedExperienceLevel,
        favoriteGames: _selectedFavoriteGames,
      );

      if (result['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: AppColors.successGreen,
          ),
        );

        // Actualizar el ProfileProvider
        final profileProvider = context.read<ProfileProvider>();
        profileProvider.refresh();

        context.pop();
      } else if (mounted) {
        setState(() {
          _errorMessage = result['message'] ?? 'Error al actualizar perfil';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error de conexión: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text(
          'Tienes cambios sin guardar. ¿Deseas descartarlos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar Perfil Extendido'),
          centerTitle: true,
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Guardar',
                      style: TextStyle(
                        color: _hasChanges ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _currentProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.errorRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.errorRed),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Sección de información personal
            _buildPersonalInfoSection(),

            const SizedBox(height: 24),

            // Sección de preferencias gaming
            _buildGamingPreferencesSection(),

            const SizedBox(height: 24),

            // Sección de juegos favoritos
            _buildFavoriteGamesSection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Campo de biografía
            TextFormField(
              controller: _bioController,
              focusNode: _bioFocus,
              enabled: !_isLoading,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Biografía',
                hintText: 'Cuéntanos sobre ti, tus logros, experiencia...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _locationFocus.requestFocus(),
              validator: (value) {
                if (value != null && value.length > 500) {
                  return 'La biografía no puede exceder 500 caracteres';
                }
                return null;
              },
              onChanged: (_) => _detectChanges(),
            ),

            const SizedBox(height: 16),

            // Campo de ubicación
            TextFormField(
              controller: _locationController,
              focusNode: _locationFocus,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                labelText: 'Ubicación',
                hintText: 'Ciudad, País',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value != null && value.length > 100) {
                  return 'La ubicación no puede exceder 100 caracteres';
                }
                return null;
              },
              onChanged: (_) => _detectChanges(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamingPreferencesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferencias de Juego',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Estilo de juego
            _buildDropdownField(
              label: 'Estilo de Juego',
              value: _selectedPlayStyle,
              items: _playStyles.map((style) {
                return DropdownMenuItem(
                  value: style,
                  child: Text(_formatPlayStyle(style)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPlayStyle = value ?? '';
                });
                _detectChanges();
              },
            ),

            const SizedBox(height: 16),

            // Nivel de experiencia
            _buildDropdownField(
              label: 'Nivel de Experiencia',
              value: _selectedExperienceLevel,
              items: _experienceLevels.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(_formatExperienceLevel(level)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedExperienceLevel = value ?? '';
                });
                _detectChanges();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteGamesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Juegos Favoritos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona hasta 5 juegos',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableGames.map((game) {
                final isSelected = _selectedFavoriteGames.contains(game);
                return FilterChip(
                  label: Text(game),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        if (_selectedFavoriteGames.length < 5) {
                          _selectedFavoriteGames.add(game);
                        }
                      } else {
                        _selectedFavoriteGames.remove(game);
                      }
                    });
                    _detectChanges();
                  },
                  selectedColor: AppColors.primaryRed.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primaryRed,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<String>(
          value: '',
          child: Text(
            'Seleccionar...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        ...items,
      ],
      onChanged: _isLoading ? null : onChanged,
    );
  }

  String _formatPlayStyle(String style) {
    switch (style) {
      case 'competitive':
        return 'Competitivo';
      case 'casual':
        return 'Casual';
      case 'collector':
        return 'Coleccionista';
      default:
        return style;
    }
  }

  String _formatExperienceLevel(String level) {
    switch (level) {
      case 'beginner':
        return 'Principiante';
      case 'intermediate':
        return 'Intermedio';
      case 'expert':
        return 'Experto';
      default:
        return level;
    }
  }
}
