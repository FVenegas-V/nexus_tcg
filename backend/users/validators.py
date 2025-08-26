"""
Validadores para el sistema de anti-abuso de valoraciones
FASE 4-0006: Validaciones y Prevención de Abuso del Sistema de Reputación
"""
from datetime import datetime, timedelta
from django.utils import timezone
from django.core.exceptions import ValidationError
from django.db.models import Count, Q
from .models import UserRating, AntiAbuseConfig, UserSuspension


class RatingRateLimitValidator:
    """
    Validador de límites de valoraciones para prevenir abuso
    
    Implementa:
    - Cooldown de 5 días entre valoraciones del mismo usuario
    - Límite de 15 valoraciones por día
    - Límite de 50 valoraciones por semana
    - Verificación de suspensiones activas
    """
    
    def __init__(self):
        """Inicializa configuración desde base de datos o valores por defecto"""
        try:
            config = AntiAbuseConfig.objects.get(key='rate_limiting')
            self.config = config.value
        except AntiAbuseConfig.DoesNotExist:
            # Configuración por defecto
            self.config = {
                'cooldown_days': 5,
                'daily_limit': 15,
                'weekly_limit': 50,
                'enabled': True
            }
    
    def validate_rating_creation(self, rater_user, rated_user):
        """
        Valida si un usuario puede crear una nueva valoración
        
        Args:
            rater_user: Usuario que quiere valorar
            rated_user: Usuario que será valorado
            
        Raises:
            ValidationError: Si la valoración no está permitida
            
        Returns:
            dict: Información sobre límites disponibles
        """
        if not self.config.get('enabled', True):
            return self._get_limits_info(rater_user)
        
        # 1. Verificar suspensiones activas
        self._check_active_suspensions(rater_user)
        
        # 2. Verificar cooldown entre valoraciones del mismo usuario
        self._check_user_cooldown(rater_user, rated_user)
        
        # 3. Verificar límites diarios
        daily_count = self._check_daily_limit(rater_user)
        
        # 4. Verificar límites semanales
        weekly_count = self._check_weekly_limit(rater_user)
        
        return {
            'can_rate': True,
            'daily_remaining': self.config['daily_limit'] - daily_count,
            'weekly_remaining': self.config['weekly_limit'] - weekly_count,
            'next_daily_reset': self._get_next_daily_reset(),
            'next_weekly_reset': self._get_next_weekly_reset()
        }
    
    def _check_active_suspensions(self, user):
        """Verifica si el usuario tiene suspensiones activas"""
        active_suspension = UserSuspension.objects.filter(
            user=user,
            is_active=True,
            suspension_type__in=['rating_ban', 'temporary', 'permanent']
        ).filter(
            Q(expires_at__isnull=True) | Q(expires_at__gt=timezone.now())
        ).first()
        
        if active_suspension:
            if active_suspension.suspension_type == 'permanent':
                raise ValidationError(
                    "Tu cuenta está permanentemente suspendida del sistema de valoraciones."
                )
            elif active_suspension.suspension_type == 'rating_ban':
                raise ValidationError(
                    "Tienes una prohibición activa para valorar usuarios."
                )
            else:
                expires_str = active_suspension.expires_at.strftime('%d/%m/%Y %H:%M')
                raise ValidationError(
                    f"Tu cuenta está suspendida temporalmente hasta {expires_str}."
                )
    
    def _check_user_cooldown(self, rater_user, rated_user):
        """Verifica cooldown de 5 días entre valoraciones del mismo usuario"""
        cooldown_date = timezone.now() - timedelta(days=self.config['cooldown_days'])
        
        recent_rating = UserRating.objects.filter(
            rater=rater_user,
            rated_user=rated_user,
            created_at__gt=cooldown_date
        ).first()
        
        if recent_rating:
            next_allowed = recent_rating.created_at + timedelta(days=self.config['cooldown_days'])
            days_remaining = (next_allowed - timezone.now()).days
            
            raise ValidationError(
                f"Debes esperar {days_remaining} días más para valorar nuevamente a este usuario. "
                f"Próxima valoración permitida: {next_allowed.strftime('%d/%m/%Y %H:%M')}"
            )
    
    def _check_daily_limit(self, user):
        """Verifica y valida límite diario de valoraciones"""
        today_start = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
        
        daily_count = UserRating.objects.filter(
            rater=user,
            created_at__gte=today_start
        ).count()
        
        if daily_count >= self.config['daily_limit']:
            tomorrow = today_start + timedelta(days=1)
            raise ValidationError(
                f"Has alcanzado el límite diario de {self.config['daily_limit']} valoraciones. "
                f"Podrás valorar nuevamente mañana a las {tomorrow.strftime('%H:%M')}."
            )
        
        return daily_count
    
    def _check_weekly_limit(self, user):
        """Verifica y valida límite semanal de valoraciones"""
        week_start = timezone.now() - timedelta(days=timezone.now().weekday())
        week_start = week_start.replace(hour=0, minute=0, second=0, microsecond=0)
        
        weekly_count = UserRating.objects.filter(
            rater=user,
            created_at__gte=week_start
        ).count()
        
        if weekly_count >= self.config['weekly_limit']:
            next_week = week_start + timedelta(days=7)
            raise ValidationError(
                f"Has alcanzado el límite semanal de {self.config['weekly_limit']} valoraciones. "
                f"Podrás valorar nuevamente el {next_week.strftime('%d/%m/%Y')}."
            )
        
        return weekly_count
    
    def _get_limits_info(self, user):
        """Obtiene información actual sobre límites del usuario"""
        today_start = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
        week_start = timezone.now() - timedelta(days=timezone.now().weekday())
        week_start = week_start.replace(hour=0, minute=0, second=0, microsecond=0)
        
        daily_count = UserRating.objects.filter(
            rater=user,
            created_at__gte=today_start
        ).count()
        
        weekly_count = UserRating.objects.filter(
            rater=user,
            created_at__gte=week_start
        ).count()
        
        return {
            'can_rate': True,
            'daily_remaining': max(0, self.config['daily_limit'] - daily_count),
            'weekly_remaining': max(0, self.config['weekly_limit'] - weekly_count),
            'daily_used': daily_count,
            'weekly_used': weekly_count,
            'next_daily_reset': self._get_next_daily_reset(),
            'next_weekly_reset': self._get_next_weekly_reset()
        }
    
    def _get_next_daily_reset(self):
        """Calcula próximo reset diario"""
        tomorrow = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
        tomorrow += timedelta(days=1)
        return tomorrow
    
    def _get_next_weekly_reset(self):
        """Calcula próximo reset semanal"""
        today = timezone.now()
        days_until_monday = (7 - today.weekday()) % 7
        if days_until_monday == 0:  # Es lunes
            days_until_monday = 7
        
        next_monday = today + timedelta(days=days_until_monday)
        next_monday = next_monday.replace(hour=0, minute=0, second=0, microsecond=0)
        return next_monday


def validate_rating_limits(rater_user, rated_user):
    """
    Función de conveniencia para validar límites de valoración
    
    Args:
        rater_user: Usuario que quiere valorar
        rated_user: Usuario que será valorado
        
    Returns:
        dict: Información sobre límites disponibles
        
    Raises:
        ValidationError: Si la valoración no está permitida
    """
    validator = RatingRateLimitValidator()
    return validator.validate_rating_creation(rater_user, rated_user)


def get_user_rating_limits(user):
    """
    Obtiene información sobre límites de valoración de un usuario
    
    Args:
        user: Usuario para consultar límites
        
    Returns:
        dict: Información detallada sobre límites actuales
    """
    validator = RatingRateLimitValidator()
    return validator._get_limits_info(user)


class InteractionValidator:
    """
    Validador para verificar que las valoraciones se basen en interacciones reales
    """
    
    def __init__(self):
        """Inicializa configuración del validador"""
        self.config = {
            'min_interactions': 3,  # Mínimo de interacciones para validar
            'valid_interaction_types': [
                'trade',
                'sale', 
                'purchase',
                'tournament',
                'casual_game'
            ]
        }
    
    def validate_interaction(self, rater, rated_user, interaction_type: str) -> bool:
        """
        Valida si una interacción es legítima
        
        Args:
            rater: Usuario que da la valoración
            rated_user: Usuario que recibe la valoración
            interaction_type: Tipo de interacción
            
        Returns:
            bool: True si es válida, False si no
        """
        # 1. Verificar tipo de interacción válido
        if interaction_type not in self.config['valid_interaction_types']:
            return False
        
        # 2. Por ahora todas las interacciones válidas son aceptadas
        # En el futuro se podría verificar contra logs de transacciones reales
        return True
    
    def get_interaction_history(self, user1, user2) -> list:
        """
        Obtiene historial de interacciones entre dos usuarios
        
        Args:
            user1: Primer usuario
            user2: Segundo usuario
            
        Returns:
            list: Lista de valoraciones entre los usuarios
        """
        # Valoraciones que user1 dio a user2
        ratings_1_to_2 = UserRating.objects.filter(
            rater=user1,
            rated_user=user2,
            is_active=True
        ).order_by('-created_at')
        
        # Valoraciones que user2 dio a user1
        ratings_2_to_1 = UserRating.objects.filter(
            rater=user2,
            rated_user=user1,
            is_active=True
        ).order_by('-created_at')
        
        return {
            f'{user1.username}_to_{user2.username}': list(ratings_1_to_2),
            f'{user2.username}_to_{user1.username}': list(ratings_2_to_1)
        }
    
    def has_sufficient_interactions(self, rater, rated_user) -> bool:
        """
        Verifica si hay suficientes interacciones para justificar una valoración
        
        Para el MVP, esto siempre retorna True
        En el futuro se podría verificar contra un log de transacciones
        """
        return True  # Simplificado para MVP
    
    def get_valid_interaction_types(self) -> list:
        """Retorna los tipos de interacción válidos"""
        return self.config['valid_interaction_types']
