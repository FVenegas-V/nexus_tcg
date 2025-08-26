"""
Tests para perfiles públicos de usuarios - Fase 4
Prueba funcionalidad de visualización de perfiles con biografía y privacidad
"""
import pytest
from django.test import TestCase
from django.urls import reverse
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status

from ..models import UserProfile
from communities.models import Community, CommunityMembership

User = get_user_model()


class UserProfileViewSetTestCase(TestCase):
    """Tests para UserProfileViewSet - perfiles públicos"""
    
    def setUp(self):
        """Configuración inicial para tests"""
        self.client = APIClient()
        
        # Crear usuarios de prueba
        self.public_user = User.objects.create_user(
            username='publico_usuario',
            email='publico@test.com',
            password='testpass123',
            first_name='Juan',
            last_name='Pérez'
        )
        
        self.private_user = User.objects.create_user(
            username='privado_usuario',
            email='privado@test.com',
            password='testpass123',
            first_name='María',
            last_name='García'
        )
        
        self.viewer_user = User.objects.create_user(
            username='observador',
            email='observador@test.com',
            password='testpass123'
        )
        
        # Configurar perfil público
        self.public_profile = UserProfile.objects.get(user=self.public_user)
        self.public_profile.bio = "Esta es una biografía de prueba que es lo suficientemente larga para ser considerada como larga y necesitar un preview. Esta biografía contiene más de 200 caracteres para poder probar la funcionalidad de preview de biografías largas en el sistema."
        self.public_profile.show_profile_publicly = True
        self.public_profile.show_email = True
        self.public_profile.show_location = True
        self.public_profile.show_birth_date = True
        self.public_profile.show_activity_stats = True
        self.public_profile.show_communities = True
        self.public_profile.location = "Ciudad de México"
        self.public_profile.favorite_games = "Magic: The Gathering, Pokémon"
        self.public_profile.play_style = "Competitivo"
        self.public_profile.experience_level = "Avanzado"
        self.public_profile.posts_count = 15
        self.public_profile.communities_count = 3
        self.public_profile.likes_received = 45
        self.public_profile.reputation_score = 250
        self.public_profile.save()
        
        # Configurar perfil privado
        self.private_profile = UserProfile.objects.get(user=self.private_user)
        self.private_profile.bio = "Biografía privada"
        self.private_profile.show_profile_publicly = False  # Perfil NO público
        self.private_profile.save()
        
        # Crear comunidad y membresía para pruebas
        self.community = Community.objects.create(
            name="Comunidad Test",
            description="Comunidad para pruebas",
            creator=self.public_user
        )
        
        CommunityMembership.objects.create(
            user=self.public_user,
            community=self.community,
            role='admin',
            is_active=True
        )
    
    def test_get_public_profile_success(self):
        """Test obtener perfil público exitosamente"""
        url = reverse('user-profiles-detail', kwargs={'pk': self.public_user.id})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        
        # Verificar datos básicos
        self.assertEqual(data['user_id'], self.public_user.id)
        self.assertEqual(data['username'], 'publico_usuario')
        self.assertEqual(data['first_name'], 'Juan')
        self.assertEqual(data['last_name'], 'Pérez')
        self.assertEqual(data['email'], 'publico@test.com')  # Debe mostrarse
        self.assertEqual(data['location'], 'Ciudad de México')  # Debe mostrarse
        
        # Verificar manejo de biografía
        self.assertIsNotNone(data['bio'])
        self.assertIsNotNone(data['bio_preview'])
        self.assertTrue(data['bio_is_long'])
        self.assertEqual(len(data['bio_preview']), 203)  # 200 chars + "..."
        self.assertTrue(data['bio_preview'].endswith('...'))
        
        # Verificar estadísticas
        self.assertIsNotNone(data['stats'])
        self.assertEqual(data['stats']['posts_count'], 15)
        self.assertEqual(data['stats']['communities_count'], 3)
        self.assertEqual(data['stats']['likes_received'], 45)
        self.assertEqual(data['stats']['reputation_score'], 250)
        
        # Verificar actividad reciente
        self.assertIn('recent_posts', data)
        self.assertIn('recent_communities', data)
    
    def test_get_private_profile_forbidden(self):
        """Test acceso denegado a perfil privado"""
        url = reverse('user-profiles-detail', kwargs={'pk': self.private_user.id})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_biography_preview_short_bio(self):
        """Test que biografía corta no genere preview"""
        # Actualizar con biografía corta
        self.public_profile.bio = "Biografía corta"
        self.public_profile.save()
        
        url = reverse('user-profiles-detail', kwargs={'pk': self.public_user.id})
        response = self.client.get(url)
        
        data = response.json()
        self.assertEqual(data['bio'], data['bio_preview'])  # Deben ser iguales
        self.assertFalse(data['bio_is_long'])
    
    def test_biography_empty(self):
        """Test manejo de biografía vacía"""
        # Biografía vacía
        self.public_profile.bio = ""
        self.public_profile.save()
        
        url = reverse('user-profiles-detail', kwargs={'pk': self.public_user.id})
        response = self.client.get(url)
        
        data = response.json()
        self.assertEqual(data['bio'], "")
        self.assertIsNone(data['bio_preview'])
        self.assertFalse(data['bio_is_long'])
    
    def test_privacy_settings_respected(self):
        """Test que se respeten las configuraciones de privacidad"""
        # Configurar perfil con privacidad selectiva
        self.public_profile.show_email = False
        self.public_profile.show_location = False
        self.public_profile.show_birth_date = False
        self.public_profile.show_activity_stats = False
        self.public_profile.show_communities = False
        self.public_profile.save()
        
        url = reverse('user-profiles-detail', kwargs={'pk': self.public_user.id})
        response = self.client.get(url)
        
        data = response.json()
        
        # Verificar que campos privados son None o listas vacías
        self.assertIsNone(data['email'])
        self.assertIsNone(data['location'])
        self.assertIsNone(data['birth_date'])
        self.assertIsNone(data['age'])
        self.assertIsNone(data['stats'])
        self.assertEqual(data['recent_posts'], [])
        self.assertEqual(data['recent_communities'], [])
    
    def test_profile_activity_endpoint(self):
        """Test endpoint de actividad específico"""
        url = reverse('user-profiles-activity', kwargs={'pk': self.public_user.id})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        
        self.assertIn('stats', data)
        self.assertIn('recent_posts', data)
        self.assertEqual(data['stats']['posts_count'], 15)
    
    def test_profile_activity_private_stats(self):
        """Test endpoint de actividad con estadísticas privadas"""
        self.public_profile.show_activity_stats = False
        self.public_profile.save()
        
        url = reverse('user-profiles-activity', kwargs={'pk': self.public_user.id})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_profile_communities_endpoint(self):
        """Test endpoint de comunidades específico"""
        url = reverse('user-profiles-communities', kwargs={'pk': self.public_user.id})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        
        self.assertIn('communities', data)
        self.assertIn('total_count', data)
        self.assertEqual(len(data['communities']), 1)
        self.assertEqual(data['communities'][0]['name'], 'Comunidad Test')
        self.assertEqual(data['communities'][0]['role'], 'admin')
    
    def test_profile_communities_private(self):
        """Test endpoint de comunidades con privacidad activada"""
        self.public_profile.show_communities = False
        self.public_profile.save()
        
        url = reverse('user-profiles-communities', kwargs={'pk': self.public_user.id})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_profile_posts_endpoint(self):
        """Test endpoint de posts específico"""
        url = reverse('user-profiles-posts', kwargs={'pk': self.public_user.id})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        
        self.assertIn('posts', data)
        self.assertIn('pagination', data)
        
        # Verificar estructura de paginación
        pagination = data['pagination']
        self.assertEqual(pagination['current_page'], 1)
        self.assertEqual(pagination['page_size'], 10)
    
    def test_profile_posts_pagination(self):
        """Test paginación en endpoint de posts"""
        # Test con parámetros de paginación
        url = reverse('user-profiles-posts', kwargs={'pk': self.public_user.id})
        response = self.client.get(url, {'page': 2, 'page_size': 5})
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        
        pagination = data['pagination']
        self.assertEqual(pagination['current_page'], 2)
        self.assertEqual(pagination['page_size'], 5)
    
    def test_nonexistent_user_profile(self):
        """Test acceso a perfil de usuario inexistente"""
        url = reverse('user-profiles-detail', kwargs={'pk': 99999})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
    
    def test_user_profile_detail_serializer_fields(self):
        """Test que el serializer incluya todos los campos esperados"""
        url = reverse('user-profiles-detail', kwargs={'pk': self.public_user.id})
        response = self.client.get(url)
        
        data = response.json()
        
        # Verificar campos obligatorios
        required_fields = [
            'user_id', 'username', 'first_name', 'last_name', 'email',
            'bio', 'bio_preview', 'bio_is_long', 'location', 'birth_date',
            'age', 'joined_at', 'favorite_games', 'play_style',
            'experience_level', 'avatar_url', 'banner_url', 'stats',
            'recent_posts', 'recent_communities'
        ]
        
        for field in required_fields:
            self.assertIn(field, data, f"Campo '{field}' faltante en respuesta")


class UserProfileSerializerTestCase(TestCase):
    """Tests específicos para UserPublicProfileDetailSerializer"""
    
    def setUp(self):
        """Configuración para tests de serializer"""
        self.user = User.objects.create_user(
            username='test_user',
            email='test@example.com',
            password='testpass123',
            first_name='Test',
            last_name='User'
        )
        
        self.profile = UserProfile.objects.get(user=self.user)
    
    def test_bio_preview_generation(self):
        """Test generación de preview de biografía"""
        from ..serializers import UserPublicProfileDetailSerializer
        
        # Biografía larga
        long_bio = "A" * 250  # 250 caracteres
        self.profile.bio = long_bio
        
        serializer = UserPublicProfileDetailSerializer(instance=self.profile)
        data = serializer.data
        
        self.assertEqual(data['bio_preview'], "A" * 200 + "...")
        self.assertTrue(data['bio_is_long'])
    
    def test_bio_preview_short_bio(self):
        """Test biografía corta sin preview"""
        from ..serializers import UserPublicProfileDetailSerializer
        
        short_bio = "Biografía corta"
        self.profile.bio = short_bio
        
        serializer = UserPublicProfileDetailSerializer(instance=self.profile)
        data = serializer.data
        
        self.assertEqual(data['bio_preview'], short_bio)
        self.assertFalse(data['bio_is_long'])
    
    def test_privacy_fields_null_when_private(self):
        """Test que campos privados retornen None"""
        from ..serializers import UserPublicProfileDetailSerializer
        
        # Configurar todo como privado
        self.profile.show_email = False
        self.profile.show_location = False
        self.profile.show_birth_date = False
        self.profile.show_activity_stats = False
        self.profile.show_communities = False
        
        serializer = UserPublicProfileDetailSerializer(instance=self.profile)
        data = serializer.data
        
        self.assertIsNone(data['email'])
        self.assertIsNone(data['location'])
        self.assertIsNone(data['birth_date'])
        self.assertIsNone(data['age'])
        self.assertIsNone(data['stats'])
        self.assertEqual(data['recent_posts'], [])
        self.assertEqual(data['recent_communities'], [])


@pytest.mark.django_db
class TestUserProfileIntegration:
    """Tests de integración para perfiles públicos"""
    
    def test_complete_user_profile_flow(self):
        """Test flujo completo de visualización de perfil"""
        # Crear usuario y configurar perfil
        user = User.objects.create_user(
            username='integration_user',
            email='integration@test.com',
            password='testpass123'
        )
        
        profile = UserProfile.objects.get(user=user)
        profile.bio = "Biografía de integración para pruebas completas del sistema"
        profile.show_profile_publicly = True
        profile.show_activity_stats = True
        profile.save()
        
        # Crear cliente y realizar solicitud
        client = APIClient()
        url = reverse('user-profiles-detail', kwargs={'pk': user.id})
        response = client.get(url)
        
        # Verificar respuesta exitosa
        assert response.status_code == 200
        data = response.json()
        
        # Verificar datos del usuario
        assert data['username'] == 'integration_user'
        assert data['bio'] == profile.bio
        assert data['bio_preview'] == profile.bio  # Bio corta, sin preview
        assert not data['bio_is_long']
