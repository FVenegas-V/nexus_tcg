"""
Tests para el sistema de reputación de Nexus TCG.
"""

from django.test import TestCase
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from decimal import Decimal
from datetime import timedelta
from django.utils import timezone

from users.models import UserRating
from users.reputation import (
    calculate_user_reputation,
    get_reputation_breakdown,
    update_user_reputation_sync,
    validate_reputation_consistency
)

User = get_user_model()


class ReputationCalculationTests(TestCase):
    """Tests para el cálculo de reputación."""
    
    def setUp(self):
        """Configuración inicial para los tests."""
        # Crear usuarios
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
        self.user3 = User.objects.create_user(
            username='user3',
            email='user3@test.com',
            password='testpass123'
        )
        self.rated_user = User.objects.create_user(
            username='rated_user',
            email='rated@test.com',
            password='testpass123'
        )

    def test_user_without_ratings(self):
        """Test usuario sin valoraciones."""
        score, count = calculate_user_reputation(self.rated_user)
        
        self.assertEqual(score, Decimal('0.0'))
        self.assertEqual(count, 0)

    def test_single_rating(self):
        """Test usuario con una sola valoración."""
        # Crear valoración
        UserRating.objects.create(
            rater=self.user1,
            rated_user=self.rated_user,
            rating=4,
            comment="Buen usuario"
        )
        
        score, count = calculate_user_reputation(self.rated_user)
        
        self.assertGreater(score, Decimal('0.0'))
        self.assertEqual(count, 1)
        # Con una sola valoración, debería ser cerca del valor base
        self.assertLess(score, Decimal('4.0'))  # Por factores del algoritmo

    def test_multiple_ratings(self):
        """Test usuario con múltiples valoraciones."""
        # Crear varias valoraciones
        ratings_data = [
            (self.user1, 5, "Excelente"),
            (self.user2, 4, "Muy bueno"),
            (self.user3, 3, "Bueno")
        ]
        
        for user, rating, comment in ratings_data:
            UserRating.objects.create(
                rater=user,
                rated_user=self.rated_user,
                rating=rating,
                comment=comment
            )
        
        score, count = calculate_user_reputation(self.rated_user)
        
        self.assertGreater(score, Decimal('0.0'))
        self.assertEqual(count, 3)
        # Con más valoraciones, debería estar más cerca del promedio
        self.assertGreater(score, Decimal('2.0'))
        self.assertLess(score, Decimal('5.0'))

    def test_temporal_decay(self):
        """Test del decay temporal en valoraciones."""
        # Crear valoración antigua
        old_rating = UserRating.objects.create(
            rater=self.user1,
            rated_user=self.rated_user,
            rating=5,
            comment="Valoración antigua"
        )
        # Simular que es de hace un año
        old_rating.created_at = timezone.now() - timedelta(days=365)
        old_rating.save()
        
        # Crear valoración reciente
        UserRating.objects.create(
            rater=self.user2,
            rated_user=self.rated_user,
            rating=5,
            comment="Valoración reciente"
        )
        
        breakdown = get_reputation_breakdown(self.rated_user)
        
        # Verificar que hay diferencia en pesos temporales
        weights = [r['temporal_weight'] for r in breakdown['ratings_data']]
        self.assertTrue(any(w != weights[0] for w in weights))

    def test_inactive_ratings_ignored(self):
        """Test que valoraciones inactivas son ignoradas."""
        # Crear valoración activa
        UserRating.objects.create(
            rater=self.user1,
            rated_user=self.rated_user,
            rating=5,
            comment="Activa"
        )
        
        # Crear valoración inactiva
        UserRating.objects.create(
            rater=self.user2,
            rated_user=self.rated_user,
            rating=1,
            comment="Inactiva",
            is_active=False
        )
        
        score, count = calculate_user_reputation(self.rated_user)
        
        # Solo debe contar la valoración activa
        self.assertEqual(count, 1)

    def test_update_user_reputation_sync(self):
        """Test actualización síncrona de reputación."""
        # Crear valoración
        UserRating.objects.create(
            rater=self.user1,
            rated_user=self.rated_user,
            rating=4,
            comment="Test"
        )
        
        # Verificar valores iniciales
        self.assertIsNone(self.rated_user.reputation_score)
        self.assertIsNone(self.rated_user.reputation_count)
        
        # Actualizar reputación
        new_score, count = update_user_reputation_sync(self.rated_user)
        
        # Refrescar objeto
        self.rated_user.refresh_from_db()
        
        # Verificar que se actualizó
        self.assertEqual(self.rated_user.reputation_score, new_score)
        self.assertEqual(self.rated_user.reputation_count, count)
        self.assertEqual(count, 1)


class ReputationBreakdownTests(TestCase):
    """Tests para el desglose detallado de reputación."""
    
    def setUp(self):
        """Configuración inicial."""
        self.user1 = User.objects.create_user(
            username='evaluator1',
            email='eval1@test.com',
            password='testpass123'
        )
        self.rated_user = User.objects.create_user(
            username='rated_user',
            email='rated@test.com',
            password='testpass123'
        )

    def test_breakdown_structure(self):
        """Test estructura del desglose."""
        # Crear valoración
        UserRating.objects.create(
            rater=self.user1,
            rated_user=self.rated_user,
            rating=4,
            comment="Test breakdown"
        )
        
        breakdown = get_reputation_breakdown(self.rated_user)
        
        # Verificar estructura
        required_keys = [
            'final_score', 'total_ratings', 'ratings_data', 'algorithm_factors'
        ]
        for key in required_keys:
            self.assertIn(key, breakdown)
        
        # Verificar datos de valoraciones
        self.assertEqual(len(breakdown['ratings_data']), 1)
        rating_data = breakdown['ratings_data'][0]
        
        rating_keys = [
            'evaluator_username', 'rating_value', 'temporal_weight',
            'evaluator_credibility', 'weighted_contribution'
        ]
        for key in rating_keys:
            self.assertIn(key, rating_data)

    def test_algorithm_factors(self):
        """Test factores del algoritmo en el desglose."""
        UserRating.objects.create(
            rater=self.user1,
            rated_user=self.rated_user,
            rating=5,
            comment="Test factors"
        )
        
        breakdown = get_reputation_breakdown(self.rated_user)
        factors = breakdown['algorithm_factors']
        
        # Verificar que existen los factores principales
        expected_factors = [
            'base_score', 'confidence_factor', 'evaluator_avg_credibility'
        ]
        for factor in expected_factors:
            self.assertIn(factor, factors)
            self.assertIsInstance(factors[factor], (int, float, Decimal))


class ReputationConsistencyTests(TestCase):
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

    def test_consistency_validation_empty(self):
        """Test validación con usuarios sin valoraciones."""
        report = validate_reputation_consistency()
        
        self.assertTrue(report['is_consistent'])
        self.assertEqual(report['total_users_checked'], 0)
        self.assertEqual(report['inconsistencies_found'], 0)

    def test_consistency_validation_with_data(self):
        """Test validación con datos consistentes."""
        # Crear valoración y actualizar reputación
        UserRating.objects.create(
            rater=self.user1,
            rated_user=self.user2,
            rating=4,
            comment="Test consistency"
        )
        
        # Actualizar reputación manualmente
        update_user_reputation_sync(self.user2)
        
        # Validar consistencia
        report = validate_reputation_consistency()
        
        self.assertTrue(report['is_consistent'])
        self.assertEqual(report['total_users_checked'], 1)
        self.assertEqual(report['inconsistencies_found'], 0)


class ReputationAPITests(APITestCase):
    """Tests para los endpoints de la API de reputación."""
    
    def setUp(self):
        """Configuración inicial para tests de API."""
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
        self.rated_user = User.objects.create_user(
            username='rated_user',
            email='rated@test.com',
            password='testpass123'
        )
        
        # Crear valoraciones de prueba
        UserRating.objects.create(
            rater=self.user1,
            rated_user=self.rated_user,
            rating=5,
            comment="Excelente usuario"
        )
        UserRating.objects.create(
            rater=self.user2,
            rated_user=self.rated_user,
            rating=4,
            comment="Muy bueno"
        )
        
        # Actualizar reputación
        update_user_reputation_sync(self.rated_user)

    def test_reputation_stats_endpoint(self):
        """Test endpoint de estadísticas de reputación."""
        self.client.force_authenticate(user=self.user1)
        
        url = reverse('userreputation-reputation-stats')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        required_keys = [
            'total_users', 'users_with_reputation', 'users_with_ratings',
            'average_reputation', 'max_reputation', 'min_reputation'
        ]
        for key in required_keys:
            self.assertIn(key, data)

    def test_user_reputation_detail_endpoint(self):
        """Test endpoint de detalle de reputación de usuario."""
        self.client.force_authenticate(user=self.user1)
        
        url = reverse('userreputation-user-reputation', args=[self.rated_user.id])
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        required_keys = [
            'user_id', 'username', 'reputation_score', 'reputation_count'
        ]
        for key in required_keys:
            self.assertIn(key, data)
        
        self.assertEqual(data['user_id'], self.rated_user.id)
        self.assertEqual(data['username'], self.rated_user.username)

    def test_reputation_breakdown_endpoint(self):
        """Test endpoint de desglose de reputación."""
        self.client.force_authenticate(user=self.user1)
        
        url = reverse('userreputation-reputation-breakdown', args=[self.rated_user.id])
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        required_keys = [
            'final_score', 'total_ratings', 'ratings_data', 'algorithm_factors'
        ]
        for key in required_keys:
            self.assertIn(key, data)

    def test_reputation_endpoints_authentication_required(self):
        """Test que los endpoints requieren autenticación."""
        # Sin autenticación
        endpoints = [
            reverse('userreputation-reputation-stats'),
            reverse('userreputation-user-reputation', args=[self.rated_user.id]),
            reverse('userreputation-reputation-breakdown', args=[self.rated_user.id]),
        ]
        
        for url in endpoints:
            response = self.client.get(url)
            self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_user_reputation_not_found(self):
        """Test endpoint con usuario inexistente."""
        self.client.force_authenticate(user=self.user1)
        
        url = reverse('userreputation-user-reputation', args=[99999])
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)


class ReputationModelTests(TestCase):
    """Tests para los campos de reputación en el modelo User."""
    
    def setUp(self):
        """Configuración inicial."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@test.com',
            password='testpass123'
        )

    def test_reputation_fields_defaults(self):
        """Test valores por defecto de campos de reputación."""
        self.assertIsNone(self.user.reputation_score)
        self.assertIsNone(self.user.reputation_count)

    def test_reputation_fields_update(self):
        """Test actualización de campos de reputación."""
        self.user.reputation_score = Decimal('3.75')
        self.user.reputation_count = 5
        self.user.save()
        
        # Refrescar y verificar
        self.user.refresh_from_db()
        self.assertEqual(self.user.reputation_score, Decimal('3.75'))
        self.assertEqual(self.user.reputation_count, 5)
