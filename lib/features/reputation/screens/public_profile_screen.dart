import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/reputation_stats.dart';
import '../models/user_rating.dart';
import '../providers/reputation_provider.dart';
import '../providers/ratings_provider.dart';
import '../widgets/anti_gaming_indicator.dart';
import '../widgets/rating_list_item.dart';
import '../widgets/reputation_chart.dart';
import '../../../core/services/user_profile_service.dart';
import '../../auth/services/auth_service.dart';
import 'rating_dialog_screen.dart';

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
    print('🎯 INICIO _loadUserData para usuario ${widget.userId}');

    final reputationProvider = Provider.of<ReputationProvider>(
      context,
      listen: false,
    );

    final ratingsProvider = Provider.of<RatingsProvider>(
      context,
      listen: false,
    );

    // Obtener token de autenticación y inicializar servicios
    try {
      final token = await AuthService.getAccessToken();
      if (token != null) {
        ratingsProvider.initialize(token);
        print('🔐 RatingsProvider inicializado con token: SÍ');
      } else {
        print('⚠️ No hay token disponible');
      }
    } catch (e) {
      print('! Error obteniendo token para RatingsProvider: $e');
      // Intentar renovar el token si es posible
      try {
        final refreshResult = await AuthService.refreshAccessToken();
        if (refreshResult['success']) {
          final newToken = await AuthService.getAccessToken();
          if (newToken != null) {
            ratingsProvider.initialize(newToken);
            print('🔐 RatingsProvider inicializado con token renovado: SÍ');
          }
        }
      } catch (refreshError) {
        print('❌ Error renovando token: $refreshError');
      }
    }

    // Cargar estadísticas de reputación
    reputationProvider.getReputationStats(widget.userId);

    // Cargar valoraciones recibidas del usuario
    print(
      '🔄 Cargando valoraciones recibidas para usuario ${widget.userId}...',
    );
    await ratingsProvider.getReceivedRatings(widget.userId, pageSize: 5);
    print(
      '✅ Finalizada carga de valoraciones recibidas para usuario ${widget.userId}',
    );

    // Cargar perfil del usuario
    await _loadUserProfile();

    print('🎯 FIN _loadUserData para usuario ${widget.userId}');
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoadingProfile = true);

      print('🚀 Cargando perfil público del usuario ${widget.userId}...');

      final userProfileService = UserProfileService();
      final profile = await userProfileService.getPublicUserProfile(
        widget.userId,
      );

      print('📦 Perfil público obtenido: $profile');

      setState(() {
        _userProfile = profile;
        _isLoadingProfile = false;
      });
    } catch (e) {
      print('🚨 Error cargando perfil: $e');

      // Si el error es de autenticación, intentar renovar el token
      if (e.toString().contains('401') ||
          e.toString().contains('No autorizado')) {
        print(
          '🔄 Detectado error de autenticación, intentando renovar token...',
        );
        try {
          final refreshResult = await AuthService.refreshAccessToken();
          if (refreshResult['success']) {
            print('✅ Token renovado, reintentando cargar perfil...');
            // Reintentar cargar el perfil con el nuevo token
            final userProfileService = UserProfileService();
            final profile = await userProfileService.getPublicUserProfile(
              widget.userId,
            );

            setState(() {
              _userProfile = profile;
              _isLoadingProfile = false;
            });
            return; // Éxito, salir sin mostrar error
          }
        } catch (refreshError) {
          print('❌ Error renovando token: $refreshError');
        }
      }

      setState(() => _isLoadingProfile = false);

      // Mostrar mensaje de error al usuario
      if (mounted) {
        _showErrorMessage(
          'Error al cargar el perfil. Verifica tu conexión e inténtalo nuevamente.',
        );
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Reintentar',
          textColor: Colors.white,
          onPressed: () => _loadUserData(),
        ),
      ),
    );
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
        print('🎯 DEBUG: getCachedReputationStats for userId ${widget.userId}');
        print('🎯 DEBUG: stats = $stats');
        print('🎯 DEBUG: stats?.totalScore = ${stats?.totalScore}');
        print('🎯 DEBUG: stats?.ratingsCount = ${stats?.ratingsCount}');
        print('🎯 DEBUG: stats?.averageRating = ${stats?.averageRating}');

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
                const SizedBox(height: 16),
                _buildReputationStars(stats),
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
                  const SizedBox(height: 8),
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

  Widget _buildReputationStars(ReputationStats stats) {
    final theme = Theme.of(context);

    // DEBUG: Imprimir valores para diagnóstico
    print('🐛 DEBUG Reputation Stars:');
    print('   totalScore: ${stats.totalScore}');
    print('   ratingsCount: ${stats.ratingsCount}');
    print('   averageRating: ${stats.averageRating}');

    // FIX: Usar directamente averageRating que ya está en escala 1-5
    final starRating = stats.averageRating.clamp(0.0, 5.0);
    print('   starRating calculado (FIXED): $starRating');

    final fullStars = starRating.floor();
    final hasHalfStar = (starRating - fullStars) >= 0.5;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...List.generate(5, (index) {
              if (index < fullStars) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.star, color: Colors.amber, size: 28),
                );
              } else if (index == fullStars && hasHalfStar) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.star_half, color: Colors.amber, size: 28),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.star_border,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                    size: 28,
                  ),
                );
              }
            }),
            const SizedBox(width: 12),
            Text(
              '${starRating.toStringAsFixed(1)}/5',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
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

    if (_userProfile == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Información Personal',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Este usuario no ha configurado su perfil público',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Extraer datos del perfil
    final profile = _userProfile!['profile'] as Map<String, dynamic>?;
    final user = _userProfile!['user'] as Map<String, dynamic>?;

    final bio = profile?['bio'] as String?;
    final location = profile?['location'] as String?;
    final createdAt = user?['created_at'] as String?;
    final firstName = user?['first_name'] as String?;
    final lastName = user?['last_name'] as String?;

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

            // Nombre completo
            if (firstName?.isNotEmpty == true ||
                lastName?.isNotEmpty == true) ...[
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${firstName ?? ''} ${lastName ?? ''}'.trim(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Biografía
            if (bio?.isNotEmpty == true) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.description,
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

            // Ubicación
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

            // Fecha de registro
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

            // Mensaje si no hay información personal
            if (bio?.isEmpty != false &&
                location?.isEmpty != false &&
                firstName?.isEmpty != false &&
                lastName?.isEmpty != false) ...[
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este usuario no ha compartido información personal',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
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
            'Valoraciones',
            '${stats.ratingsCount}',
            subtitle: 'total',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, {String? subtitle}) {
    final theme = Theme.of(context);

    // Determinar si es la tarjeta de nivel para usar un tamaño de texto más pequeño
    final isLevelCard = label == 'Nivel';

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
              style: isLevelCard
                  ? theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    )
                  : theme.textTheme.headlineSmall?.copyWith(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Distribución de Valoraciones',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            // Aumentamos la altura y mejoramos el contenedor
            Container(
              height: 220,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ReputationChart(
                stats: stats,
                type: ChartType.bar,
                height: 220,
                showLegend: false,
                animate: true,
              ),
            ),
            const SizedBox(height: 16),
            // Mejoramos el diseño de las estadísticas
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildChartStat(
                    'Total',
                    stats.ratingsCount > 0 ? '${stats.ratingsCount}' : '0',
                    Icons.star_border,
                    theme.colorScheme.primary,
                  ),
                  _buildVerticalDivider(theme),
                  _buildChartStat(
                    'Promedio',
                    stats.ratingsCount > 0
                        ? '${stats.averageRating.toStringAsFixed(1)} ⭐'
                        : '-',
                    Icons.trending_up,
                    theme.colorScheme.secondary,
                  ),
                  _buildVerticalDivider(theme),
                  _buildChartStat(
                    'Puntuación',
                    stats.ratingsCount > 0
                        ? '${stats.totalScore.toStringAsFixed(1)}'
                        : '0.0',
                    Icons.emoji_events,
                    theme.colorScheme.tertiary,
                  ),
                ],
              ),
            ),
            // Agregar mensaje informativo si no hay valoraciones
            if (stats.ratingsCount == 0) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Aún no hay valoraciones para mostrar',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider(ThemeData theme) {
    return Container(
      height: 40,
      width: 1,
      color: theme.colorScheme.outline.withOpacity(0.3),
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
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final ratings =
                    ratingsProvider.getCachedReceivedRatings(widget.userId) ??
                    [];
                if (ratings.isEmpty) {
                  return _buildEmptyRatingsState();
                }

                return Column(
                  children: ratings.take(3).map((rating) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: RatingListItem(
                          rating: rating,
                          onTap: () => _showRatingDetails(rating),
                          onReport: () => _reportRating(rating),
                        ),
                      ),
                    );
                  }).toList(),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.star_border,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Este usuario aún no ha recibido valoraciones',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
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
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(
                  maxHeight: 400,
                  maxWidth: 500,
                ),
                child: SingleChildScrollView(
                  child: RatingListItem(
                    rating: rating,
                    showAvatar: true,
                    expandComment: true,
                  ),
                ),
              ),
            ],
          ),
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

  void _showRatingDialog() async {
    if (_userProfile != null) {
      final user = _userProfile!['user'] as Map<String, dynamic>?;
      final username =
          user?['username'] as String? ?? widget.username ?? 'Usuario';

      print('🎯 DEBUG Rating Dialog: username = $username');
      print('🎯 DEBUG Rating Dialog: _userProfile user = $user');

      // Verificar si ya existe una valoración para este usuario
      try {
        final ratingsProvider = Provider.of<RatingsProvider>(
          context,
          listen: false,
        );

        // Asegurar que el ratings provider esté inicializado
        final token = await AuthService.getAccessToken();
        if (token != null) {
          ratingsProvider.initialize(token);
        }

        final existingRatingResult = await ratingsProvider
            .getExistingRatingForUser(widget.userId);

        if (!existingRatingResult.isSuccess) {
          _showErrorMessage(
            'Error al verificar valoraciones existentes: ${existingRatingResult.error}',
          );
          return;
        }

        final existingRating = existingRatingResult.data;

        if (existingRating != null) {
          // El usuario ya valoró a este usuario
          _showExistingRatingDialog(existingRating, username);
        } else {
          // No hay valoración previa, mostrar diálogo normal
          _showNewRatingDialog(username);
        }
      } catch (e) {
        print('❌ Error verificando valoración existente: $e');
        _showErrorMessage('Error al verificar valoraciones: $e');
      }
    }
  }

  void _showExistingRatingDialog(UserRating existingRating, String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Valoración existente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ya has valorado a $username anteriormente:'),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Valoración: '),
                ...List.generate(5, (index) {
                  return Icon(
                    index < existingRating.rating
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
                Text(' (${existingRating.rating}/5)'),
              ],
            ),
            if (existingRating.comment != null &&
                existingRating.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Comentario: "${existingRating.comment}"'),
            ],
            const SizedBox(height: 8),
            Text('Fecha: ${_formatTime(existingRating.createdAt)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showUpdateRatingDialog(existingRating, username);
            },
            child: const Text('Actualizar valoración'),
          ),
        ],
      ),
    );
  }

  void _showNewRatingDialog(String username) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => RatingDialogScreen(
              targetUserId: widget.userId,
              targetUserName: username,
            ),
          ),
        )
        .then((_) {
          // Refrescar datos después de calificar
          _loadUserData();
        });
  }

  void _showUpdateRatingDialog(UserRating existingRating, String username) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => RatingDialogScreen(
              targetUserId: widget.userId,
              targetUserName: username,
              existingRating: existingRating,
            ),
          ),
        )
        .then((_) {
          // Refrescar datos después de actualizar la calificación
          _loadUserData();
        });
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'hace un momento';
    }
  }

  /// Widget para mostrar una estadística pequeña en el gráfico
  Widget _buildChartStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
