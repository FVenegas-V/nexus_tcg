"""
Tests para el sistema de reputación de Nexus TCG.
Incluye tests para el algoritmo, endpoints, tasks y edge cases.
"""

from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from decimal import Decimal
from datetime import timedelta
from unittest.mock import patch, MagicMock
from rest_framework.test import APITestCase, APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken

from users.models import UserRating
from users.reputation import (
    calculate_user_reputation,
    get_reputation_breakdown,
    update_user_reputation_sync,
    validate_reputation_consistency
)

User = get_user_model()


class ReputationAlgorithmTestCase(TestCase):
    """Tests para el algoritmo de cálculo de reputación."""
    
    def setUp(self):
        """Configuración inicial para los tests."""
        # Crear usuarios de prueba
        self.rated_user = User.objects.create_user(
            username='rated_user',
            email='rated@test.com',
            password='testpass123'
        )
        
        self.evaluator1 = User.objects.create_user(
            username='evaluator1',
            email='eval1@test.com',
            password='testpass123'
        )
        
        self.evaluator2 = User.objects.create_user(
            username='evaluator2',
            email='eval2@test.com',
            password='testpass123'
        )
        
        self.evaluator3 = User.objects.create_user(
            username='evaluator3',
            email='eval3@test.com',
            password='testpass123'
        )
        
        # Dar algo de reputación a los evaluadores
        self.evaluator1.reputation_score = Decimal('4.5')
        self.evaluator1.save()
        
        self.evaluator2.reputation_score = Decimal('3.0')
        self.evaluator2.save()
        
        self.evaluator3.reputation_score = Decimal('1.5')
        self.evaluator3.save()

    def test_calculate_reputation_no_ratings(self):
        """Test calcular reputación sin valoraciones."""
        score, count = calculate_user_reputation(self.rated_user)
        
        self.assertEqual(score, Decimal('0.0'))
        self.assertEqual(count, 0)

    def test_calculate_reputation_single_rating(self):
        """Test calcular reputación con una sola valoración."""
        # Crear valoración reciente
        UserRating.objects.create(
            rater=self.evaluator1,
            rated_user=self.rated_user,
            rating=5,
            comment="Excelente usuario"
        )
        
        score, count = calculate_user_reputation(self.rated_user)
        
        self.assertGreater(score, Decimal('0.0'))
        self.assertEqual(count, 1)
        # Con un evaluador de buena reputación y rating 5, esperamos una puntuación alta
        self.assertGreater(score, Decimal('4.0'))

    def test_calculate_reputation_multiple_ratings(self):
        """Test calcular reputación con múltiples valoraciones."""
        now = timezone.now()
        
        # Crear múltiples valoraciones con diferentes timestamps
        UserRating.objects.create(
            rater=self.evaluator1,
            rated_user=self.rated_user,
            rating=5,
            created_at=now
        )
        
        UserRating.objects.create(
            rater=self.evaluator2,
            rated_user=self.rated_user,
            rating=4,
            created_at=now - timedelta(days=30)
        )
        
        UserRating.objects.create(
            rater=self.evaluator3,
            rated_user=self.rated_user,
            rating=3,
            created_at=now - timedelta(days=60)
        )
        
        score, count = calculate_user_reputation(self.rated_user)
        
        self.assertEqual(count, 3)
        self.assertGreater(score, Decimal('0.0'))
        # Debería estar entre 3 y 5 considerando los pesos
        self.assertGreater(score, Decimal('3.0'))
        self.assertLess(score, Decimal('5.0'))

    def test_temporal_weight_decay(self):
        """Test que el peso temporal decae correctamente."""
        now = timezone.now()
        
        # Rating reciente
        recent_rating = UserRating.objects.create(
            rater=self.evaluator1,
            rated_user=self.rated_user,
            rating=5,
            created_at=now
        )
        
        # Rating antiguo
        old_rating = UserRating.objects.create(
            rater=self.evaluator2,
            rated_user=self.rated_user,
            rating=5,
            created_at=now - timedelta(days=300)
        )
        
        score_with_old, _ = calculate_user_reputation(self.rated_user)
        
        # Eliminar rating antiguo y recalcular
        old_rating.delete()
        score_without_old, _ = calculate_user_reputation(self.rated_user)
        
        # La puntuación sin el rating antiguo debería ser similar o mayor
        # porque el rating antiguo tiene menos peso
        self.assertGreaterEqual(score_without_old, score_with_old * Decimal('0.9'))

    def test_evaluator_credibility_impact(self):
        """Test que la credibilidad del evaluador afecta la puntuación."""
        # Crear dos ratings iguales de evaluadores con diferente credibilidad
        UserRating.objects.create(
            rater=self.evaluator1,  # Alta reputación (4.5)
            rated_user=self.rated_user,
            rating=5
        )
        
        score_high_cred, _ = calculate_user_reputation(self.rated_user)
        
        # Eliminar y crear con evaluador de baja credibilidad
        UserRating.objects.filter(rated_user=self.rated_user).delete()
        
        UserRating.objects.create(
            rater=self.evaluator3,  # Baja reputación (1.5)
            rated_user=self.rated_user,
            rating=5
        )
        
        score_low_cred, _ = calculate_user_reputation(self.rated_user)
        
        # La puntuación con evaluador de alta credibilidad debería ser mayor
        self.assertGreater(score_high_cred, score_low_cred)

    def test_get_reputation_breakdown(self):
        """Test obtener desglose detallado de reputación."""
        # Crear algunas valoraciones
        UserRating.objects.create(
            rater=self.evaluator1,
            rated_user=self.rated_user,
            rating=5,
            comment="Excelente"
        )
        
        UserRating.objects.create(
            rater=self.evaluator2,
            rated_user=self.rated_user,
            rating=4,
            comment="Muy bueno"
        )
        
        breakdown = get_reputation_breakdown(self.rated_user)
        
        # Verificar estructura del breakdown
        self.assertIn('final_score', breakdown)
        self.assertIn('total_ratings', breakdown)
        self.assertIn('ratings_data', breakdown)
        self.assertIn('algorithm_factors', breakdown)
        
        self.assertEqual(breakdown['total_ratings'], 2)
        self.assertEqual(len(breakdown['ratings_data']), 2)
        
        # Verificar datos de ratings individuales
        rating_data = breakdown['ratings_data'][0]
        self.assertIn('rating_value', rating_data)
        self.assertIn('temporal_weight', rating_data)
        self.assertIn('evaluator_credibility', rating_data)
        self.assertIn('weighted_contribution', rating_data)

    def test_update_user_reputation_sync(self):
        """Test actualización síncrona de reputación."""
        # Crear valoración
        UserRating.objects.create(
            rater=self.evaluator1,
            rated_user=self.rated_user,
            rating=4
        )
        
        # Verificar que inicialmente no tiene reputación
        self.assertIsNone(self.rated_user.reputation_score)
        
        # Actualizar reputación
        new_score, count = update_user_reputation_sync(self.rated_user)
        
        # Recargar usuario desde DB
        self.rated_user.refresh_from_db()
        
        # Verificar que se actualizó
        self.assertEqual(self.rated_user.reputation_score, new_score)
        self.assertEqual(self.rated_user.reputation_count, count)
        self.assertGreater(new_score, Decimal('0.0'))
        self.assertEqual(count, 1)

    def test_inactive_ratings_ignored(self):
        """Test que las valoraciones inactivas se ignoran."""
        # Crear valoración activa
        active_rating = UserRating.objects.create(
            rater=self.evaluator1,
            rated_user=self.rated_user,
            rating=5
        )
        
        # Crear valoración inactiva
        inactive_rating = UserRating.objects.create(
            rater=self.evaluator2,
            rated_user=self.rated_user,
            rating=1,
            is_active=False
        )
        
        score, count = calculate_user_reputation(self.rated_user)
        
        # Solo debería contar la valoración activa
        self.assertEqual(count, 1)
        self.assertGreater(score, Decimal('4.0'))  # Debería ser cercano a 5

    def test_self_rating_prevention(self):
        """Test que las auto-valoraciones se manejan correctamente."""
        # Intentar crear auto-valoración (debería estar prevenido por el modelo)
        with self.assertRaises(Exception):
            UserRating.objects.create(
                rater=self.rated_user,
                rated_user=self.rated_user,
                rating=5
            )


class ReputationConsistencyTestCase(TestCase):
    """Tests para validación de consistencia."""
    
    def setUp(self):
        """Configuración inicial."""
        self.user1 = User.objects.create_user(
            username='user1',
            email='user1@test.com',
            password='testpass123'
        )
        
        self.user2 = User.objects.create_user(
            username='user2',
            email='user2@test.com',
            password='testpass123'
        )

    def test_validate_consistency_no_users(self):
        """Test validación cuando no hay usuarios con valoraciones."""
        report = validate_reputation_consistency()
        
        self.assertTrue(report['is_consistent'])
        self.assertEqual(report['total_users_checked'], 0)
        self.assertEqual(report['inconsistencies_found'], 0)

    def test_validate_consistency_consistent_system(self):
        """Test validación con sistema consistente."""
        # Crear valoración y actualizar reputación correctamente
        UserRating.objects.create(
            rater=self.user1,
            rated_user=self.user2,
            rating=4
        )
        
        update_user_reputation_sync(self.user2)
        
        report = validate_reputation_consistency()
        
        self.assertTrue(report['is_consistent'])
        self.assertEqual(report['total_users_checked'], 1)
        self.assertEqual(report['inconsistencies_found'], 0)

    def test_validate_consistency_inconsistent_system(self):
        """Test validación con inconsistencias."""
        # Crear valoración
        UserRating.objects.create(
            rater=self.user1,
            rated_user=self.user2,
            rating=4
        )
        
        # Establecer reputación incorrecta manualmente
        self.user2.reputation_score = Decimal('1.0')  # Valor incorrecto
        self.user2.reputation_count = 5  # Conteo incorrecto
        self.user2.save()
        
        report = validate_reputation_consistency()
        
        self.assertFalse(report['is_consistent'])
        self.assertEqual(report['total_users_checked'], 1)
        self.assertEqual(report['inconsistencies_found'], 1)
        self.assertEqual(len(report['inconsistencies']), 1)
        
        inconsistency = report['inconsistencies'][0]
        self.assertEqual(inconsistency['user_id'], self.user2.id)
        self.assertNotEqual(inconsistency['expected_score'], inconsistency['stored_score'])


class ReputationAPITestCase(APITestCase):
    """Tests para los endpoints de la API de reputación."""
    
    def setUp(self):
        """Configuración inicial para tests de API."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@test.com',
            password='testpass123'
        )
        
        self.admin_user = User.objects.create_user(
            username='admin',
            email='admin@test.com',
            password='testpass123',
            is_staff=True
        )
        
        self.other_user = User.objects.create_user(
            username='otheruser',
            email='other@test.com',
            password='testpass123'
        )
        
        # Configurar cliente API
        self.client = APIClient()

    def get_jwt_token(self, user):
        """Obtiene token JWT para autenticación."""
        refresh = RefreshToken.for_user(user)
        return str(refresh.access_token)

    def test_get_reputation_stats_authenticated(self):
        """Test obtener estadísticas de reputación autenticado."""
        # Crear algunas valoraciones
        UserRating.objects.create(
            rater=self.other_user,
            rated_user=self.user,
            rating=5
        )
        
        update_user_reputation_sync(self.user)
        
        # Autenticar
        token = self.get_jwt_token(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        
        # Hacer petición
        url = f'/api/users/reputation/{self.user.id}/reputation-stats/'
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        
        # Verificar estructura de respuesta
        self.assertIn('user', data)
        self.assertIn('reputation', data)
        self.assertIn('breakdown', data)
        
        self.assertEqual(data['user']['username'], self.user.username)
        self.assertGreater(data['reputation']['score'], 0)
        self.assertEqual(data['reputation']['rating_count'], 1)

    def test_get_reputation_stats_unauthenticated(self):
        """Test obtener estadísticas sin autenticación."""
        url = f'/api/users/reputation/{self.user.id}/reputation-stats/'
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_recalculate_reputation_admin_only(self):
        """Test recalcular reputación solo para admins."""
        # Crear valoración
        UserRating.objects.create(
            rater=self.other_user,
            rated_user=self.user,
            rating=4
        )
        
        # Intentar como usuario normal
        token = self.get_jwt_token(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        
        url = f'/api/users/reputation/{self.user.id}/recalculate-reputation/'
        response = self.client.post(url)
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        
        # Intentar como admin
        admin_token = self.get_jwt_token(self.admin_user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {admin_token}')
        
        response = self.client.post(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        
        self.assertIn('message', data)
        self.assertIn('changes', data)
        self.assertEqual(data['user']['username'], self.user.username)

    def test_get_system_stats_admin_only(self):
        """Test estadísticas del sistema solo para admins."""
        # Intentar como usuario normal
        token = self.get_jwt_token(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        
        url = '/api/users/reputation/system-stats/'
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        
        # Intentar como admin
        admin_token = self.get_jwt_token(self.admin_user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {admin_token}')
        
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        
        self.assertIn('system_overview', data)
        self.assertIn('reputation_statistics', data)
        self.assertIn('distribution', data)
        self.assertIn('top_users', data)

    @patch('users.tasks.validate_reputation_consistency_task.delay')
    def test_validate_consistency_async(self, mock_task):
        """Test validación de consistencia asíncrona."""
        mock_task.return_value = MagicMock(id='test-task-id')
        
        # Autenticar como admin
        admin_token = self.get_jwt_token(self.admin_user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {admin_token}')
        
        url = '/api/users/reputation/validate-consistency/'
        response = self.client.post(url, {'async': True})
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        
        self.assertIn('task_id', data)
        self.assertEqual(data['task_id'], 'test-task-id')
        mock_task.assert_called_once()

    @patch('users.tasks.bulk_update_reputations_task.delay')
    def test_bulk_recalculate_async(self, mock_task):
        """Test recálculo masivo asíncrono."""
        mock_task.return_value = MagicMock(id='bulk-task-id')
        
        # Autenticar como admin
        admin_token = self.get_jwt_token(self.admin_user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {admin_token}')
        
        url = '/api/users/reputation/bulk-recalculate/'
        response = self.client.post(url, {
            'user_ids': [self.user.id, self.other_user.id],
            'async': True,
            'batch_size': 10
        })
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        
        self.assertIn('task_id', data)
        self.assertEqual(data['task_id'], 'bulk-task-id')
        self.assertEqual(data['total_users'], 2)
        mock_task.assert_called_once_with([self.user.id, self.other_user.id], 10)


class ReputationEdgeCasesTestCase(TestCase):
    """Tests para casos extremos y edge cases."""
    
    def setUp(self):
        """Configuración inicial."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@test.com',
            password='testpass123'
        )
        
        self.evaluator = User.objects.create_user(
            username='evaluator',
            email='eval@test.com',
            password='testpass123'
        )

    def test_extremely_old_rating(self):
        """Test rating extremadamente antiguo."""
        # Rating de hace 5 años
        old_date = timezone.now() - timedelta(days=1825)
        
        UserRating.objects.create(
            rater=self.evaluator,
            rated_user=self.user,
            rating=5,
            created_at=old_date
        )
        
        score, count = calculate_user_reputation(self.user)
        
        # Debería tener muy poco peso pero aún contribuir algo
        self.assertGreater(score, Decimal('0.0'))
        self.assertLess(score, Decimal('1.0'))
        self.assertEqual(count, 1)

    def test_evaluator_without_reputation(self):
        """Test evaluador sin reputación establecida."""
        # Evaluador sin reputation_score (None)
        self.evaluator.reputation_score = None
        self.evaluator.save()
        
        UserRating.objects.create(
            rater=self.evaluator,
            rated_user=self.user,
            rating=5
        )
        
        score, count = calculate_user_reputation(self.user)
        
        # Debería usar credibilidad por defecto
        self.assertGreater(score, Decimal('0.0'))
        self.assertEqual(count, 1)

    def test_massive_number_of_ratings(self):
        """Test con gran cantidad de valoraciones."""
        # Crear muchas valoraciones
        for i in range(100):
            evaluator = User.objects.create_user(
                username=f'eval_{i}',
                email=f'eval_{i}@test.com',
                password='testpass123'
            )
            
            UserRating.objects.create(
                rater=evaluator,
                rated_user=self.user,
                rating=4,  # Rating consistente
            )
        
        score, count = calculate_user_reputation(self.user)
        
        self.assertEqual(count, 100)
        # Con 100 ratings de 4, debería estar cerca de 4
        self.assertGreater(score, Decimal('3.5'))
        self.assertLess(score, Decimal('4.5'))

    def test_extreme_rating_values(self):
        """Test con valores extremos de rating."""
        # Rating mínimo
        UserRating.objects.create(
            rater=self.evaluator,
            rated_user=self.user,
            rating=1
        )
        
        score_min, count_min = calculate_user_reputation(self.user)
        
        # Limpiar y probar rating máximo
        UserRating.objects.all().delete()
        
        UserRating.objects.create(
            rater=self.evaluator,
            rated_user=self.user,
            rating=5
        )
        
        score_max, count_max = calculate_user_reputation(self.user)
        
        self.assertEqual(count_min, 1)
        self.assertEqual(count_max, 1)
        self.assertLess(score_min, score_max)
        self.assertGreater(score_min, Decimal('0.0'))
        self.assertLess(score_max, Decimal('5.1'))
