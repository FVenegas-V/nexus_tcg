import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ratings_provider.dart';
import '../models/user_rating.dart';
import '../widgets/rating_stars.dart';

/// Pantalla de diálogo para crear o editar valoraciones
class RatingDialogScreen extends StatefulWidget {
  final int targetUserId;
  final String targetUserName;
  final UserRating? existingRating;
  final bool isReadOnly;

  const RatingDialogScreen({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    this.existingRating,
    this.isReadOnly = false,
  });

  @override
  State<RatingDialogScreen> createState() => _RatingDialogScreenState();
}

class _RatingDialogScreenState extends State<RatingDialogScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _selectedRating = 5;
  String _interactionType = 'general';
  bool _isSubmitting = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _initializeFromExisting();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeFromExisting() {
    if (widget.existingRating != null) {
      _selectedRating = widget.existingRating!.rating;
      _commentController.text = widget.existingRating!.comment ?? '';
      _interactionType = widget.existingRating!.interactionType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildBody(),
            ),
          );
        },
      ),
      bottomNavigationBar: widget.isReadOnly ? null : _buildActionButtons(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        widget.isReadOnly
            ? 'Valoración recibida'
            : widget.existingRating != null
            ? 'Editar valoración'
            : 'Valorar usuario',
      ),
      centerTitle: true,
      elevation: 0,
      actions: widget.isReadOnly
          ? null
          : [
              if (widget.existingRating != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _showDeleteConfirmation,
                  tooltip: 'Eliminar valoración',
                ),
            ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildUserHeader(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildRatingTab(), _buildCommentTab()],
          ),
        ),
        _buildTabBar(),
      ],
    );
  }

  Widget _buildUserHeader() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              widget.targetUserName.isNotEmpty
                  ? widget.targetUserName[0].toUpperCase()
                  : '?',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Valorando a:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  widget.targetUserName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (widget.existingRating != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Editando',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.star_outline), text: 'Puntuación'),
          Tab(icon: Icon(Icons.comment_outlined), text: 'Comentario'),
        ],
      ),
    );
  }

  Widget _buildRatingTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Text(
            '¿Cómo calificarías tu experiencia?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona una puntuación del 1 al 5',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Rating selector grande
          RatingStars(
            rating: _selectedRating.toDouble(),
            starSize: 48,
            onRatingChanged: widget.isReadOnly
                ? null
                : (rating) {
                    setState(() {
                      _selectedRating = rating.round();
                    });
                  },
            allowHalfRating: false,
            spacing: 8,
          ),

          const SizedBox(height: 24),

          // Descripción de la puntuación
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _getRatingDescription(_selectedRating),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getRatingColor(_selectedRating),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _getRatingExplanation(_selectedRating),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Tipo de interacción
          _buildInteractionTypeSelector(),

          const SizedBox(height: 24),

          // Preview de puntuación
          _buildRatingPreview(),
        ],
      ),
    );
  }

  Widget _buildInteractionTypeSelector() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de interacción',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInteractionChip('general', 'General', Icons.handshake),
              _buildInteractionChip('trade', 'Intercambio', Icons.swap_horiz),
              _buildInteractionChip('game', 'Partida', Icons.sports_esports),
              _buildInteractionChip('community', 'Comunidad', Icons.people),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionChip(String type, String label, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = _interactionType == type;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: widget.isReadOnly
          ? null
          : (selected) {
              if (selected) {
                setState(() {
                  _interactionType = type;
                });
              }
            },
    );
  }

  Widget _buildCommentTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comentario adicional',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comparte detalles sobre tu experiencia (opcional)',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _commentController,
              enabled: !widget.isReadOnly,
              maxLines: 6,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Describe tu experiencia con este usuario...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
              validator: (value) {
                if (value != null && value.length > 500) {
                  return 'El comentario no puede exceder 500 caracteres';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Tips para comentarios
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tips para un buen comentario',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._getCommentTips().map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                          Expanded(
                            child: Text(
                              tip,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingPreview() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vista previa',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              RatingStars(
                rating: _selectedRating.toDouble(),
                starSize: 20,
                isInteractive: false,
              ),
              const SizedBox(width: 8),
              Text(
                '$_selectedRating/5',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getInteractionTypeLabel(_interactionType),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _isSubmitting || !_isFormValid()
                    ? null
                    : _submitRating,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.existingRating != null
                            ? 'Actualizar'
                            : 'Enviar valoración',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isFormValid() {
    return _selectedRating > 0;
  }

  Future<void> _submitRating() async {
    if (!_isFormValid()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final ratingsProvider = Provider.of<RatingsProvider>(
        context,
        listen: false,
      );

      if (widget.existingRating != null) {
        // Actualizar valoración existente
        await ratingsProvider.updateRating(
          widget.existingRating!.id,
          rating: _selectedRating,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
        );
      } else {
        // Crear nueva valoración
        await ratingsProvider.rateUser(
          ratedUserId: widget.targetUserId,
          rating: _selectedRating,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
          interactionType: _interactionType,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingRating != null
                  ? 'Valoración actualizada correctamente'
                  : 'Valoración enviada correctamente',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar valoración'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta valoración? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _deleteRating();
    }
  }

  Future<void> _deleteRating() async {
    if (widget.existingRating == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final ratingsProvider = Provider.of<RatingsProvider>(
        context,
        listen: false,
      );
      await ratingsProvider.deleteRating(widget.existingRating!.id);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Valoración eliminada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'Muy negativa';
      case 2:
        return 'Negativa';
      case 3:
        return 'Neutral';
      case 4:
        return 'Positiva';
      case 5:
        return 'Excelente';
      default:
        return 'Sin valoración';
    }
  }

  String _getRatingExplanation(int rating) {
    switch (rating) {
      case 1:
        return 'Experiencia muy decepcionante, múltiples problemas';
      case 2:
        return 'Experiencia por debajo de las expectativas';
      case 3:
        return 'Experiencia normal, sin destacar positiva o negativamente';
      case 4:
        return 'Buena experiencia, recomendable';
      case 5:
        return 'Experiencia excepcional, altamente recomendable';
      default:
        return '';
    }
  }

  String _getInteractionTypeLabel(String type) {
    switch (type) {
      case 'trade':
        return 'Intercambio';
      case 'game':
        return 'Partida';
      case 'community':
        return 'Comunidad';
      case 'general':
      default:
        return 'General';
    }
  }

  Color _getRatingColor(int rating) {
    final theme = Theme.of(context);
    switch (rating) {
      case 1:
      case 2:
        return theme.colorScheme.error;
      case 3:
        return theme.colorScheme.tertiary;
      case 4:
      case 5:
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  List<String> _getCommentTips() {
    return [
      'Sé específico sobre tu experiencia',
      'Menciona aspectos positivos y áreas de mejora',
      'Mantén un tono constructivo y respetuoso',
      'Evita información personal sensible',
      'Enfócate en hechos concretos, no opiniones generales',
    ];
  }
}
