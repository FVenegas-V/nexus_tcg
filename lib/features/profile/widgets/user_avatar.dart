import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/dialog_service.dart';

/// Widget de avatar de usuario con capacidad de actualización
/// Incluye placeholder y preparación para cambio de imagen
class UserAvatar extends StatefulWidget {
  final String? avatarUrl;
  final String userName;
  final double size;
  final bool isEditable;
  final Function(String?)? onAvatarChanged;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.userName,
    this.size = 120,
    this.isEditable = false,
    this.onAvatarChanged,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  File? _localImageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isEditable ? _showAvatarOptions : null,
      child: Stack(
        children: [
          // Avatar principal
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _getAvatarGradient(),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(child: _buildAvatarContent()),
          ),

          // Indicador de editable
          if (widget.isEditable)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: widget.size * 0.25,
                height: widget.size * 0.25,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: widget.size * 0.12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Construye el contenido del avatar
  Widget _buildAvatarContent() {
    // Si hay una imagen local seleccionada
    if (_localImageFile != null) {
      return Image.file(
        _localImageFile!,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
      );
    }

    // Si hay una URL de avatar
    if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty) {
      return Image.network(
        widget.avatarUrl!,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
        errorBuilder: (context, error, stackTrace) {
          return _buildInitialsAvatar();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          );
        },
      );
    }

    // Avatar por defecto con iniciales
    return _buildInitialsAvatar();
  }

  /// Construye avatar con iniciales del usuario
  Widget _buildInitialsAvatar() {
    final initials = _getInitials(widget.userName);
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(gradient: _getAvatarGradient()),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.size * 0.35,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  /// Obtiene las iniciales del nombre del usuario
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
          .toUpperCase();
    }
  }

  /// Obtiene el gradiente basado en el nombre del usuario
  LinearGradient _getAvatarGradient() {
    // Generar colores basados en el hash del nombre
    final hash = widget.userName.hashCode;
    final hue = (hash % 360).toDouble();

    return LinearGradient(
      colors: [
        HSVColor.fromAHSV(1.0, hue, 0.7, 0.8).toColor(),
        HSVColor.fromAHSV(1.0, hue, 0.9, 0.6).toColor(),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Muestra opciones para cambiar avatar
  void _showAvatarOptions() {
    DialogService.showOptionsBottomSheet(
      context: context,
      title: 'Cambiar Avatar',
      options: [
        BottomSheetOption(
          icon: Icons.camera_alt,
          title: 'Tomar Foto',
          subtitle: 'Usar cámara para nueva foto',
          onTap: () => _pickImage(ImageSource.camera),
        ),
        BottomSheetOption(
          icon: Icons.photo_library,
          title: 'Elegir de Galería',
          subtitle: 'Seleccionar foto existente',
          onTap: () => _pickImage(ImageSource.gallery),
        ),
        if (widget.avatarUrl != null || _localImageFile != null)
          BottomSheetOption(
            icon: Icons.delete,
            title: 'Eliminar Avatar',
            subtitle: 'Usar avatar por defecto',
            onTap: _removeAvatar,
            isDestructive: true,
          ),
      ],
    );
  }

  /// Selecciona imagen desde cámara o galería
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _localImageFile = File(image.path);
        });

        // Notificar cambio
        widget.onAvatarChanged?.call(image.path);

        // Mostrar mensaje informativo
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Avatar actualizado. Próximamente: subida automática',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        DialogService.showErrorDialog(
          context: context,
          title: 'Error',
          content: 'No se pudo seleccionar la imagen. Inténtalo de nuevo.',
        );
      }
    }
  }

  /// Elimina el avatar actual
  void _removeAvatar() {
    DialogService.showConfirmDialog(
      context: context,
      title: 'Eliminar Avatar',
      content: '¿Estás seguro de que quieres eliminar tu avatar?',
      confirmText: 'Eliminar',
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed) {
        setState(() {
          _localImageFile = null;
        });
        widget.onAvatarChanged?.call(null);
      }
    });
  }
}

/// Servicios relacionados con avatares
class AvatarService {
  /// Valida si un archivo de imagen es válido
  static bool isValidImageFile(File file) {
    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
    final fileName = file.path.toLowerCase();
    return allowedExtensions.any((ext) => fileName.endsWith(ext));
  }

  /// Obtiene el tamaño del archivo en MB
  static Future<double> getFileSizeInMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  /// Valida tamaño del archivo (máximo 5MB)
  static Future<bool> isValidFileSize(File file) async {
    final sizeMB = await getFileSizeInMB(file);
    return sizeMB <= 5.0;
  }

  /// Genera un nombre único para el archivo
  static String generateUniqueFileName(int userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'avatar_${userId}_$timestamp.jpg';
  }

  /// TODO: Subir avatar al servidor
  /// Este método será implementado cuando se tenga el endpoint de backend
  static Future<String?> uploadAvatar(File imageFile, int userId) async {
    // TODO: Implementar subida real al servidor
    await Future.delayed(const Duration(seconds: 2)); // Simular subida

    // Por ahora retornamos una URL simulada
    return 'https://api.nexustcg.com/media/avatars/${generateUniqueFileName(userId)}';
  }

  /// TODO: Eliminar avatar del servidor
  static Future<bool> deleteAvatar(String avatarUrl) async {
    // TODO: Implementar eliminación real del servidor
    await Future.delayed(const Duration(seconds: 1)); // Simular eliminación
    return true;
  }
}
