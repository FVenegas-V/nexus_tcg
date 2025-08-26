"""
Motor de detección anti-gaming para el sistema de valoraciones
FASE 4-0006: Validaciones y Prevención de Abuso del Sistema de Reputación
"""
from datetime import datetime, timedelta
from django.utils import timezone
from django.db.models import Count, Q, Avg
from django.contrib.auth import get_user_model
from .models import UserRating, RatingFlag, AntiAbuseConfig, AbuseLog
import logging

User = get_user_model()
logger = logging.getLogger(__name__)


class AntiGamingDetector:
    """
    Detector principal de patrones de gaming en el sistema de valoraciones
    
    Implementa múltiples algoritmos para detectar:
    - Círculos de valoración mutua
    - Sesgos de 5 estrellas 
    - Ráfagas de valoraciones
    - Valoraciones desde misma IP
    - Spam de cuentas nuevas
    - Patrones sospechosos generales
    """
    
    def __init__(self):
        """Inicializa configuración desde base de datos"""
        try:
            config = AntiAbuseConfig.objects.get(key='gaming_detection')
            self.config = config.value
        except AntiAbuseConfig.DoesNotExist:
            # Configuración por defecto si no existe
            self.config = {
                'enabled': True,
                'mutual_rating_threshold': 3,
                'five_star_bias_threshold': 0.92,  # 92% en lugar de 80%
                'rating_burst_threshold': 10,
                'same_ip_threshold': 5,
                'new_account_days': 7,
                'new_account_limit': 5  # 5 en lugar de 3 para cuentas nuevas
            }
    
    def analyze_rating(self, rating):
        """
        Analiza una valoración específica para detectar patrones sospechosos
        
        Args:
            rating: Instancia de UserRating a analizar
            
        Returns:
            list: Lista de flags detectados
        """
        if not self.config.get('enabled', True):
            return []
        
        flags = []
        
        # 1. Detectar círculos de valoración mutua
        mutual_flags = self._detect_mutual_rating_circle(rating)
        flags.extend(mutual_flags)
        
        # 2. Detectar sesgo de 5 estrellas
        bias_flags = self._detect_five_star_bias(rating)
        flags.extend(bias_flags)
        
        # 3. Detectar ráfagas de valoraciones
        burst_flags = self._detect_rating_burst(rating)
        flags.extend(burst_flags)
        
        # 4. Detectar valoraciones a usuarios inactivos
        inactive_flags = self._detect_inactive_user_ratings(rating)
        flags.extend(inactive_flags)
        
        # 5. Detectar spam de cuentas nuevas
        new_account_flags = self._detect_new_account_spam(rating)
        flags.extend(new_account_flags)
        
        # 6. Detectar patrones sospechosos generales
        pattern_flags = self._detect_suspicious_patterns(rating)
        flags.extend(pattern_flags)
        
        return flags
    
    def _detect_mutual_rating_circle(self, rating):
        """
        Detecta círculos de valoración mutua (usuarios que se valoran repetidamente)
        """
        flags = []
        
        # Buscar valoraciones mutuas entre los dos usuarios
        mutual_ratings = UserRating.objects.filter(
            Q(rater=rating.rater, rated_user=rating.rated_user) |
            Q(rater=rating.rated_user, rated_user=rating.rater),
            is_active=True,
            created_at__gte=timezone.now() - timedelta(days=30)  # Últimos 30 días
        ).count()
        
        threshold = self.config.get('mutual_rating_threshold', 3)
        
        if mutual_ratings >= threshold:
            flags.append({
                'type': 'mutual_rating_circle',
                'severity': 'medium' if mutual_ratings < threshold + 2 else 'high',
                'details': {
                    'mutual_ratings_count': mutual_ratings,
                    'threshold': threshold,
                    'period_days': 30,
                    'users_involved': [rating.rater.id, rating.rated_user.id]
                },
                'message': f'Detectado círculo de valoración mutua: {mutual_ratings} valoraciones mutuas en 30 días'
            })
        
        return flags
    
    def _detect_five_star_bias(self, rating):
        """
        Detecta usuarios que dan demasiadas valoraciones de 5 estrellas (sesgo artificial)
        """
        flags = []
        
        # Obtener valoraciones recientes del usuario
        recent_ratings = UserRating.objects.filter(
            rater=rating.rater,
            is_active=True,
            created_at__gte=timezone.now() - timedelta(days=30)
        )
        
        total_ratings = recent_ratings.count()
        five_star_ratings = recent_ratings.filter(rating=5).count()
        
        if total_ratings >= 10:  # Requerir al menos 10 valoraciones para análisis
            five_star_ratio = five_star_ratings / total_ratings
            threshold = self.config.get('five_star_bias_threshold', 0.92)  # 92% por defecto
            
            if five_star_ratio >= threshold:
                severity = 'medium' if five_star_ratio < 0.95 else 'high'  # Ajustar umbrales
                flags.append({
                    'type': 'five_star_bias',
                    'severity': severity,
                    'details': {
                        'five_star_ratio': round(five_star_ratio, 3),
                        'five_star_count': five_star_ratings,
                        'total_ratings': total_ratings,
                        'threshold': threshold,
                        'period_days': 30
                    },
                    'message': f'Sesgo de 5 estrellas detectado: {five_star_ratio:.1%} de valoraciones son 5 estrellas'
                })
        
        return flags
    
    def _detect_rating_burst(self, rating):
        """
        Detecta ráfagas de valoraciones (muchas valoraciones en poco tiempo)
        """
        flags = []
        
        # Verificar valoraciones en la última hora
        one_hour_ago = timezone.now() - timedelta(hours=1)
        recent_burst = UserRating.objects.filter(
            rater=rating.rater,
            is_active=True,
            created_at__gte=one_hour_ago
        ).count()
        
        threshold = self.config.get('rating_burst_threshold', 10)
        
        if recent_burst >= threshold:
            severity = 'high' if recent_burst >= threshold * 2 else 'medium'
            flags.append({
                'type': 'rating_burst',
                'severity': severity,
                'details': {
                    'ratings_in_hour': recent_burst,
                    'threshold': threshold,
                    'time_window': '1 hour',
                    'detection_time': timezone.now().isoformat()
                },
                'message': f'Ráfaga de valoraciones detectada: {recent_burst} valoraciones en 1 hora'
            })
        
        return flags
    
    def _detect_inactive_user_ratings(self, rating):
        """
        Detecta valoraciones a usuarios que han estado inactivos por mucho tiempo
        """
        flags = []
        
        # Verificar actividad reciente del usuario valorado
        if hasattr(rating.rated_user, 'last_login') and rating.rated_user.last_login:
            days_inactive = (timezone.now() - rating.rated_user.last_login).days
            
            # Si el usuario ha estado inactivo más de 60 días
            if days_inactive > 60:
                severity = 'medium' if days_inactive < 120 else 'high'
                flags.append({
                    'type': 'inactive_user_ratings',
                    'severity': severity,
                    'details': {
                        'days_inactive': days_inactive,
                        'last_login': rating.rated_user.last_login.isoformat() if rating.rated_user.last_login else None,
                        'rated_user_id': rating.rated_user.id
                    },
                    'message': f'Valoración a usuario inactivo: {days_inactive} días sin actividad'
                })
        
        return flags
    
    def _detect_new_account_spam(self, rating):
        """
        Detecta spam de cuentas nuevas (cuentas recién creadas que valoran mucho)
        """
        flags = []
        
        # Verificar si la cuenta del usuario que valora es nueva
        account_age = (timezone.now() - rating.rater.date_joined).days
        new_account_threshold = self.config.get('new_account_days', 7)
        
        if account_age <= new_account_threshold:
            # Contar valoraciones de esta cuenta nueva
            ratings_by_new_account = UserRating.objects.filter(
                rater=rating.rater,
                is_active=True
            ).count()
            
            limit = self.config.get('new_account_limit', 3)
            
            if ratings_by_new_account > limit:
                flags.append({
                    'type': 'new_account_spam',
                    'severity': 'high',
                    'details': {
                        'account_age_days': account_age,
                        'ratings_count': ratings_by_new_account,
                        'limit': limit,
                        'threshold_days': new_account_threshold,
                        'created_at': rating.rater.date_joined.isoformat()
                    },
                    'message': f'Spam de cuenta nueva: {ratings_by_new_account} valoraciones en cuenta de {account_age} días'
                })
        
        return flags
    
    def _detect_suspicious_patterns(self, rating):
        """
        Detecta otros patrones sospechosos generales
        """
        flags = []
        
        # Patrón 1: Valoraciones siempre en el mismo tipo de interacción
        interaction_pattern = UserRating.objects.filter(
            rater=rating.rater,
            is_active=True,
            created_at__gte=timezone.now() - timedelta(days=14)
        ).values('interaction_type').annotate(count=Count('id')).order_by('-count')
        
        if interaction_pattern:
            dominant_type = interaction_pattern[0]
            total_recent = sum(p['count'] for p in interaction_pattern)
            
            if total_recent >= 5 and dominant_type['count'] / total_recent >= 0.9:
                flags.append({
                    'type': 'suspicious_pattern',
                    'severity': 'low',
                    'details': {
                        'pattern_type': 'single_interaction_type',
                        'dominant_type': dominant_type['interaction_type'],
                        'ratio': dominant_type['count'] / total_recent,
                        'total_ratings': total_recent
                    },
                    'message': f'Patrón sospechoso: 90%+ valoraciones en tipo "{dominant_type["interaction_type"]}"'
                })
        
        # Patrón 2: Valoraciones consecutivas con mismo rating
        consecutive_same = UserRating.objects.filter(
            rater=rating.rater,
            is_active=True,
            created_at__gte=timezone.now() - timedelta(days=10)  # 10 días en lugar de 7
        ).order_by('-created_at')[:8]  # 8 valoraciones en lugar de 5
        
        if len(consecutive_same) >= 8:  # Requerir 8 valoraciones consecutivas
            ratings_values = [r.rating for r in consecutive_same]
            if len(set(ratings_values)) == 1:  # Todas las valoraciones son iguales
                flags.append({
                    'type': 'suspicious_pattern',
                    'severity': 'medium',
                    'details': {
                        'pattern_type': 'consecutive_same_rating',
                        'rating_value': ratings_values[0],
                        'consecutive_count': len(consecutive_same)
                    },
                    'message': f'Patrón sospechoso: {len(consecutive_same)} valoraciones consecutivas con {ratings_values[0]} estrellas'
                })
        
        return flags
    
    def create_flags_for_rating(self, rating):
        """
        Analiza una valoración y crea flags en la base de datos si detecta problemas
        
        Args:
            rating: Instancia de UserRating
            
        Returns:
            list: Lista de RatingFlag objetos creados
        """
        detected_flags = self.analyze_rating(rating)
        created_flags = []
        
        for flag_data in detected_flags:
            try:
                flag = RatingFlag.objects.create(
                    rating=rating,
                    flag_type=flag_data['type'],
                    severity=flag_data['severity'],
                    details=flag_data['details']
                )
                created_flags.append(flag)
                
                # Log para auditoría
                logger.info(f"Flag creado: {flag_data['type']} - {flag_data['message']}")
                
                # Crear entrada en AbuseLog
                AbuseLog.objects.create(
                    action_type='flag_created',
                    target_user=rating.rated_user,
                    moderator=None,  # Detección automática
                    details={
                        'flag_id': flag.id,
                        'flag_type': flag_data['type'],
                        'severity': flag_data['severity'],
                        'rating_id': rating.id,
                        'rater_id': rating.rater.id,
                        'auto_detected': True,
                        'message': flag_data['message']
                    }
                )
                
            except Exception as e:
                logger.error(f"Error creando flag: {e}")
        
        return created_flags
    
    def bulk_analyze_recent_ratings(self, hours=24):
        """
        Analiza todas las valoraciones recientes en busca de patrones
        
        Args:
            hours: Número de horas hacia atrás para analizar
            
        Returns:
            dict: Resumen del análisis
        """
        since = timezone.now() - timedelta(hours=hours)
        recent_ratings = UserRating.objects.filter(
            created_at__gte=since,
            is_active=True
        ).select_related('rater', 'rated_user')
        
        total_analyzed = 0
        total_flags = 0
        flag_types = {}
        
        for rating in recent_ratings:
            flags = self.create_flags_for_rating(rating)
            total_analyzed += 1
            total_flags += len(flags)
            
            for flag in flags:
                flag_types[flag.flag_type] = flag_types.get(flag.flag_type, 0) + 1
        
        return {
            'period_hours': hours,
            'ratings_analyzed': total_analyzed,
            'flags_created': total_flags,
            'flag_types': flag_types,
            'analysis_time': timezone.now().isoformat()
        }


def analyze_rating_on_creation(rating):
    """
    Función de conveniencia para analizar una valoración al momento de crearla
    
    Args:
        rating: Instancia de UserRating recién creada
        
    Returns:
        list: Lista de flags detectados
    """
    detector = AntiGamingDetector()
    return detector.create_flags_for_rating(rating)


def get_user_suspicious_activity_summary(user):
    """
    Obtiene resumen de actividad sospechosa de un usuario
    
    Args:
        user: Instancia de User
        
    Returns:
        dict: Resumen de flags y patrones detectados
    """
    # Flags en valoraciones dadas por el usuario
    given_flags = RatingFlag.objects.filter(
        rating__rater=user,
        status='pending'
    ).values('flag_type', 'severity').annotate(count=Count('id'))
    
    # Flags en valoraciones recibidas por el usuario
    received_flags = RatingFlag.objects.filter(
        rating__rated_user=user,
        status='pending'
    ).values('flag_type', 'severity').annotate(count=Count('id'))
    
    return {
        'user_id': user.id,
        'username': user.username,
        'flags_on_given_ratings': list(given_flags),
        'flags_on_received_ratings': list(received_flags),
        'total_suspicious_given': sum(f['count'] for f in given_flags),
        'total_suspicious_received': sum(f['count'] for f in received_flags),
        'generated_at': timezone.now().isoformat()
    }
