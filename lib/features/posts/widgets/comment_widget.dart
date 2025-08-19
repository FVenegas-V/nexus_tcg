import 'package:flutter/material.dart';
import '../../../core/models/comment.dart';
import '../../../core/utils/time_formatter.dart';

/// Widget individual para mostrar un comentario con threading visual
/// Incluye autor, contenido, metadatos, reacciones y acciones
class CommentWidget extends StatefulWidget {
  final Comment comment;
  final Function(String)? onReact;
  final VoidCallback? onReply;
  final Function(String)? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final bool showThreadIndicator;

  const CommentWidget({
    super.key,
    required this.comment,
    this.onReact,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onTap,
    this.showThreadIndicator = true,
  });

  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  bool _isEditing = false;
  late TextEditingController _editController;
  bool _showActions = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.comment.content);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Card(
          elevation: widget.comment.threadLevel > 0 ? 1 : 2,
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con autor y metadata
                  _buildCommentHeader(context),

                  const SizedBox(height: 8),

                  // Contenido del comentario
                  _buildCommentContent(context),

                  const SizedBox(height: 8),

                  // Reacciones si las hay
                  if (widget.comment.reactionsCount > 0) ...[
                    _buildReactionsSection(context),
                    const SizedBox(height: 8),
                  ],

                  // Acciones (responder, editar, eliminar)
                  _buildCommentActions(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentHeader(BuildContext context) {
    return Row(
      children: [
        // Indicador de threading
        if (widget.showThreadIndicator && widget.comment.threadLevel > 0)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              widget.comment.levelIndicator,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        // Avatar del autor
        CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: widget.comment.authorAvatarUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.comment.authorAvatarUrl!,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultAvatar(context);
                    },
                  ),
                )
              : _buildDefaultAvatar(context),
        ),

        const SizedBox(width: 12),

        // Información del autor
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.comment.authorUsername,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // Badge de nivel de thread si es mayor a 0
                  if (widget.comment.threadLevel > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Nivel ${widget.comment.threadLevel}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              Text(
                TimeFormatter.formatRelativeTime(widget.comment.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Botón de más opciones
        if (widget.comment.canEdit || widget.comment.canDelete)
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () {
              setState(() {
                _showActions = !_showActions;
              });
            },
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return Text(
      widget.comment.authorUsername.isNotEmpty
          ? widget.comment.authorUsername[0].toUpperCase()
          : 'U',
      style: TextStyle(
        color: Theme.of(context).colorScheme.onPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }

  Widget _buildCommentContent(BuildContext context) {
    if (widget.comment.isDeleted) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.delete_outline,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Este comentario ha sido eliminado',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (_isEditing) {
      return _buildEditingContent(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.comment.content,
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        // Indicador de edición si fue editado
        if (widget.comment.updatedAt.isAfter(
          widget.comment.createdAt.add(const Duration(minutes: 1)),
        )) ...[
          const SizedBox(height: 4),
          Text(
            'Editado',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEditingContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de edición
        TextField(
          controller: _editController,
          maxLines: null,
          decoration: InputDecoration(
            hintText: 'Editar comentario...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(12),
          ),
          autofocus: true,
        ),

        const SizedBox(height: 8),

        // Tiempo restante para editar
        if (widget.comment.canBeEdited) ...[
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Puedes editar por ${widget.comment.editTimeRemainingMinutes} minutos más',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Botones de guardar/cancelar
        Row(
          children: [
            TextButton(onPressed: _cancelEdit, child: const Text('Cancelar')),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _saveEdit, child: const Text('Guardar')),
          ],
        ),
      ],
    );
  }

  Widget _buildReactionsSection(BuildContext context) {
    // Versión simplificada para comentarios
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.comment.reactionsCount}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          // Mostrar tipos de reacciones si hay breakdown
          if (widget.comment.reactionsBreakdown.isNotEmpty) ...[
            const SizedBox(width: 8),
            ...widget.comment.reactionsBreakdown.entries
                .where((entry) => entry.value > 0)
                .take(3) // Mostrar solo las primeras 3
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      _getEmojiForReaction(entry.key),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  /// Convierte el tipo de reacción a emoji
  String _getEmojiForReaction(String reactionType) {
    switch (reactionType.toLowerCase()) {
      case 'like':
        return '👍';
      case 'love':
        return '❤️';
      case 'laugh':
        return '😂';
      case 'wow':
        return '😮';
      case 'sad':
        return '😢';
      case 'angry':
        return '😡';
      default:
        return '👍';
    }
  }

  Widget _buildCommentActions(BuildContext context) {
    if (widget.comment.isDeleted) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Acciones principales
        Row(
          children: [
            // Botón de responder
            if (widget.onReply != null && widget.comment.canHaveReplies)
              TextButton.icon(
                onPressed: widget.onReply,
                icon: const Icon(Icons.reply, size: 16),
                label: const Text('Responder'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),

            const Spacer(),

            // Contador de reacciones si las hay
            if (widget.comment.reactionsCount > 0)
              TextButton.icon(
                onPressed: () {
                  // TODO: Mostrar breakdown de reacciones
                },
                icon: const Icon(Icons.favorite, size: 16),
                label: Text('${widget.comment.reactionsCount}'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
          ],
        ),

        // Acciones extendidas (si están visibles)
        if (_showActions) ...[
          const Divider(height: 16),
          Row(
            children: [
              if (widget.comment.canBeEdited && widget.onEdit != null)
                TextButton.icon(
                  onPressed: _startEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Editar'),
                ),

              if (widget.comment.canDelete && widget.onDelete != null) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Eliminar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  void _startEdit() {
    setState(() {
      _isEditing = true;
      _showActions = false;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _editController.text = widget.comment.content;
    });
  }

  void _saveEdit() {
    final newContent = _editController.text.trim();

    if (newContent.isEmpty) {
      return;
    }

    if (newContent != widget.comment.content && widget.onEdit != null) {
      widget.onEdit!(newContent);
    }

    setState(() {
      _isEditing = false;
    });
  }
}
