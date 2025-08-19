/// Modelo para PostImage basado en las APIs del backend Fase 3
///
/// Representa una imagen asociada a un post con soporte para:
/// - Múltiples resoluciones (thumbnail, medium, large)
/// - Conversión automática a WebP
/// - Upload múltiple y reordenamiento
/// - Validación exhaustiva con python-magic
class PostImage {
  final int id;
  final int postId;
  final String originalFilename;
  final String filename;
  final int fileSize;
  final String contentType;
  final int width;
  final int height;
  final int order;
  final DateTime uploadedAt;
  final DateTime? processedAt;
  final bool isProcessed;

  // URLs para diferentes resoluciones
  final String originalUrl;
  final String thumbnailUrl;
  final String mediumUrl;
  final String largeUrl;

  // Metadatos adicionales
  final Map<String, dynamic> metadata;

  const PostImage({
    required this.id,
    required this.postId,
    required this.originalFilename,
    required this.filename,
    required this.fileSize,
    required this.contentType,
    required this.width,
    required this.height,
    this.order = 0,
    required this.uploadedAt,
    this.processedAt,
    this.isProcessed = false,
    required this.originalUrl,
    required this.thumbnailUrl,
    required this.mediumUrl,
    required this.largeUrl,
    this.metadata = const {},
  });

  /// Crear PostImage desde JSON (response del backend)
  factory PostImage.fromJson(Map<String, dynamic> json) {
    return PostImage(
      id: json['id'] as int,
      postId: json['post_id'] as int,
      originalFilename: json['original_filename'] as String,
      filename: json['filename'] as String,
      fileSize: json['file_size'] as int,
      contentType: json['content_type'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      order: json['order'] as int? ?? 0,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
      isProcessed: json['is_processed'] as bool? ?? false,
      originalUrl: json['original_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String,
      mediumUrl: json['medium_url'] as String,
      largeUrl: json['large_url'] as String,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : {},
    );
  }

  /// Crear PostImage desde JSON de upload (respuesta simplificada)
  factory PostImage.fromUploadJson(Map<String, dynamic> json) {
    return PostImage(
      id: json['id'] as int,
      postId: 0, // No se proporciona en upload, se asigna después
      originalFilename: json['original_filename'] as String,
      filename:
          json['original_filename'] as String, // Usar original como fallback
      fileSize: ((json['file_size_mb'] as double) * 1024 * 1024).round(),
      contentType: 'image/jpeg', // Fallback - no se proporciona
      width: json['width'] as int,
      height: json['height'] as int,
      order: json['order'] as int? ?? 0,
      uploadedAt: DateTime.parse(json['created_at'] as String),
      processedAt: json['processed'] == true
          ? DateTime.parse(json['created_at'] as String)
          : null,
      isProcessed: json['processed'] as bool? ?? false,
      originalUrl:
          json['thumbnail_url']
              as String, // Por ahora usar thumbnail como original
      thumbnailUrl: json['thumbnail_url'] as String,
      mediumUrl: json['thumbnail_url'] as String, // Fallback
      largeUrl: json['thumbnail_url'] as String, // Fallback
      metadata: {},
    );
  }

  /// Convertir PostImage a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'original_filename': originalFilename,
      'filename': filename,
      'file_size': fileSize,
      'content_type': contentType,
      'width': width,
      'height': height,
      'order': order,
      'uploaded_at': uploadedAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'is_processed': isProcessed,
      'original_url': originalUrl,
      'thumbnail_url': thumbnailUrl,
      'medium_url': mediumUrl,
      'large_url': largeUrl,
      'metadata': metadata,
    };
  }

  /// Crear copia del PostImage con campos modificados
  PostImage copyWith({
    int? id,
    int? postId,
    String? originalFilename,
    String? filename,
    int? fileSize,
    String? contentType,
    int? width,
    int? height,
    int? order,
    DateTime? uploadedAt,
    DateTime? processedAt,
    bool? isProcessed,
    String? originalUrl,
    String? thumbnailUrl,
    String? mediumUrl,
    String? largeUrl,
    Map<String, dynamic>? metadata,
  }) {
    return PostImage(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      originalFilename: originalFilename ?? this.originalFilename,
      filename: filename ?? this.filename,
      fileSize: fileSize ?? this.fileSize,
      contentType: contentType ?? this.contentType,
      width: width ?? this.width,
      height: height ?? this.height,
      order: order ?? this.order,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      processedAt: processedAt ?? this.processedAt,
      isProcessed: isProcessed ?? this.isProcessed,
      originalUrl: originalUrl ?? this.originalUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      mediumUrl: mediumUrl ?? this.mediumUrl,
      largeUrl: largeUrl ?? this.largeUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Obtener la URL más apropiada según el contexto
  String getUrlForResolution(ImageResolution resolution) {
    switch (resolution) {
      case ImageResolution.thumbnail:
        return thumbnailUrl;
      case ImageResolution.medium:
        return mediumUrl;
      case ImageResolution.large:
        return largeUrl;
      case ImageResolution.original:
        return originalUrl;
    }
  }

  /// Obtener aspectRatio de la imagen
  double get aspectRatio => width / height;

  /// Verificar si la imagen está en formato landscape
  bool get isLandscape => width > height;

  /// Verificar si la imagen está en formato portrait
  bool get isPortrait => height > width;

  /// Verificar si la imagen es cuadrada
  bool get isSquare => width == height;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostImage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PostImage{id: $id, filename: $filename, resolution: ${width}x$height, processed: $isProcessed}';
  }
}

/// Enum para especificar la resolución deseada de la imagen
enum ImageResolution {
  thumbnail, // 150x150
  medium, // 800x600
  large, // 1200x900
  original, // Tamaño original
}

/// Clase para upload de múltiples imágenes
class ImageUploadRequest {
  final int postId;
  final List<String> imagePaths;
  final List<int>? orders; // Orden específico para cada imagen

  const ImageUploadRequest({
    required this.postId,
    required this.imagePaths,
    this.orders,
  });

  Map<String, dynamic> toJson() {
    return {'post_id': postId, 'image_paths': imagePaths, 'orders': orders};
  }
}

/// Clase para reordenar imágenes existentes
class ImageReorderRequest {
  final List<int> imageIds;
  final List<int> newOrders;

  const ImageReorderRequest({required this.imageIds, required this.newOrders});

  Map<String, dynamic> toJson() {
    return {'image_ids': imageIds, 'new_orders': newOrders};
  }
}
