"""
Rate Limiting para el sistema de valoraciones
"""
from django.utils import timezone
from datetime import timedelta
from users.models import UserRating, User


class RateLimitChecker:
    """
    Verificador de límites de tasa para valoraciones
    """
    
    def __init__(self):
        """Inicializa configuración de rate limiting"""
        self.config = {
            'same_user_cooldown_days': 5,     # Días entre valoraciones al mismo usuario
            'daily_limit': 15,                # Límite diario de valoraciones
            'weekly_limit': 50,               # Límite semanal
            'new_user_daily_limit': 5,        # Límite para usuarios nuevos
            'new_user_threshold_days': 7      # Días para considerar usuario "nuevo"
        }
    
    def can_user_rate(self, rater: User, rated_user: User) -> bool:
        """
        Verifica si un usuario puede valorar a otro
        
        Args:
            rater: Usuario que quiere dar la valoración
            rated_user: Usuario que recibiría la valoración
            
        Returns:
            bool: True si puede valorar, False si no
        """
        # 1. Verificar cooldown mismo usuario
        if not self._check_same_user_cooldown(rater, rated_user):
            return False
        
        # 2. Verificar límites diarios
        if not self._check_daily_limit(rater):
            return False
        
        # 3. Verificar límites semanales
        if not self._check_weekly_limit(rater):
            return False
        
        return True
    
    def _check_same_user_cooldown(self, rater: User, rated_user: User) -> bool:
        """Verifica cooldown para valorar al mismo usuario"""
        cooldown_time = timezone.now() - timedelta(
            days=self.config['same_user_cooldown_days']
        )
        
        recent_rating = UserRating.objects.filter(
            rater=rater,
            rated_user=rated_user,
            created_at__gte=cooldown_time,
            is_active=True
        ).exists()
        
        return not recent_rating
    
    def _check_daily_limit(self, rater: User) -> bool:
        """Verifica límite diario de valoraciones"""
        today = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
        
        daily_count = UserRating.objects.filter(
            rater=rater,
            created_at__gte=today,
            is_active=True
        ).count()
        
        # Límite especial para usuarios nuevos
        if self._is_new_user(rater):
            return daily_count < self.config['new_user_daily_limit']
        
        return daily_count < self.config['daily_limit']
    
    def _check_weekly_limit(self, rater: User) -> bool:
        """Verifica límite semanal de valoraciones"""
        week_ago = timezone.now() - timedelta(days=7)
        
        weekly_count = UserRating.objects.filter(
            rater=rater,
            created_at__gte=week_ago,
            is_active=True
        ).count()
        
        return weekly_count < self.config['weekly_limit']
    
    def _is_new_user(self, user: User) -> bool:
        """Verifica si es un usuario nuevo"""
        threshold = timezone.now() - timedelta(
            days=self.config['new_user_threshold_days']
        )
        return user.date_joined >= threshold
    
    def get_remaining_daily_ratings(self, rater: User) -> int:
        """Retorna cuántas valoraciones puede hacer hoy"""
        today = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
        
        daily_count = UserRating.objects.filter(
            rater=rater,
            created_at__gte=today,
            is_active=True
        ).count()
        
        limit = (self.config['new_user_daily_limit'] if self._is_new_user(rater) 
                else self.config['daily_limit'])
        
        return max(0, limit - daily_count)
    
    def get_next_rating_time(self, rater: User, rated_user: User) -> timezone.datetime:
        """Retorna cuándo puede valorar al mismo usuario nuevamente"""
        last_rating = UserRating.objects.filter(
            rater=rater,
            rated_user=rated_user,
            is_active=True
        ).order_by('-created_at').first()
        
        if not last_rating:
            return timezone.now()  # Puede valorar ahora
        
        return last_rating.created_at + timedelta(
            days=self.config['same_user_cooldown_days']
        )
