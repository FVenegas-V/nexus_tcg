import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/comment.dart';
import '../providers/comments_provider.dart';
import 'comment_widget.dart';
import 'comment_composer_widget.dart';

/// Widget principal para mostrar lista de comentarios con threading visual
/// Soporta 3 niveles de profundidad con indentación progresiva
class CommentsListWidget extends StatefulWidget {
  final int communityId;
  final int postId;
  final bool showComposer;
  final int? maxCommentsToShow;
  final Function(Comment)? onCommentTap;
  final Function(Comment)? onReplyTap;

  const CommentsListWidget({
    super.key,
    required this.communityId,
    required this.postId,
    this.showComposer = true,
    this.maxCommentsToShow,
    this.onCommentTap,
    this.onReplyTap,
  });

  @override
  State<CommentsListWidget> createState() => _CommentsListWidgetState();
}

class _CommentsListWidgetState extends State<CommentsListWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _showComposer = false;
  Comment? _replyingTo;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _loadComments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentsProvider>().loadCommentsByPost(
        widget.communityId,
        widget.postId,
      );
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<CommentsProvider>().loadMoreComments(widget.communityId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommentsProvider>(
      builder: (context, commentsProvider, child) {
        final comments = commentsProvider.getCommentsByPost(widget.postId);
        final isLoading = commentsProvider.isLoading;
        final hasError = commentsProvider.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con contador de comentarios
            _buildCommentsHeader(context, commentsProvider),

            // Lista de comentarios o estados de carga/error
            if (hasError)
              _buildErrorState(context, commentsProvider)
            else if (isLoading && comments.isEmpty)
              _buildLoadingState(context)
            else if (comments.isEmpty)
              _buildEmptyState(context)
            else
              _buildCommentsList(context, comments, commentsProvider),

            // Composer para nuevo comentario
            if (widget.showComposer || _showComposer)
              _buildCommentComposer(context, commentsProvider),
          ],
        );
      },
    );
  }

  Widget _buildCommentsHeader(BuildContext context, CommentsProvider provider) {
    final commentsCount = provider.getCommentsCountByPost(widget.postId);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.comment_outlined,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '$commentsCount comentario${commentsCount != 1 ? 's' : ''}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (!_showComposer && widget.showComposer)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showComposer = true;
                  _replyingTo = null;
                });
              },
              icon: const Icon(Icons.add_comment_outlined, size: 18),
              label: const Text('Comentar'),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(
    BuildContext context,
    List<Comment> comments,
    CommentsProvider provider,
  ) {
    final displayComments = widget.maxCommentsToShow != null
        ? comments.take(widget.maxCommentsToShow!).toList()
        : comments;

    return ListView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayComments.length + (provider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < displayComments.length) {
          return _buildCommentWithReplies(
            context,
            displayComments[index],
            provider,
          );
        }

        // Loading indicator para más comentarios
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildCommentWithReplies(
    BuildContext context,
    Comment comment,
    CommentsProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comentario principal
        CommentWidget(
          comment: comment,
          onReact: (reactionType) {
            provider.reactToComment(comment.id, reactionType);
          },
          onReply: () {
            _startReply(comment);
          },
          onEdit: comment.canBeEdited
              ? (newContent) {
                  provider.updateComment(
                    widget.communityId,
                    comment.id,
                    newContent,
                    postId: widget.postId,
                  );
                }
              : null,
          onDelete: comment.canDelete
              ? () {
                  _deleteComment(context, provider, comment);
                }
              : null,
          onTap: widget.onCommentTap != null
              ? () => widget.onCommentTap!(comment)
              : null,
        ),

        // Respuestas anidadas
        if (comment.replies.isNotEmpty)
          _buildRepliesList(context, comment.replies, provider),

        // Composer para responder a este comentario
        if (_replyingTo?.id == comment.id)
          Padding(
            padding: EdgeInsets.only(
              left: _getIndentationForLevel(comment.threadLevel + 1),
              top: 8,
            ),
            child: _buildReplyComposer(context, provider, comment),
          ),
      ],
    );
  }

  Widget _buildRepliesList(
    BuildContext context,
    List<Comment> replies,
    CommentsProvider provider,
  ) {
    return Column(
      children: replies.map((reply) {
        return Padding(
          padding: EdgeInsets.only(
            left: _getIndentationForLevel(reply.threadLevel),
          ),
          child: Column(
            children: [
              CommentWidget(
                comment: reply,
                onReact: (reactionType) {
                  provider.reactToComment(reply.id, reactionType);
                },
                onReply: reply.canHaveReplies
                    ? () {
                        _startReply(reply);
                      }
                    : null,
                onEdit: reply.canBeEdited
                    ? (newContent) {
                        provider.updateComment(
                          widget.communityId,
                          reply.id,
                          newContent,
                          postId: widget.postId,
                        );
                      }
                    : null,
                onDelete: reply.canDelete
                    ? () {
                        _deleteComment(context, provider, reply);
                      }
                    : null,
                onTap: widget.onReplyTap != null
                    ? () => widget.onReplyTap!(reply)
                    : null,
              ),

              // Respuestas anidadas (hasta 3 niveles)
              if (reply.replies.isNotEmpty)
                _buildRepliesList(context, reply.replies, provider),

              // Composer para responder a esta respuesta
              if (_replyingTo?.id == reply.id)
                Padding(
                  padding: EdgeInsets.only(
                    left: _getIndentationForLevel(reply.threadLevel + 1),
                    top: 8,
                  ),
                  child: _buildReplyComposer(context, provider, reply),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCommentComposer(
    BuildContext context,
    CommentsProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CommentComposerWidget(
        hintText: 'Escribe un comentario...',
        isLoading: provider.isCreating,
        onSubmit: (content) async {
          final success = await provider.createComment(
            widget.communityId,
            widget.postId,
            content,
          );

          if (success != null && mounted) {
            setState(() {
              _showComposer = false;
            });
          }
        },
        onCancel: () {
          setState(() {
            _showComposer = false;
          });
        },
      ),
    );
  }

  Widget _buildReplyComposer(
    BuildContext context,
    CommentsProvider provider,
    Comment parentComment,
  ) {
    return CommentComposerWidget(
      hintText: 'Responder a ${parentComment.authorUsername}...',
      isLoading: provider.isCreating,
      parentComment: parentComment,
      onSubmit: (content) async {
        final success = await provider.replyToComment(
          widget.communityId,
          widget.postId,
          parentComment.id,
          content,
        );

        if (success != null && mounted) {
          setState(() {
            _replyingTo = null;
          });
        }
      },
      onCancel: () {
        setState(() {
          _replyingTo = null;
        });
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando comentarios...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, CommentsProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar comentarios',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'Error desconocido',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadComments,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.comment_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay comentarios aún',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sé el primero en comentar',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.showComposer) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showComposer = true;
                    _replyingTo = null;
                  });
                },
                icon: const Icon(Icons.add_comment),
                label: const Text('Escribir comentario'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startReply(Comment comment) {
    setState(() {
      _replyingTo = comment;
      _showComposer = false;
    });
  }

  void _deleteComment(
    BuildContext context,
    CommentsProvider provider,
    Comment comment,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este comentario? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await provider.deleteComment(
                widget.communityId,
                comment.id,
                postId: widget.postId,
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  /// Calcula la indentación para cada nivel de threading
  double _getIndentationForLevel(int level) {
    switch (level) {
      case 0:
        return 0;
      case 1:
        return 24;
      case 2:
        return 48;
      default:
        return 48; // Máximo 3 niveles
    }
  }
}
