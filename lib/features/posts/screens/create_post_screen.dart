import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/post.dart';
import '../../../core/models/post_image.dart';
import '../providers/posts_provider.dart';
import '../widgets/image_picker_widget.dart';

/// Pantalla para crear un nuevo post
/// Permite agregar texto e imágenes para una comunidad específica
class CreatePostScreen extends StatefulWidget {
  final int preselectedCommunityId;

  const CreatePostScreen({super.key, required this.preselectedCommunityId});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _contentFocusNode = FocusNode();

  List<File> _selectedImages = [];
  bool _isLoading = false;

  // Constantes de validación
  static const int _minContentLength = 10;
  static const int _maxContentLength = 1000;
  static const int _maxImages = 5;
  static const int _maxImageSizeMB = 5;

  @override
  void initState() {
    super.initState();
    // Auto-focus en el campo de texto al abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  /// Valida el contenido del post
  String? _validateContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El contenido no puede estar vacío';
    }

    final trimmed = value.trim();
    if (trimmed.length < _minContentLength) {
      return 'El contenido debe tener al menos $_minContentLength caracteres';
    }

    if (trimmed.length > _maxContentLength) {
      return 'El contenido no puede exceder $_maxContentLength caracteres';
    }

    return null;
  }

  /// Simula la publicación del post
  Future<void> _publishPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Crear el request para el post
      final createRequest = CreatePostRequest(
        title: '', // Por ahora sin título, solo contenido
        content: _contentController.text.trim(),
        communityId: widget.preselectedCommunityId,
      );

      // Crear post usando PostsProvider
      final postsProvider = context.read<PostsProvider>();
      final createdPost = await postsProvider.createPost(createRequest);

      if (createdPost != null) {
        debugPrint('✅ Post creado exitosamente: ${createdPost.id}');

        // Si hay imágenes, subirlas
        if (_selectedImages.isNotEmpty) {
          debugPrint('📸 Subiendo ${_selectedImages.length} imágenes...');

          try {
            final imageUploadRequest = ImageUploadRequest(
              postId: createdPost.id,
              imagePaths: _selectedImages.map((file) => file.path).toList(),
            );

            final uploadSuccess = await postsProvider.uploadImages(
              imageUploadRequest,
            );

            if (uploadSuccess) {
              debugPrint('✅ Todas las imágenes subidas exitosamente');
            } else {
              debugPrint('⚠️ Algunas imágenes no se pudieron subir');
              // Mostrar mensaje al usuario pero no fallar
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Algunas imágenes no se pudieron subir'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('❌ Error subiendo imágenes: $e');
            // Mostrar mensaje al usuario pero no fallar
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error al subir las imágenes'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('¡Post publicado exitosamente!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Navegar de vuelta al feed con resultado exitoso
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } else {
        throw Exception('No se pudo crear el post');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al publicar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Maneja el cambio en las imágenes seleccionadas
  void _onImagesChanged(List<File> images) {
    setState(() {
      _selectedImages = images;
    });
  }

  /// Muestra diálogo de confirmación para descartar
  Future<bool> _showDiscardDialog() async {
    // Si no hay contenido, no mostrar diálogo
    if (_contentController.text.trim().isEmpty && _selectedImages.isEmpty) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¿Descartar post?'),
          content: const Text(
            'Tienes cambios sin guardar. ¿Estás seguro de que quieres salir?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Descartar',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _showDiscardDialog();
          if (shouldPop && mounted) {
            // ignore: use_build_context_synchronously
            Navigator.pop(context, false);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Crear post'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final shouldPop = await _showDiscardDialog();
              if (shouldPop && mounted) {
                // ignore: use_build_context_synchronously
                Navigator.pop(context, false);
              }
            },
          ),
          actions: [
            // Botón Publicar
            TextButton(
              onPressed: _isLoading ? null : _publishPost,
              child: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  : Text(
                      'Publicar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color:
                            (_contentController.text.trim().length >=
                                _minContentLength)
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              // Contenido scrolleable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campo de contenido
                      Text(
                        'Contenido',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _contentController,
                        focusNode: _contentFocusNode,
                        maxLines: 6,
                        maxLength: _maxContentLength,
                        decoration: InputDecoration(
                          hintText: '¿Qué quieres compartir?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          counterText:
                              '${_contentController.text.length}/$_maxContentLength',
                        ),
                        validator: _validateContent,
                        onChanged: (value) {
                          setState(
                            () {},
                          ); // Para actualizar el contador y botón
                        },
                      ),

                      const SizedBox(height: 24),

                      // Selector de imágenes
                      ImagePickerWidget(
                        selectedImages: _selectedImages,
                        onImagesChanged: _onImagesChanged,
                        maxImages: _maxImages,
                        maxSizeInMB: _maxImageSizeMB,
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Preview del post (opcional)
              if (_contentController.text.trim().isNotEmpty ||
                  _selectedImages.isNotEmpty)
                _buildPostPreview(),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye un preview del post
  Widget _buildPostPreview() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del preview
          Row(
            children: [
              Icon(
                Icons.visibility,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Preview',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Contenido del preview
          if (_contentController.text.trim().isNotEmpty)
            Text(
              _contentController.text.trim(),
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

          // Imágenes del preview
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.image,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_selectedImages.length} imagen${_selectedImages.length != 1 ? 'es' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
