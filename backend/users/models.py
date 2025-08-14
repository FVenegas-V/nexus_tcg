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
