import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Widget para seleccionar y mostrar imágenes
/// Permite seleccionar múltiples imágenes de galería o cámara
/// Incluye preview con opción de eliminar imágenes individuales
class ImagePickerWidget extends StatefulWidget {
  final List<File> selectedImages;
  final ValueChanged<List<File>> onImagesChanged;
  final int maxImages;
  final int maxSizeInMB;

  const ImagePickerWidget({
    super.key,
    required this.selectedImages,
    required this.onImagesChanged,
    this.maxImages = 5,
    this.maxSizeInMB = 5,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();

  /// Selecciona imágenes de la galería
  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        await _processSelectedImages(images);
      }
    } catch (e) {
      _showError('Error al seleccionar imágenes de la galería');
    }
  }

  /// Toma foto con la cámara
  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        await _processSelectedImages([image]);
      }
    } catch (e) {
      _showError('Error al tomar foto con la cámara');
    }
  }

  /// Procesa las imágenes seleccionadas
  Future<void> _processSelectedImages(List<XFile> newImages) async {
    final List<File> validImages = [];
    final List<File> currentImages = List.from(widget.selectedImages);

    for (final XFile xFile in newImages) {
      // Verificar límite de cantidad
      if (currentImages.length + validImages.length >= widget.maxImages) {
        _showError('Máximo ${widget.maxImages} imágenes permitidas');
        break;
      }

      final File file = File(xFile.path);

      // Verificar tamaño del archivo
      final int fileSizeInBytes = await file.length();
      final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB > widget.maxSizeInMB) {
        _showError('La imagen es muy grande (máximo ${widget.maxSizeInMB}MB)');
        continue;
      }

      validImages.add(file);
    }

    if (validImages.isNotEmpty) {
      final List<File> updatedImages = [...currentImages, ...validImages];
      widget.onImagesChanged(updatedImages);
    }
  }

  /// Elimina una imagen específica
  void _removeImage(int index) {
    final List<File> updatedImages = List.from(widget.selectedImages);
    updatedImages.removeAt(index);
    widget.onImagesChanged(updatedImages);
  }

  /// Muestra diálogo de error
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Muestra opciones de selección de imagen
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seleccionar imagen',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.photo_library),
                      title: const Text('Galería'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickFromGallery();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text('Cámara'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickFromCamera();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con información
        Row(
          children: [
            Text(
              'Imágenes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${widget.selectedImages.length}/${widget.maxImages}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Grid de imágenes seleccionadas + botón agregar
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount:
              widget.selectedImages.length +
              (widget.selectedImages.length < widget.maxImages ? 1 : 0),
          itemBuilder: (context, index) {
            // Imágenes existentes
            if (index < widget.selectedImages.length) {
              return _buildImagePreview(widget.selectedImages[index], index);
            }

            // Botón para agregar nueva imagen
            return _buildAddImageButton();
          },
        ),

        // Ayuda/información
        if (widget.selectedImages.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Toca + para agregar hasta ${widget.maxImages} imágenes (máximo ${widget.maxSizeInMB}MB c/u)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  /// Construye el preview de una imagen con opción de eliminar
  Widget _buildImagePreview(File image, int index) {
    return Stack(
      children: [
        // Imagen
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              image,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Botón eliminar
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  /// Construye el botón para agregar nueva imagen
  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              'Agregar',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
