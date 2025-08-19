"""
Tests completos para el sistema de reacciones (likes, emojis) en posts y comentarios.
"""
import json
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.contrib.contenttypes.models import ContentType
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken

from communities.models import (
    Community, CommunityMembership, Post, Comment, Reaction,
    GameType, CommunityCategory
)

User = get_user_model()


class ReactionModelTest(TestCase):
    """Tests para el modelo Reaction."""
    
    def setUp(self):
        # Crear usuarios
        self.user1 = User.objects.create_user(
            username='testuser1',
            email='test1@example.com',
            password='testpass123'
        )
        self.user2 = User.objects.create_user(
            username='testuser2',
            email='test2@example.com',
            password='testpass123'
        )
        
        # Crear datos básicos
        self.game_type = GameType.objects.create(
            name='Magic: The Gathering',
            description='Popular TCG'
        )
        self.category = CommunityCategory.objects.create(
            name='Competitive',
            description='Competitive communities'
        )
        self.community = Community.objects.create(
            name='Test Community',
            description='Community for testing',
            game_type=self.game_type,
            category=self.category,
            created_by=self.user1
        )
        
        # Crear membresías
        CommunityMembership.objects.create(
            user=self.user1,
            community=self.community,
            role='admin',
            status='active'
        )
        CommunityMembership.objects.create(
            user=self.user2,
            community=self.community,
            role='member',
            status='active'
        )
        
        # Crear post
        self.post = Post.objects.create(
            title='Test Post',
            content='Test content',
            author=self.user1,
            community=self.community
        )
        
        # Crear comentario
        self.comment = Comment.objects.create(
            content='Test comment',
            author=self.user2,
            post=self.post
        )
    
    def test_create_reaction(self):
        """Test de creación básica de reacción."""
        reaction = Reaction.objects.create(
            user=self.user1,
            content_object=self.post,
            reaction_type='like'
        )
        
        self.assertEqual(reaction.user, self.user1)
        self.assertEqual(reaction.content_object, self.post)
        self.assertEqual(reaction.reaction_type, 'like')
        self.assertIsNotNone(reaction.created_at)
    
    def test_emoji_mapping(self):
        """Test de mapeo correcto de emojis."""
        self.assertEqual(Reaction.EMOJI_MAP['like'], '👍')
        self.assertEqual(Reaction.EMOJI_MAP['love'], '❤️')
        self.assertEqual(Reaction.EMOJI_MAP['laugh'], '😂')
        self.assertEqual(Reaction.EMOJI_MAP['wow'], '😮')
        self.assertEqual(Reaction.EMOJI_MAP['sad'], '😢')
        self.assertEqual(Reaction.EMOJI_MAP['angry'], '😠')


class ReactionAPITest(APITestCase):
    """Tests básicos para las APIs de reacciones."""
    
    def setUp(self):
        # Crear usuarios
        self.user1 = User.objects.create_user(
            username='testuser1',
            email='test1@example.com',
            password='testpass123'
        )
        
        # Crear datos básicos
        self.game_type = GameType.objects.create(
            name='Magic: The Gathering',
            description='Popular TCG'
        )
        self.category = CommunityCategory.objects.create(
            name='Competitive',
            description='Competitive communities'
        )
        self.community = Community.objects.create(
            name='Test Community',
            description='Community for testing',
            game_type=self.game_type,
            category=self.category,
            created_by=self.user1
        )
        
        # Crear membresías
        CommunityMembership.objects.create(
            user=self.user1,
            community=self.community,
            role='admin',
            status='active'
        )
        
        # Crear post
        self.post = Post.objects.create(
            title='Test Post',
            content='Test content',
            author=self.user1,
            community=self.community
        )
        
        # Crear comentario
        self.comment = Comment.objects.create(
            content='Test comment',
            author=self.user1,
            post=self.post
        )
        
        # Token JWT
        self.user1_token = str(RefreshToken.for_user(self.user1).access_token)
    
    def test_react_to_post(self):
        """Test de reaccionar a un post."""
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.user1_token}')
        
        url = f'/api/reactions/posts/{self.post.id}/react/'
        data = {'reaction_type': 'like'}
        
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['action'], 'added')
        self.assertEqual(response.data['user_reaction']['reaction_type'], 'like')
    
    def test_invalid_reaction_type(self):
        """Test de tipo de reacción inválido."""
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.user1_token}')
        
        url = f'/api/reactions/posts/{self.post.id}/react/'
        data = {'reaction_type': 'invalid_type'}
        
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_unauthenticated_user(self):
        """Test de usuario no autenticado."""
        url = f'/api/reactions/posts/{self.post.id}/react/'
        data = {'reaction_type': 'like'}
        
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
