from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils import timezone
import uuid
from datetime import timedelta

class User(AbstractUser):
    """
    Modelo de usuario personalizado para Nexus TCG
    """
    email = models.EmailField(unique=True)
    email_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Campos de reputación (Fase 4.3)
    reputation_score = models.DecimalField(
        max_digits=4, 
        decimal_places=2, 
        default=0.00,
        help_text="Puntuación de reputación calculada (0.00-5.00)"
    )
    reputation_count = models.IntegerField(
        default=0,
        help_text="Número total de valoraciones recibidas activas"
    )
    
    # Usar email como campo de autenticación principal
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']
    
    def __str__(self):
        return self.email

class PasswordResetToken(models.Model):
    """
    Modelo para tokens de recuperación de contraseña
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='password_reset_tokens')
    token = models.UUIDField(default=uuid.uuid4, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    used_at = models.DateTimeField(null=True, blank=True)
    expires_at = models.DateTimeField()
    
    class Meta:
        ordering = ['-created_at']
    
    def save(self, *args, **kwargs):
        if not self.expires_at:
            # Token válido por 1 hora
            self.expires_at = timezone.now() + timedelta(hours=1)
        super().save(*args, **kwargs)
    
    def is_valid(self):
        """
        Verifica si el token es válido (no usado y no expirado)
        """
        return (
            self.used_at is None and 
            timezone.now() < self.expires_at
        )
    
    def mark_as_used(self):
        """
        Marca el token como usado
        """
        self.used_at = timezone.now()
        self.save()


class EmailVerificationToken(models.Model):
    """
    Modelo para tokens de verificación de email
    """
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='email_verification_token')
    token = models.UUIDField(default=uuid.uuid4, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    used_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = "Email Verification Token"
        verbose_name_plural = "Email Verification Tokens"
    
    def save(self, *args, **kwargs):
        if not self.expires_at:
            # Token válido por 24 horas (más tiempo que password reset)
            self.expires_at = timezone.now() + timedelta(hours=24)
        super().save(*args, **kwargs)
    
    def is_valid(self):
        """
        Verifica si el token es válido (no usado y no expirado)
        """
        return (
            self.used_at is None and 
            timezone.now() < self.expires_at
        )
    
    def mark_as_used(self):
        """
        Marca el token como usado y verifica el email del usuario
        """
        self.used_at = timezone.now()
        self.user.email_verified = True
        self.user.save()
        self.save()
    
    def __str__(self):
        return f"Email verification token for {self.user.email}"


class UserProfile(models.Model):
    """
    Modelo de perfil público de usuario para Nexus TCG
    Extiende el modelo User base con información adicional y configuraciones de privacidad
    """
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    
    # Información pública
    bio = models.TextField(max_length=500, blank=True, help_text="Biografía del usuario (máximo 500 caracteres)")
    location = models.CharField(max_length=100, blank=True, help_text="Ubicación del usuario")
    birth_date = models.DateField(null=True, blank=True, help_text="Fecha de nacimiento")
    
    # Gaming preferences
    favorite_games = models.JSONField(default=list, blank=True, help_text="Lista de juegos favoritos")
    play_style = models.CharField(
        max_length=50, 
        blank=True,
        choices=[
            ('competitive', 'Competitivo'),
            ('casual', 'Casual'),
            ('collector', 'Coleccionista'),
            ('trader', 'Intercambiador'),
            ('content_creator', 'Creador de Contenido'),
        ],
        help_text="Estilo de juego preferido"
    )
    experience_level = models.CharField(
        max_length=20,
        blank=True,
        choices=[
            ('beginner', 'Principiante'),
            ('intermediate', 'Intermedio'),
            ('advanced', 'Avanzado'),
            ('expert', 'Experto'),
        ],
        help_text="Nivel de experiencia en TCGs"
    )
    
    # Personalización visual
    avatar_url = models.URLField(blank=True, null=True, help_text="URL del avatar del usuario")
    banner_url = models.URLField(blank=True, null=True, help_text="URL del banner del perfil")
    theme_preference = models.CharField(
        max_length=20,
        default='system',
        choices=[
            ('light', 'Claro'),
            ('dark', 'Oscuro'),
            ('system', 'Sistema'),
        ],
        help_text="Preferencia de tema visual"
    )
    
    # Configuraciones de privacidad
    show_email = models.BooleanField(default=False, help_text="Mostrar email públicamente")
    show_location = models.BooleanField(default=True, help_text="Mostrar ubicación públicamente")
    show_birth_date = models.BooleanField(default=False, help_text="Mostrar fecha de nacimiento públicamente")
    show_communities = models.BooleanField(default=True, help_text="Mostrar comunidades públicamente")
    show_activity_stats = models.BooleanField(default=True, help_text="Mostrar estadísticas de actividad públicamente")
    
    # Estadísticas (calculadas/cached)
    communities_count = models.IntegerField(default=0, help_text="Número de comunidades en las que participa")
    posts_count = models.IntegerField(default=0, help_text="Número total de publicaciones")
    likes_received = models.IntegerField(default=0, help_text="Número total de likes recibidos")
    reputation_score = models.IntegerField(default=0, help_text="Puntuación de reputación (para Fase 4)")
    
    # Metadatos
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = "User Profile"
        verbose_name_plural = "User Profiles"
    
    def __str__(self):
        return f"Perfil de {self.user.username}"
    
    def get_age(self):
        """
        Calcula la edad del usuario basada en su fecha de nacimiento
        """
        if not self.birth_date:
            return None
        from datetime import date
        today = date.today()
        return today.year - self.birth_date.year - ((today.month, today.day) < (self.birth_date.month, self.birth_date.day))
    
    def update_communities_count(self):
        """
        Actualiza el contador de comunidades del usuario
        """
        if hasattr(self.user, 'memberships'):
            self.communities_count = self.user.memberships.filter(is_active=True).count()
            self.save(update_fields=['communities_count'])
    
    def get_public_data(self):
        """
        Retorna los datos públicos del perfil respetando las configuraciones de privacidad
        """
        data = {
            'bio': self.bio,
            'favorite_games': self.favorite_games,
            'play_style': self.play_style,
            'experience_level': self.experience_level,
            'avatar_url': self.avatar_url,
            'banner_url': self.banner_url,
            'joined_at': self.user.created_at,
        }
        
        # Agregar campos según configuraciones de privacidad
        if self.show_location:
            data['location'] = self.location
            
        if self.show_birth_date:
            data['birth_date'] = self.birth_date
            data['age'] = self.get_age()
            
        if self.show_activity_stats:
            data['stats'] = {
                'communities_count': self.communities_count,
                'posts_count': self.posts_count,
                'likes_received': self.likes_received,
                'reputation_score': self.reputation_score,
            }
        
        return data


class UserRating(models.Model):
    """
    Sistema de valoraciones entre usuarios para Nexus TCG
    Permite a los usuarios calificar sus interacciones con otros usuarios
    """
    
    # Relaciones principales
    rater = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='ratings_given',
        help_text="Usuario que otorga la valoración"
    )
    rated_user = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='ratings_received',
        help_text="Usuario que recibe la valoración"
    )
    
    # Datos de la valoración
    rating = models.IntegerField(
        help_text="Valoración de 1 a 5 estrellas",
        choices=[
            (1, '⭐ - Muy Malo'),
            (2, '⭐⭐ - Malo'),
            (3, '⭐⭐⭐ - Regular'),
            (4, '⭐⭐⭐⭐ - Bueno'),
            (5, '⭐⭐⭐⭐⭐ - Excelente'),
        ]
    )
    
    comment = models.TextField(
        max_length=300, 
        blank=True,
        help_text="Comentario opcional sobre la valoración (máximo 300 caracteres)"
    )
    
    # Contexto de la interacción
    interaction_type = models.CharField(
        max_length=30,
        choices=[
            ('trade', 'Intercambio de cartas'),
            ('game', 'Partida/Duelo'),
            ('tournament', 'Torneo'),
            ('community', 'Actividad en comunidad'),
            ('help', 'Ayuda/Asesoría'),
            ('general', 'Interacción general'),
        ],
        default='general',
        help_text="Tipo de interacción que motivó la valoración"
    )
    
    interaction_reference = models.CharField(
        max_length=100,
        blank=True,
        help_text="Referencia opcional a la interacción específica (ID de post, torneo, etc.)"
    )
    
    # Control de estado
    is_active = models.BooleanField(
        default=True,
        help_text="Si la valoración está activa (soft delete)"
    )
    
    # Metadatos
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        # Un usuario solo puede valorar a otro usuario una vez
        unique_together = ['rater', 'rated_user']
        ordering = ['-created_at']
        verbose_name = "User Rating"
        verbose_name_plural = "User Ratings"
        indexes = [
            models.Index(fields=['rated_user', 'is_active']),
            models.Index(fields=['rater', 'is_active']),
            models.Index(fields=['rating', 'is_active']),
            models.Index(fields=['interaction_type']),
        ]
    
    def __str__(self):
        return f"{self.rater.username} → {self.rated_user.username}: {self.rating}⭐"
    
    def clean(self):
        """
        Validaciones personalizadas del modelo
        """
        from django.core.exceptions import ValidationError
        
        # Un usuario no puede valorarse a sí mismo
        if self.rater == self.rated_user:
            raise ValidationError("Un usuario no puede valorarse a sí mismo")
        
        # Validar rango de valoración
        if not (1 <= self.rating <= 5):
            raise ValidationError("La valoración debe estar entre 1 y 5")
        
        # Validar límites de rate limiting (solo para nuevas valoraciones)
        if not self.pk:  # Solo validar en creación, no en actualización
            from .validators import validate_rating_limits
            try:
                validate_rating_limits(self.rater, self.rated_user)
            except ValidationError as e:
                raise ValidationError(f"Límite de valoraciones: {str(e)}")
    
    def save(self, *args, **kwargs):
        """
        Sobrescribe save para ejecutar validaciones y detección anti-gaming
        """
        self.clean()
        is_new_rating = not self.pk  # Verificar si es una nueva valoración
        
        super().save(*args, **kwargs)
        
        # Actualizar estadísticas del usuario valorado después de guardar
        self.update_user_rating_stats()
        
        # Ejecutar detección anti-gaming solo para nuevas valoraciones
        if is_new_rating:
            try:
                from .anti_gaming import analyze_rating_on_creation
                analyze_rating_on_creation(self)
            except Exception as e:
                # Log el error pero no fallar la creación de la valoración
                import logging
                logger = logging.getLogger(__name__)
                logger.error(f"Error en detección anti-gaming para rating {self.id}: {e}")
    
    def soft_delete(self):
        """
        Eliminación suave: marca la valoración como inactiva
        """
        self.is_active = False
        self.save()
        self.update_user_rating_stats()
    
    def update_user_rating_stats(self):
        """
        Actualiza las estadísticas de valoración del usuario valorado
        """
        try:
            # Por ahora solo log - el sistema de reputación se maneja por signals
            import logging
            logger = logging.getLogger(__name__)
            logger.debug(f"Rating stats update triggered for user {self.rated_user.username}")
            
            # TODO: Implementar actualización de estadísticas básicas si es necesario
            # El sistema principal de reputación se maneja en reputation.py y signals.py
            
        except Exception as e:
            # Log del error sin interrumpir el proceso
            import logging
            logger = logging.getLogger(__name__)
            logger.warning(f"Error actualizando estadísticas de valoración: {e}")
    
    @classmethod
    def get_user_rating_summary(cls, user):
        """
        Obtiene un resumen de las valoraciones de un usuario
        """
        ratings = cls.objects.filter(rated_user=user, is_active=True)
        
        if not ratings.exists():
            return {
                'total_ratings': 0,
                'average_rating': 0,
                'rating_distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
            }
        
        from django.db.models import Count, Avg
        
        summary = ratings.aggregate(
            total=Count('id'),
            average=Avg('rating')
        )
        
        # Distribución por estrellas
        distribution = {}
        for i in range(1, 6):
            distribution[i] = ratings.filter(rating=i).count()
        
        return {
            'total_ratings': summary['total'],
            'average_rating': round(summary['average'], 2),
            'rating_distribution': distribution
        }


# ================================
# MODELOS ANTI-ABUSO (FASE4-0006)
# ================================

class RatingFlag(models.Model):
    """
    Modelo para marcar valoraciones sospechosas automáticamente
    """
    FLAG_TYPE_CHOICES = [
        ('mutual_rating_circle', 'Círculo de Valoración Mutua'),
        ('five_star_bias', 'Sesgo de 5 Estrellas'),
        ('rating_burst', 'Ráfaga de Valoraciones'),
        ('inactive_user_ratings', 'Valoraciones a Usuarios Inactivos'),
        ('same_ip_ratings', 'Valoraciones desde Misma IP'),
        ('new_account_spam', 'Spam de Cuenta Nueva'),
        ('suspicious_pattern', 'Patrón Sospechoso General'),
    ]
    
    SEVERITY_CHOICES = [
        ('low', 'Baja'),
        ('medium', 'Media'),
        ('high', 'Alta'),
        ('critical', 'Crítica'),
    ]
    
    STATUS_CHOICES = [
        ('pending', 'Pendiente'),
        ('reviewed', 'Revisado'),
        ('resolved', 'Resuelto'),
        ('false_positive', 'Falso Positivo'),
    ]
    
    # Relación con la valoración flagged
    rating = models.ForeignKey(
        UserRating, 
        on_delete=models.CASCADE, 
        related_name='flags'
    )
    
    # Tipo y severidad del flag
    flag_type = models.CharField(max_length=50, choices=FLAG_TYPE_CHOICES)
    severity = models.CharField(max_length=20, choices=SEVERITY_CHOICES)
    
    # Detalles del flag (JSON con información específica)
    details = models.JSONField(
        default=dict,
        help_text="Detalles específicos del flag detectado"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    
    # Revisión manual
    reviewed_by = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='reviewed_flags'
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    moderator_notes = models.TextField(blank=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['flag_type', 'severity']),
            models.Index(fields=['status', 'created_at']),
            models.Index(fields=['rating', 'flag_type']),
        ]
    
    def __str__(self):
        return f"Flag {self.flag_type} for Rating {self.rating.id} ({self.severity})"
    
    @property
    def is_pending(self):
        return self.status == 'pending'
    
    @property
    def is_critical(self):
        return self.severity == 'critical'


class UserSuspension(models.Model):
    """
    Modelo para suspensiones de usuarios del sistema de valoraciones
    """
    SUSPENSION_TYPE_CHOICES = [
        ('warning', 'Advertencia'),
        ('temporary', 'Suspensión Temporal'),
        ('permanent', 'Suspensión Permanente'),
        ('rating_ban', 'Prohibición de Valorar'),
    ]
    
    REASON_CHOICES = [
        ('gaming_detection', 'Gaming del Sistema Detectado'),
        ('abuse_pattern', 'Patrón de Abuso'),
        ('false_ratings', 'Valoraciones Falsas'),
        ('harassment', 'Acoso a Otros Usuarios'),
        ('multiple_accounts', 'Múltiples Cuentas'),
        ('manual_review', 'Revisión Manual'),
        ('community_violation', 'Violación de Normas'),
    ]
    
    # Usuario suspendido
    user = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='rating_suspensions'
    )
    
    # Detalles de la suspensión
    suspension_type = models.CharField(max_length=20, choices=SUSPENSION_TYPE_CHOICES)
    reason = models.CharField(max_length=50, choices=REASON_CHOICES)
    reason_details = models.TextField(
        help_text="Descripción detallada del motivo de suspensión"
    )
    
    # Administración
    suspended_by = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='issued_suspensions'
    )
    
    # Temporalidad
    suspended_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(
        null=True, 
        blank=True,
        help_text="Fecha de expiración (null = permanente)"
    )
    
    # Estado
    is_active = models.BooleanField(default=True)
    lifted_at = models.DateTimeField(null=True, blank=True)
    lifted_by = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='lifted_suspensions'
    )
    lift_reason = models.TextField(blank=True)
    
    class Meta:
        ordering = ['-suspended_at']
        indexes = [
            models.Index(fields=['user', 'is_active']),
            models.Index(fields=['suspension_type', 'is_active']),
            models.Index(fields=['expires_at', 'is_active']),
        ]
    
    def __str__(self):
        return f"{self.suspension_type} for {self.user.username} by {self.suspended_by.username}"
    
    @property
    def is_expired(self):
        """Verifica si la suspensión ha expirado"""
        if not self.expires_at:
            return False  # Suspensión permanente
        return timezone.now() > self.expires_at
    
    @property
    def is_currently_active(self):
        """Verifica si la suspensión está actualmente activa"""
        return self.is_active and not self.is_expired
    
    def lift_suspension(self, lifted_by, reason=""):
        """Levanta la suspensión manualmente"""
        self.is_active = False
        self.lifted_at = timezone.now()
        self.lifted_by = lifted_by
        self.lift_reason = reason
        self.save()


class AbuseLog(models.Model):
    """
    Log de auditoría para todas las acciones del sistema anti-abuso
    """
    ACTION_TYPE_CHOICES = [
        ('flag_created', 'Flag Creado'),
        ('flag_reviewed', 'Flag Revisado'),
        ('flag_resolved', 'Flag Resuelto'),
        ('user_suspended', 'Usuario Suspendido'),
        ('suspension_lifted', 'Suspensión Levantada'),
        ('rating_blocked', 'Valoración Bloqueada'),
        ('pattern_detected', 'Patrón Detectado'),
        ('manual_review', 'Revisión Manual'),
        ('config_changed', 'Configuración Cambiada'),
        ('system_alert', 'Alerta del Sistema'),
    ]
    
    # Tipo de acción
    action_type = models.CharField(max_length=50, choices=ACTION_TYPE_CHOICES)
    
    # Usuario objetivo de la acción
    target_user = models.ForeignKey(
        User, 
        on_delete=models.CASCADE,
        related_name='abuse_logs_as_target'
    )
    
    # Moderador que ejecutó la acción (si aplica)
    moderator = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        related_name='abuse_logs_as_moderator'
    )
    
    # Detalles de la acción (JSON)
    details = models.JSONField(
        default=dict,
        help_text="Detalles específicos de la acción ejecutada"
    )
    
    # Metadatos
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    
    # Referencias opcionales
    related_rating = models.ForeignKey(
        UserRating, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True
    )
    related_flag = models.ForeignKey(
        RatingFlag, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True
    )
    related_suspension = models.ForeignKey(
        UserSuspension, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True
    )
    
    class Meta:
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['action_type', 'timestamp']),
            models.Index(fields=['target_user', 'timestamp']),
            models.Index(fields=['moderator', 'timestamp']),
        ]
    
    def __str__(self):
        return f"{self.action_type} - {self.target_user.username} at {self.timestamp}"


class AntiAbuseConfig(models.Model):
    """
    Configuración dinámica para el sistema anti-abuso
    """
    CONFIG_CATEGORIES = [
        ('rate_limiting', 'Rate Limiting'),
        ('detection_thresholds', 'Umbrales de Detección'),
        ('suspension_rules', 'Reglas de Suspensión'),
        ('notification_settings', 'Configuración de Notificaciones'),
        ('general_settings', 'Configuración General'),
    ]
    
    # Identificación
    key = models.CharField(
        max_length=100, 
        unique=True,
        help_text="Clave única de configuración (ej: daily_rating_limit)"
    )
    category = models.CharField(
        max_length=50, 
        choices=CONFIG_CATEGORIES,
        default='general_settings'
    )
    
    # Valor y descripción
    value = models.JSONField(
        help_text="Valor de configuración (puede ser número, string, dict, etc.)"
    )
    description = models.TextField(
        help_text="Descripción de qué controla esta configuración"
    )
    
    # Metadatos
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    updated_by = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True
    )
    
    # Validación
    validation_rules = models.JSONField(
        default=dict,
        blank=True,
        help_text="Reglas de validación para el valor (ej: min, max, type)"
    )
    
    class Meta:
        ordering = ['category', 'key']
        indexes = [
            models.Index(fields=['category', 'is_active']),
            models.Index(fields=['key', 'is_active']),
        ]
    
    def __str__(self):
        return f"{self.category}.{self.key} = {self.value}"
    
    @classmethod
    def get_config(cls, key, default=None):
        """
        Obtiene un valor de configuración por clave
        """
        try:
            config = cls.objects.get(key=key, is_active=True)
            return config.value
        except cls.DoesNotExist:
            return default
    
    @classmethod
    def set_config(cls, key, value, category='general_settings', description="", user=None):
        """
        Establece un valor de configuración
        """
        config, created = cls.objects.get_or_create(
            key=key,
            defaults={
                'value': value,
                'category': category,
                'description': description,
                'updated_by': user
            }
        )
        
        if not created:
            config.value = value
            config.updated_by = user
            config.save()
        
        return config
