import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/reputation_stats.dart';
import '../models/user_rating.dart';
import '../providers/reputation_provider.dart';
import '../providers/ratings_provider.dart';
import '../widgets/reputation_chart.dart';
import '../widgets/anti_gaming_indicator.dart';
import '../widgets/rating_list_item.dart';
import '../../../core/services/user_profile_service.dart';

/// Pantalla simplificada del perfil público de un usuario
class PublicProfileScreen extends StatefulWidget {
  final int userId;
  final String? username;

  const PublicProfileScreen({super.key, required this.userId, this.username});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    final reputationProvider = Provider.of<ReputationProvider>(
      context,
      listen: false,
    );

    // Cargar estadísticas de reputación
    reputationProvider.getReputationStats(widget.userId);

    // Cargar perfil del usuario
    await _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoadingProfile = true);

      final userProfileService = UserProfileService();
      final profile = await userProfileService.getUserProfile();

      setState(() {
        _userProfile = profile;
        _isLoadingProfile = false;
      });
    } catch (e) {
      print('🚨 Error cargando perfil: $e');
      setState(() => _isLoadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildRateUserButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      title: Consumer<ReputationProvider>(
        builder: (context, provider, child) {
          final cachedUsername = provider.getCachedUsername(widget.userId);
          return Text(
            cachedUsername ?? widget.username ?? 'Usuario #${widget.userId}',
          );
        },
      ),
      actions: [
        IconButton(icon: const Icon(Icons.share), onPressed: _shareProfile),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer<ReputationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = provider.getCachedReputationStats(widget.userId);
        if (stats == null) {
          return _buildErrorState();
        }

        return RefreshIndicator(
          onRefresh: _loadUserData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserInfo(stats),
                const SizedBox(height: 24),
                _buildUserBio(),
                const SizedBox(height: 24),
                _buildQuickStats(stats),
                const SizedBox(height: 24),
                _buildReputationChart(stats),
                const SizedBox(height: 24),
                _buildRatingsSection(),
                const SizedBox(height: 100), // Espacio para el FAB
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfo(ReputationStats stats) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                widget.username?.isNotEmpty == true
                    ? widget.username![0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.username ?? 'Usuario #${widget.userId}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        stats.level.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        stats.level.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AntiGamingIndicator(
                    status: stats.antiGamingStatus,
                    style: AntiGamingDisplayStyle.chip,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBio() {
    if (_isLoadingProfile) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final bio = _userProfile?['bio'] as String?;
    final location = _userProfile?['location'] as String?;
    final createdAt = _userProfile?['created_at'] as String?;

    if (bio?.isEmpty != false && location?.isEmpty != false) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Personal',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (bio?.isNotEmpty == true) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.person,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(bio!, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (location?.isNotEmpty == true) ...[
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(location!, style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (createdAt != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Miembro desde ${_formatDate(createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre',
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildQuickStats(ReputationStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Reputación',
            '${stats.totalScore.toStringAsFixed(1)}',
            subtitle: stats.scoreChange != null
                ? '${stats.scoreChange! >= 0 ? '+' : ''}${stats.scoreChange!.toStringAsFixed(1)}'
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Valoraciones',
            '${stats.ratingsCount}',
            subtitle: 'total',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Nivel',
            '${stats.level.name}',
            subtitle: stats.level.displayName,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, {String? subtitle}) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReputationChart(ReputationStats stats) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evolución de Reputación',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ReputationChart(
                stats: stats,
                type: ChartType.line,
                height: 200,
                showLegend: false,
                animate: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Valoraciones Recientes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Consumer<RatingsProvider>(
              builder: (context, ratingsProvider, child) {
                if (ratingsProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final ratings =
                    ratingsProvider.getCachedReceivedRatings(widget.userId) ??
                    [];
                if (ratings.isEmpty) {
                  return _buildEmptyRatingsState();
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ratings.take(5).length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final rating = ratings[index];
                    return RatingListItem(
                      rating: rating,
                      onTap: () => _showRatingDetails(rating),
                      onReport: () => _reportRating(rating),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48),
            SizedBox(height: 16),
            Text('Error al cargar el perfil'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRatingsState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.star_border, size: 48),
            SizedBox(height: 16),
            Text('Este usuario aún no ha recibido valoraciones'),
          ],
        ),
      ),
    );
  }

  Widget _buildRateUserButton() {
    return FloatingActionButton.extended(
      onPressed: _showRatingDialog,
      icon: const Icon(Icons.star),
      label: const Text('Valorar'),
    );
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad de compartir en desarrollo')),
    );
  }

  void _showRatingDetails(UserRating rating) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Valoración de ${rating.raterUsername}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RatingListItem(
              rating: rating,
              showAvatar: false,
              expandComment: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _reportRating(UserRating rating) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar Valoración'),
        content: const Text('¿Por qué quieres reportar esta valoración?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Valoración reportada')),
              );
            },
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de valoración en desarrollo'),
      ),
    );
  }
}
