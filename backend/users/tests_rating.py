from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APITestCase, APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from users.models import UserProfile, UserRating
import json

User = get_user_model()


class UserRatingModelTest(TestCase):
    """
    Pruebas unitarias para el modelo UserRating
    """
    
    def setUp(self):
        """Configuración inicial para las pruebas"""
        # Crear usuarios de prueba
        self.alice = User.objects.create_user(
            username='alice',
            email='alice@test.com',
            password='testpass123'
        )
        
        self.bob = User.objects.create_user(
            username='bob', 
            email='bob@test.com',
            password='testpass123'
        )
        
        self.charlie = User.objects.create_user(
            username='charlie',
            email='charlie@test.com', 
            password='testpass123'
        )
        
        # Crear perfiles
        UserProfile.objects.create(
            user=self.alice,
            bio='Alice bio',
            play_style='competitive'
        )
        
        UserProfile.objects.create(
            user=self.bob,
            bio='Bob bio',
            play_style='casual'
        )
        
        UserProfile.objects.create(
            user=self.charlie,
            bio='Charlie bio',
            play_style='collector'
        )
    
    def test_create_rating(self):
        """Prueba creación básica de valoración"""
        rating = UserRating.objects.create(
            rater=self.alice,
            rated_user=self.bob,
            rating=5,
            comment="Excelente usuario",
            interaction_type='trade'
        )
        
        self.assertEqual(rating.rater, self.alice)
        self.assertEqual(rating.rated_user, self.bob)
        self.assertEqual(rating.rating, 5)
        self.assertEqual(rating.interaction_type, 'trade')
        self.assertTrue(rating.is_active)
    
    def test_rating_string_representation(self):
        """Prueba la representación string del rating"""
        rating = UserRating.objects.create(
            rater=self.alice,
            rated_user=self.bob,
            rating=4,
            comment="Buen usuario"
        )
        
        expected_str = f"{self.alice.username} → {self.bob.username}: 4⭐"
        self.assertEqual(str(rating), expected_str)
    
    def test_self_rating_validation(self):
        """Prueba que un usuario no puede valorarse a sí mismo"""
        from django.core.exceptions import ValidationError
        
        with self.assertRaises(ValidationError):
            rating = UserRating(
                rater=self.alice,
                rated_user=self.alice,
                rating=5,
                comment="Auto-valoración"
            )
            rating.clean()
    
    def test_rating_range_validation(self):
        """Prueba validación del rango de valoración (1-5)"""
        from django.core.exceptions import ValidationError
        
        # Rating muy bajo
        with self.assertRaises(ValidationError):
            rating = UserRating(
                rater=self.alice,
                rated_user=self.bob,
                rating=0,
                comment="Rating inválido"
            )
            rating.clean()
        
        # Rating muy alto
        with self.assertRaises(ValidationError):
            rating = UserRating(
                rater=self.alice,
                rated_user=self.bob,
                rating=6,
                comment="Rating inválido"
            )
            rating.clean()
    
    def test_unique_rating_constraint(self):
        """Prueba que un usuario solo puede valorar a otro una vez"""
        from django.db import IntegrityError
        
        # Crear primera valoración
        UserRating.objects.create(
            rater=self.alice,
            rated_user=self.bob,
            rating=5,
            comment="Primera valoración"
        )
        
        # Intentar crear segunda valoración (debe fallar)
        with self.assertRaises(IntegrityError):
            UserRating.objects.create(
                rater=self.alice,
                rated_user=self.bob,
                rating=3,
                comment="Segunda valoración"
            )
    
    def test_soft_delete(self):
        """Prueba la funcionalidad de soft delete"""
        rating = UserRating.objects.create(
            rater=self.alice,
            rated_user=self.bob,
            rating=5,
            comment="Para eliminar"
        )
        
        # Verificar que está activa
        self.assertTrue(rating.is_active)
        
        # Soft delete
        rating.soft_delete()
        
        # Verificar que está inactiva
        self.assertFalse(rating.is_active)
        
        # Verificar que sigue en la base de datos
        self.assertTrue(UserRating.objects.filter(id=rating.id).exists())
    
    def test_rating_summary(self):
        """Prueba el método get_user_rating_summary"""
        # Crear varias valoraciones para Bob
        UserRating.objects.create(
            rater=self.alice,
            rated_user=self.bob,
            rating=5,
            comment="Excelente"
        )
        
        UserRating.objects.create(
            rater=self.charlie,
            rated_user=self.bob,
            rating=4,
            comment="Muy bueno"
        )
        
        # Obtener resumen
        summary = UserRating.get_user_rating_summary(self.bob)
        
        self.assertEqual(summary['total_ratings'], 2)
        self.assertEqual(summary['average_rating'], 4.5)
        self.assertEqual(summary['rating_distribution'][4], 1)
        self.assertEqual(summary['rating_distribution'][5], 1)
    
    def test_reputation_score_update(self):
        """Prueba que el reputation_score se actualiza correctamente"""
        # Crear valoración
        rating = UserRating.objects.create(
            rater=self.alice,
            rated_user=self.bob,
            rating=4,
            comment="Buen usuario"
        )
        
        # Refrescar perfil de Bob desde la base de datos
        bob_profile = UserProfile.objects.get(user=self.bob)
        
        # Verificar que el reputation_score se actualizo (4 * 20 = 80)
        self.assertEqual(bob_profile.reputation_score, 80)


class UserRatingAPITest(APITestCase):
    """
    Pruebas de la API de valoraciones
    """
    
    def setUp(self):
        """Configuración inicial para las pruebas de API"""
        # Crear usuarios
        self.alice = User.objects.create_user(
            username='alice_api',
            email='alice_api@test.com',
            password='testpass123'
        )
        
        self.bob = User.objects.create_user(
            username='bob_api',
            email='bob_api@test.com', 
            password='testpass123'
        )
        
        # Crear perfiles
        UserProfile.objects.create(user=self.alice, bio='Alice bio')
        UserProfile.objects.create(user=self.bob, bio='Bob bio')
        
        # Configurar cliente API
        self.client = APIClient()
        
        # Obtener tokens
        self.alice_token = RefreshToken.for_user(self.alice)
        self.bob_token = RefreshToken.for_user(self.bob)
    
    def authenticate_as_alice(self):
        """Autenticar como Alice"""
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.alice_token.access_token}')
    
    def authenticate_as_bob(self):
        """Autenticar como Bob"""
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.bob_token.access_token}')
    
    def test_rate_user_endpoint(self):
        """Prueba el endpoint para valorar usuario"""
        self.authenticate_as_alice()
        
        url = reverse('user-ratings-rate-user')
        data = {
            'rated_user': self.bob.id,
            'rating': 5,
            'comment': 'Excelente usuario via API',
            'interaction_type': 'trade'
        }
        
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('rating', response.data)
        self.assertEqual(response.data['rating']['rating'], 5)
    
    def test_rate_user_self_rating_rejected(self):
        """Prueba que la auto-valoración es rechazada"""
        self.authenticate_as_alice()
        
        url = reverse('user-ratings-rate-user')
        data = {
            'rated_user': self.alice.id,  # Auto-valoración
            'rating': 5,
            'comment': 'Me valoro a mi misma'
        }
        
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_received_ratings_endpoint(self):
        """Prueba el endpoint de valoraciones recibidas"""
        # Crear valoración
        UserRating.objects.create(
            rater=self.alice,
            rated_user=self.bob,
            rating=5,
            comment="Para prueba API"
        )
        
        self.authenticate_as_alice()
        
        url = reverse('user-ratings-received-ratings', kwargs={'pk': self.bob.id})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('ratings', response.data)
        self.assertEqual(len(response.data['ratings']), 1)
    
    def test_my_ratings_endpoint(self):
        """Prueba el endpoint de mis valoraciones"""
        # Crear valoración
        UserRating.objects.create(
            rater=self.alice,
            rated_user=self.bob,
            rating=4,
            comment="Mi valoración"
        )
        
        self.authenticate_as_alice()
        
        url = reverse('user-ratings-my-ratings')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('ratings', response.data)
        self.assertEqual(len(response.data['ratings']), 1)
    
    def test_stats_endpoint(self):
        """Prueba el endpoint de estadísticas"""
        # Crear valoraciones
        UserRating.objects.create(
            rater=self.alice,
            rated_user=self.bob,
            rating=5,
            comment="Excelente"
        )
        
        self.authenticate_as_alice()
        
        url = reverse('user-ratings-stats', kwargs={'pk': self.bob.id})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('stats', response.data)
        self.assertEqual(response.data['stats']['total_ratings'], 1)
        self.assertEqual(response.data['stats']['average_rating'], 5.0)
    
    def test_unauthenticated_access_denied(self):
        """Prueba que el acceso sin autenticación es denegado"""
        url = reverse('user-ratings-rate-user')
        data = {
            'rated_user': self.bob.id,
            'rating': 5,
            'comment': 'Sin autenticación'
        }
        
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
