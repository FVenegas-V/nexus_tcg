import 'package:flutter/material.dart';
import '../../../core/models/comment.dart';

/// Widget para componer comentarios y respuestas
/// Incluye validación, preview del comentario padre y estados de carga
class CommentComposerWidget extends StatefulWidget {
  final String hintText;
  final Comment? parentComment;
  final bool isLoading;
  final Function(String) onSubmit;
  final VoidCallback? onCancel;
  final int maxLength;

  const CommentComposerWidget({
    super.key,
    required this.hintText,
    this.parentComment,
    this.isLoading = false,
    required this.onSubmit,
    this.onCancel,
    this.maxLength = 1000,
  });

  @override
  State<CommentComposerWidget> createState() => _CommentComposerWidgetState();
}

class _CommentComposerWidgetState extends State<CommentComposerWidget> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      // Solo para actualizar la UI con el contador de caracteres
    });
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && !_isExpanded) {
      setState(() {
        _isExpanded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview del comentario padre si es una respuesta
          if (widget.parentComment != null) _buildParentCommentPreview(context),

          // Campo de texto principal
          _buildTextInput(context),

          // Acciones (cuando está expandido)
          if (_isExpanded || widget.parentComment != null)
            _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildParentCommentPreview(BuildContext context) {
    final parent = widget.parentComment!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Respondiendo a ${parent.authorUsername}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (widget.onCancel != null)
            SizedBox(
              width: 24,
              height: 24,
              child: IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: widget.onCancel,
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: _isExpanded ? null : 1,
            maxLength: widget.maxLength,
            enabled: !widget.isLoading,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              counterText: _isExpanded
                  ? null
                  : '', // Ocultar contador cuando no está expandido
            ),
            textCapitalization: TextCapitalization.sentences,
          ),

          // Contador de caracteres cuando está expandido
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Spacer(),
                  Text(
                    '${_controller.text.length}/${widget.maxLength}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _controller.text.length > widget.maxLength * 0.9
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;
    final isValid = hasText && _controller.text.length <= widget.maxLength;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Información sobre threading si es respuesta de nivel profundo
          if (widget.parentComment != null &&
              widget.parentComment!.threadLevel >= 1) ...[
            Icon(
              Icons.info_outline,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Nivel ${widget.parentComment!.threadLevel + 1} de threading',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ] else
            const Spacer(),

          // Botones de acción
          if (widget.onCancel != null && widget.parentComment == null) ...[
            TextButton(
              onPressed: widget.isLoading ? null : _cancel,
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
          ],

          // Botón de enviar
          ElevatedButton(
            onPressed: (widget.isLoading || !isValid) ? null : _submit,
            child: widget.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.parentComment != null ? 'Responder' : 'Comentar'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final content = _controller.text.trim();

    if (content.isEmpty || content.length > widget.maxLength) {
      return;
    }

    widget.onSubmit(content);

    // Limpiar el campo después de enviar
    _controller.clear();

    // Colapsar si no es una respuesta
    if (widget.parentComment == null) {
      setState(() {
        _isExpanded = false;
      });
      _focusNode.unfocus();
    }
  }

  void _cancel() {
    _controller.clear();
    setState(() {
      _isExpanded = false;
    });
    _focusNode.unfocus();

    if (widget.onCancel != null) {
      widget.onCancel!();
    }
  }
}

/// Widget simplificado para respuestas rápidas inline
class QuickReplyWidget extends StatefulWidget {
  final String hintText;
  final Function(String) onSubmit;
  final VoidCallback? onCancel;

  const QuickReplyWidget({
    super.key,
    required this.hintText,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<QuickReplyWidget> createState() => _QuickReplyWidgetState();
}

class _QuickReplyWidgetState extends State<QuickReplyWidget> {
  late TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: _submit,
            ),
          ),
          const SizedBox(width: 8),
          if (widget.onCancel != null)
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: widget.onCancel,
                padding: const EdgeInsets.all(4),
              ),
            ),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, size: 20),
              onPressed: _isLoading ? null : () => _submit(_controller.text),
              padding: const EdgeInsets.all(4),
            ),
          ),
        ],
      ),
    );
  }

  void _submit(String content) {
    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    widget.onSubmit(trimmedContent);

    _controller.clear();

    setState(() {
      _isLoading = false;
    });
  }
}
