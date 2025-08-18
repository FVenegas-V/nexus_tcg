"""
Tests para el sistema de Posts de comunidades TCG.
"""
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.contrib.contenttypes.models import ContentType
from rest_framework.test import APITestCase, APIClient
from rest_framework import status
from .models import (
    Community, CommunityCategory, CommunityMembership, 
    Post, Reaction, GameType
)
from .serializers import (
    PostListSerializer, PostDetailSerializer, PostCreateUpdateSerializer
)

User = get_user_model()


class PostModelTest(TestCase):
    """Tests para el modelo Post."""
    
    def setUp(self):
        """Configuración inicial para los tests."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.category = CommunityCategory.objects.create(
            name='Test Category'
        )
        
        self.game_type = GameType.objects.create(
            name='Magic: The Gathering',
            slug='magic'
        )
        
        self.community = Community.objects.create(
            name='Test Community',
            description='Una comunidad de prueba',
            category=self.category,
            created_by=self.user,
            game_type=self.game_type,
            difficulty_level='beginner'
        )
        
        # Crear membresía
        CommunityMembership.objects.create(
            user=self.user,
            community=self.community,
            role='admin'
        )
    
    def test_post_creation(self):
        """Test básico de creación de post."""
        post = Post.objects.create(
            title='Test Post',
            content='Contenido del post de prueba',
            author=self.user,
            community=self.community
        )
        
        self.assertEqual(post.title, 'Test Post')
        self.assertEqual(post.author, self.user)
        self.assertEqual(post.community, self.community)
        self.assertTrue(post.is_active)
        
        # Verificar que no hay reacciones inicialmente usando GenericForeignKey
        post_content_type = ContentType.objects.get_for_model(Post)
        reaction_count = Reaction.objects.filter(
            content_type=post_content_type,
            object_id=post.id
        ).count()
        self.assertEqual(reaction_count, 0)
    
    def test_post_str_representation(self):
        """Test de representación string."""
        post = Post.objects.create(
            title='Mi Post Genial',
            content='Contenido',
            author=self.user,
            community=self.community
        )
        
        self.assertEqual(str(post), 'Mi Post Genial - testuser')
    
    def test_post_reactions_count(self):
        """Test del conteo de reacciones."""
        post = Post.objects.create(
            title='Post con Reacciones',
            content='Contenido',
            author=self.user,
            community=self.community
        )
        
        # Crear usuarios adicionales
        user2 = User.objects.create_user(
            username='user2',
            email='user2@example.com',
            password='pass123'
        )
        
        user3 = User.objects.create_user(
            username='user3',
            email='user3@example.com',
            password='pass123'
        )
        
        # Obtener ContentType para Post
        post_content_type = ContentType.objects.get_for_model(Post)
        
        # Crear reacciones usando GenericForeignKey
        Reaction.objects.create(
            user=self.user, 
            content_type=post_content_type,
            object_id=post.id,
            reaction_type='like'
        )
        Reaction.objects.create(
            user=user2, 
            content_type=post_content_type,
            object_id=post.id,
            reaction_type='love'
        )
        Reaction.objects.create(
            user=user3, 
            content_type=post_content_type,
            object_id=post.id,
            reaction_type='like'
        )
        
        # Verificar conteo de reacciones
        reaction_count = Reaction.objects.filter(
            content_type=post_content_type,
            object_id=post.id
        ).count()
        self.assertEqual(reaction_count, 3)
    
    def test_post_user_reaction(self):
        """Test de verificar reacciones de usuario."""
        post = Post.objects.create(
            title='Post Test',
            content='Contenido',
            author=self.user,
            community=self.community
        )
        
        # Obtener ContentType para Post
        post_content_type = ContentType.objects.get_for_model(Post)
        
        # Sin reacción
        user_reaction = Reaction.objects.filter(
            content_type=post_content_type,
            object_id=post.id,
            user=self.user
        ).first()
        self.assertIsNone(user_reaction)
        
        # Con reacción
        Reaction.objects.create(
            user=self.user,
            content_type=post_content_type,
            object_id=post.id,
            reaction_type='love'
        )
        user_reaction = Reaction.objects.filter(
            content_type=post_content_type,
            object_id=post.id,
            user=self.user
        ).first()
        self.assertIsNotNone(user_reaction)
        self.assertEqual(user_reaction.reaction_type, 'love')


class ReactionModelTest(TestCase):
    """Tests para el modelo Reaction."""
    
    def setUp(self):
        """Configuración inicial."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.category = CommunityCategory.objects.create(name='Test Category')
        
        self.game_type = GameType.objects.create(
            name='Magic: The Gathering',
            slug='magic'
        )
        
        self.community = Community.objects.create(
            name='Test Community',
            description='Test',
            category=self.category,
            created_by=self.user,
            game_type=self.game_type,
            difficulty_level='beginner'
        )
        
        # Crear membresía para que el usuario pueda crear posts
        CommunityMembership.objects.create(
            user=self.user,
            community=self.community,
            role='member'
        )
        
        self.post = Post.objects.create(
            title='Test Post',
            content='Content',
            author=self.user,
            community=self.community
        )
    
    def test_reaction_creation(self):
        """Test de creación de reacción."""
        post_content_type = ContentType.objects.get_for_model(Post)
        
        reaction = Reaction.objects.create(
            content_type=post_content_type,
            object_id=self.post.id,
            user=self.user,
            reaction_type='like'
        )
        
        self.assertEqual(reaction.content_object, self.post)
        self.assertEqual(reaction.user, self.user)
        self.assertEqual(reaction.reaction_type, 'like')
    
    def test_unique_constraint(self):
        """Test de constraint único por usuario y contenido."""
        post_content_type = ContentType.objects.get_for_model(Post)
        
        # Primera reacción
        Reaction.objects.create(
            content_type=post_content_type,
            object_id=self.post.id,
            user=self.user,
            reaction_type='like'
        )
        
        # Segunda reacción del mismo usuario al mismo post debe fallar
        with self.assertRaises(Exception):  # IntegrityError
            Reaction.objects.create(
                content_type=post_content_type,
                object_id=self.post.id,
                user=self.user,
                reaction_type='love'
            )


class PostSerializerTest(TestCase):
    """Tests para los serializers de Post."""
    
    def setUp(self):
        """Configuración inicial."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.category = CommunityCategory.objects.create(name='Test Category')
        
        self.game_type = GameType.objects.create(
            name='Magic: The Gathering',
            slug='magic'
        )
        
        self.community = Community.objects.create(
            name='Test Community',
            description='Test',
            category=self.category,
            created_by=self.user,
            game_type=self.game_type,
            difficulty_level='beginner'
        )
        
        CommunityMembership.objects.create(
            user=self.user,
            community=self.community,
            role='member'
        )
        
        self.post = Post.objects.create(
            title='Test Post',
            content='Content',
            author=self.user,
            community=self.community
        )
    
    def test_post_list_serializer(self):
        """Test del PostListSerializer."""
        serializer = PostListSerializer(self.post)
        data = serializer.data
        
        self.assertEqual(data['title'], 'Test Post')
        self.assertEqual(data['author']['username'], 'testuser')
        self.assertEqual(data['community']['name'], 'Test Community')
    
    def test_post_detail_serializer(self):
        """Test del PostDetailSerializer."""
        serializer = PostDetailSerializer(self.post)
        data = serializer.data
        
        self.assertEqual(data['title'], 'Test Post')
        self.assertEqual(data['content'], 'Content')
        self.assertIn('image_urls', data)
    
    def test_post_create_serializer_validation(self):
        """Test de validación del PostCreateUpdateSerializer."""
        from django.test import RequestFactory
        
        # Crear un request mock con usuario autenticado
        factory = RequestFactory()
        request = factory.post('/api/posts/')
        request.user = self.user
        
        data = {
            'title': 'Nuevo Post',
            'content': 'Contenido del nuevo post',
            'community': self.community.id
        }
        
        serializer = PostCreateUpdateSerializer(data=data, context={'request': request})
        if not serializer.is_valid():
            print("Errores del serializer:", serializer.errors)
        self.assertTrue(serializer.is_valid())
        
        # Test con datos inválidos - content vacío (que sí es requerido)
        invalid_data = {
            'title': 'Título válido',
            'content': '',  # Contenido vacío (requerido)
            'community': self.community.id
        }
        
        serializer = PostCreateUpdateSerializer(data=invalid_data, context={'request': request})
        self.assertFalse(serializer.is_valid())
        self.assertIn('content', serializer.errors)


class PostAPITest(APITestCase):
    """Tests para las APIs de Posts."""
    
    def setUp(self):
        """Configuración inicial para tests de API."""
        self.client = APIClient()
        
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.other_user = User.objects.create_user(
            username='otheruser',
            email='other@example.com',
            password='testpass123'
        )
        
        self.category = CommunityCategory.objects.create(name='Test Category')
        
        self.game_type = GameType.objects.create(
            name='Magic: The Gathering',
            slug='magic'
        )
        
        self.community = Community.objects.create(
            name='Test Community',
            description='Test',
            category=self.category,
            created_by=self.user,
            game_type=self.game_type,
            difficulty_level='beginner'
        )
        
        # Crear membresías
        CommunityMembership.objects.create(
            user=self.user,
            community=self.community,
            role='admin'
        )
        
        CommunityMembership.objects.create(
            user=self.other_user,
            community=self.community,
            role='member'
        )
        
        self.post = Post.objects.create(
            title='Test Post',
            content='Content',
            author=self.user,
            community=self.community
        )
    
    def test_post_list_requires_authentication(self):
        """Test que listar posts requiere autenticación."""
        response = self.client.get('/api/posts/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_post_list_authenticated(self):
        """Test de listado de posts autenticado."""
        self.client.force_authenticate(user=self.user)
        response = self.client.get('/api/posts/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
    
    def test_post_create_by_member(self):
        """Test de creación de post por miembro."""
        self.client.force_authenticate(user=self.other_user)
        
        data = {
            'title': 'Nuevo Post',
            'content': 'Contenido del nuevo post',
            'community': self.community.id
        }
        
        response = self.client.post('/api/posts/', data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['author']['username'], 'otheruser')
    
    def test_post_create_by_non_member(self):
        """Test de creación de post por no-miembro."""
        non_member = User.objects.create_user(
            username='nonmember',
            email='nonmember@example.com',
            password='testpass123'
        )
        
        self.client.force_authenticate(user=non_member)
        
        data = {
            'title': 'Post No Permitido',
            'content': 'Este post no debería crearse',
            'community': self.community.id
        }
        
        response = self.client.post('/api/posts/', data)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_post_update_by_author(self):
        """Test de actualización de post por el autor."""
        self.client.force_authenticate(user=self.user)
        
        data = {
            'title': 'Post Actualizado',
            'content': 'Contenido actualizado'
        }
        
        response = self.client.patch(f'/api/posts/{self.post.id}/', data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['title'], 'Post Actualizado')
    
    def test_post_update_by_non_author(self):
        """Test de actualización de post por otro usuario."""
        self.client.force_authenticate(user=self.other_user)
        
        data = {
            'title': 'Intento de Actualización',
            'content': 'Este cambio no debería permitirse'
        }
        
        response = self.client.patch(f'/api/posts/{self.post.id}/', data)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_post_toggle_reaction(self):
        """Test de alternar reacción en post."""
        self.client.force_authenticate(user=self.other_user)
        
        # Agregar reacción
        data = {'reaction_type': 'like'}
        response = self.client.post(f'/api/posts/{self.post.id}/toggle_reaction/', data)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['action'], 'created')
        self.assertEqual(response.data['reaction_type'], 'like')
        
        # Quitar reacción (mismo tipo)
        response = self.client.post(f'/api/posts/{self.post.id}/toggle_reaction/', data)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['action'], 'removed')
    
    def test_post_feed(self):
        """Test del feed personalizado."""
        self.client.force_authenticate(user=self.other_user)
        
        response = self.client.get('/api/posts/feed/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Debería incluir posts de comunidades donde es miembro
        self.assertEqual(len(response.data), 1)
    
    def test_post_by_community(self):
        """Test de posts por comunidad."""
        self.client.force_authenticate(user=self.user)
        
        response = self.client.get(f'/api/posts/by_community/?community_id={self.community.id}')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        
        # Test sin community_id
        response = self.client.get('/api/posts/by_community/')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_my_posts(self):
        """Test de posts del usuario autenticado."""
        self.client.force_authenticate(user=self.user)
        
        response = self.client.get('/api/posts/my_posts/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['author']['username'], 'testuser')
