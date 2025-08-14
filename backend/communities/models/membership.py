"""
Modelo de membresías para la relación Usuario-Comunidad.
"""
from django.db import models
from django.conf import settings
from django.core.exceptions import ValidationError
from django.utils import timezone
from .community import Community


class CommunityMembership(models.Model):
    """
    Modelo intermedio para la relación muchos-a-muchos entre User y Community.
    Permite gestionar roles, estados y metadatos de la membresía.
    """
    
    ROLE_CHOICES = [
        ('member', 'Miembro'),
        ('moderator', 'Moderador'),
        ('admin', 'Administrador'),
    ]
    
    STATUS_CHOICES = [
        ('active', 'Activo'),
        ('pending', 'Pendiente de Aprobación'),
        ('suspended', 'Suspendido'),
        ('banned', 'Expulsado'),
    ]
    
    # --- Relaciones ---
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='community_memberships',
        help_text="Usuario miembro de la comunidad"
    )
    community = models.ForeignKey(
        Community,
        on_delete=models.CASCADE,
        related_name='memberships',
        help_text="Comunidad a la que pertenece"
    )
    
    # --- Estado de la Membresía ---
    role = models.CharField(
        max_length=20,
        choices=ROLE_CHOICES,
        default='member',
        help_text="Rol del usuario en la comunidad"
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='active',
        help_text="Estado actual de la membresía"
    )
    
    # --- Metadatos ---
    joined_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Fecha en que se unió a la comunidad"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="Última actualización del estado/rol"
    )
    
    # --- Campos Adicionales ---
    notes = models.TextField(
        blank=True,
        help_text="Notas internas sobre la membresía (visible solo para moderadores)"
    )
    invited_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='community_invitations',
        help_text="Usuario que invitó a este miembro (si aplica)"
    )
    
    class Meta:
        verbose_name = "Membresía de Comunidad"
        verbose_name_plural = "Membresías de Comunidades"
        unique_together = ['user', 'community']
        ordering = ['-joined_at']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['community', 'role']),
            models.Index(fields=['status']),
            models.Index(fields=['-joined_at']),
        ]
    
    def __str__(self):
        return "{} en {} ({})".format(
            self.user.username, 
            self.community.name, 
            self.get_role_display()
        )
    
    def clean(self):
        """Validaciones custom del modelo."""
        super().clean()
        
        # Validar que no se puede ser admin sin ser miembro activo
        if self.role in ['admin', 'moderator'] and self.status != 'active':
            raise ValidationError(
                "Los administradores y moderadores deben tener status 'active'"
            )
        
        # Validar límite de miembros en la comunidad
        if (self.status == 'active' and 
            self.community.max_members and 
            self.community.member_count >= self.community.max_members):
            # Solo permitir si ya era miembro activo (actualización)
            if not self.pk:  # Nueva membresía
                raise ValidationError(
                    "La comunidad '{}' ha alcanzado su límite de {} miembros".format(
                        self.community.name, self.community.max_members
                    )
                )
    
    def save(self, *args, **kwargs):
        """Override save para ejecutar validaciones."""
        self.clean()
        super().save(*args, **kwargs)
    
    @property
    def is_staff(self):
        """Determina si el usuario tiene permisos de staff (moderador o admin)."""
        return self.role in ['moderator', 'admin']
    
    @property
    def is_active(self):
        """Shortcut para verificar si la membresía está activa."""
        return self.status == 'active'
    
    @property
    def can_moderate(self):
        """Determina si puede moderar la comunidad."""
        return self.is_active and self.role in ['moderator', 'admin']
    
    @property
    def can_admin(self):
        """Determina si puede administrar la comunidad."""
        return self.is_active and self.role == 'admin'
    
    def promote_to_moderator(self, promoted_by=None):
        """Promover usuario a moderador."""
        if self.status != 'active':
            raise ValidationError("Solo se puede promover a miembros activos")
        
        self.role = 'moderator'
        if promoted_by:
            self.notes += "\nPromovido a moderador por {} el {}".format(
                promoted_by.username, timezone.now()
            )
        self.save()
    
    def demote_to_member(self, demoted_by=None):
        """Degradar usuario a miembro regular."""
        self.role = 'member'
        if demoted_by:
            self.notes += "\nDegradado a miembro por {} el {}".format(
                demoted_by.username, timezone.now()
            )
        self.save()
    
    def suspend(self, suspended_by=None, reason=""):
        """Suspender membresía."""
        self.status = 'suspended'
        self.role = 'member'  # Remover permisos de staff
        if suspended_by:
            self.notes += "\nSuspendido por {} el {}. Razón: {}".format(
                suspended_by.username, timezone.now(), reason
            )
        self.save()
    
    def reactivate(self, reactivated_by=None):
        """Reactivar membresía suspendida."""
        if self.status == 'banned':
            raise ValidationError("No se puede reactivar un usuario expulsado")
        
        self.status = 'active'
        if reactivated_by:
            self.notes += "\nReactivado por {} el {}".format(
                reactivated_by.username, timezone.now()
            )
        self.save()
